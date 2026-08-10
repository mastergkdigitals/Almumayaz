import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/app_state/app_store.dart';
import '../../../core/design/app_design_system.dart';
import '../../../core/services/service_failure.dart';
import '../domain/session_models.dart';

/// Keeps the Flutter demo session coherent with user activity and blocks the
/// application while the shared session is locked.
///
/// A backend will remain responsible for authoritative session expiry. This
/// guard provides the complete desktop interaction and an interchangeable
/// client-side policy boundary in the meantime.
class SessionActivityGuard extends StatefulWidget {
  const SessionActivityGuard({
    required this.child,
    required this.onRequireSignIn,
    super.key,
  });

  final Widget child;
  final Future<void> Function() onRequireSignIn;

  @override
  State<SessionActivityGuard> createState() =>
      _SessionActivityGuardState();
}

class _SessionActivityGuardState extends State<SessionActivityGuard> {
  AppStore? _store;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final store = AppStoreScope.of(context, listen: false);
    if (identical(store, _store)) return;
    _store?.suspendIdleMonitoring();
    _store = store;
    store.resumeIdleMonitoring();
  }

  @override
  void dispose() {
    _store?.suspendIdleMonitoring();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = AppStoreScope.of(context);
    final requiresAuthentication = store.requiresAuthentication;

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: requiresAuthentication
          ? null
          : (_) => unawaited(store.recordActivity()),
      onPointerSignal: requiresAuthentication
          ? null
          : (_) => unawaited(store.recordActivity()),
      onPointerHover: requiresAuthentication
          ? null
          : (_) => unawaited(store.recordActivity()),
      child: Focus(
        canRequestFocus: false,
        onKeyEvent: (_, event) {
          if (!requiresAuthentication && event is KeyDownEvent) {
            unawaited(store.recordActivity());
          }
          return KeyEventResult.ignored;
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            ExcludeSemantics(
              excluding: requiresAuthentication,
              child: ExcludeFocus(
                excluding: requiresAuthentication,
                child: AbsorbPointer(
                  absorbing: requiresAuthentication,
                  child: widget.child,
                ),
              ),
            ),
            if (requiresAuthentication)
              _SessionUnlockView(
                sessionState: store.session?.state,
                onRequireSignIn: widget.onRequireSignIn,
              ),
          ],
        ),
      ),
    );
  }
}

class _SessionUnlockView extends StatefulWidget {
  const _SessionUnlockView({
    required this.sessionState,
    required this.onRequireSignIn,
  });

  final SessionState? sessionState;
  final Future<void> Function() onRequireSignIn;

  @override
  State<_SessionUnlockView> createState() => _SessionUnlockViewState();
}

class _SessionUnlockViewState extends State<_SessionUnlockView> {
  final _passwordController = TextEditingController();
  final _passwordFocusNode = FocusNode();
  var _isUnlocking = false;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _unlock() async {
    if (widget.sessionState != SessionState.locked) {
      if (_isUnlocking) return;
      setState(() {
        _isUnlocking = true;
        _error = null;
      });
      try {
        await widget.onRequireSignIn();
      } on Object catch (error) {
        if (mounted) {
          setState(() {
            _error = error is ServiceFailure
                ? error.message
                : 'تعذر العودة إلى تسجيل الدخول.';
          });
        }
      } finally {
        if (mounted) setState(() => _isUnlocking = false);
      }
      return;
    }
    if (_isUnlocking || _passwordController.text.isEmpty) return;
    setState(() {
      _isUnlocking = true;
      _error = null;
    });
    try {
      await AppStoreScope.of(
        context,
        listen: false,
      ).unlock(_passwordController.text);
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error is ServiceFailure
            ? error.message
            : 'تعذر فتح الجلسة. حاول مرة أخرى.';
      });
      _passwordController.clear();
      _passwordFocusNode.requestFocus();
    } finally {
      if (mounted) setState(() => _isUnlocking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canUnlock = widget.sessionState == SessionState.locked;
    return FocusScope(
      autofocus: true,
      canRequestFocus: true,
      child: Material(
        key: const Key('sessionLockOverlay'),
        color: AppColors.background,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Card(
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                    const Icon(
                      Icons.lock_clock_rounded,
                      size: 52,
                      color: AppModuleColors.settings,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      canUnlock ? 'الجلسة مقفلة' : 'الجلسة غير نشطة',
                      textAlign: TextAlign.center,
                      style: AppTypography.sectionTitle,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      canUnlock
                          ? 'أدخل كلمة مرور المستخدم الحالي للمتابعة'
                          : 'انتهت الجلسة. ارجع إلى شاشة تسجيل الدخول للمتابعة.',
                      textAlign: TextAlign.center,
                      style: AppTypography.fieldText,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    if (canUnlock)
                      AppTextField(
                        fieldKey:
                            const Key('sessionUnlockPasswordField'),
                        controller: _passwordController,
                        focusNode: _passwordFocusNode,
                        label: 'كلمة المرور',
                        icon: Icons.password_rounded,
                        obscureText: true,
                        autofocus: true,
                        enabled: !_isUnlocking,
                        onChanged: (_) {
                          if (_error != null) setState(() => _error = null);
                        },
                        onSubmitted: (_) => _unlock(),
                      ),
                    if (_error != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      AppInfoBanner(
                        key: const Key('sessionUnlockError'),
                        message: _error!,
                        icon: Icons.error_outline_rounded,
                        foregroundColor: AppColors.danger,
                        backgroundColor: AppColors.dangerSurface,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                      Focus(
                        autofocus: !canUnlock,
                        onKeyEvent: (_, event) {
                          if (event is KeyDownEvent &&
                              (event.logicalKey ==
                                      LogicalKeyboardKey.enter ||
                                  event.logicalKey ==
                                      LogicalKeyboardKey.space)) {
                            unawaited(_unlock());
                            return KeyEventResult.handled;
                          }
                          return KeyEventResult.ignored;
                        },
                        child: AppButton(
                          key: const Key('sessionUnlockButton'),
                          label: canUnlock
                              ? 'فتح الجلسة'
                              : 'العودة إلى تسجيل الدخول',
                          icon: canUnlock
                              ? Icons.lock_open_rounded
                              : Icons.login_rounded,
                          width: double.infinity,
                          isLoading: _isUnlocking,
                          onPressed: _isUnlocking ? null : _unlock,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
