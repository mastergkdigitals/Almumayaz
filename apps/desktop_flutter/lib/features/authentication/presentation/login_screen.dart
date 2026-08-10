import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/app_state/app_store.dart';
import '../../../core/design/app_design_system.dart';
import '../../../core/services/service_failure.dart';
import '../../dashboard/presentation/dashboard_screen.dart';
import '../domain/session_models.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static final _enterKeys = {
    LogicalKeyboardKey.enter,
    LogicalKeyboardKey.numpadEnter,
  };

  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _usernameFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _keyHoldGuard = AppKeyHoldGuard();
  bool _hidePassword = true;
  bool _isAuthenticating = false;
  String? _authenticationError;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    _usernameFocusNode.dispose();
    _passwordFocusNode.dispose();
    _keyHoldGuard.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_isAuthenticating || !_formKey.currentState!.validate()) return;
    setState(() {
      _isAuthenticating = true;
      _authenticationError = null;
    });
    final username = _username.text.trim();
    try {
      await AppStoreScope.of(context, listen: false).signIn(
        SignInCredentials(
          username: username,
          password: _password.text,
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => DashboardScreen(username: username),
        ),
      );
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _authenticationError = _loginFailureMessage(error));
      _passwordFocusNode.requestFocus();
    } finally {
      if (mounted) setState(() => _isAuthenticating = false);
    }
  }

  void _clearAuthenticationError() {
    if (_authenticationError == null) return;
    setState(() => _authenticationError = null);
  }

  void _focusNextField() {
    _keyHoldGuard.runOnce(
      keys: {LogicalKeyboardKey.tab},
      action: () {
        if (_usernameFocusNode.hasFocus) {
          _passwordFocusNode.requestFocus();
        } else {
          _usernameFocusNode.requestFocus();
        }
      },
    );
  }

  void _focusPreviousField() {
    _keyHoldGuard.runOnce(
      keys: {LogicalKeyboardKey.tab},
      action: () {
        if (_passwordFocusNode.hasFocus) {
          _usernameFocusNode.requestFocus();
        } else {
          _passwordFocusNode.requestFocus();
        }
      },
    );
  }

  void _submitUsername() {
    _keyHoldGuard.runOnce(
      keys: _enterKeys,
      action: () => _passwordFocusNode.requestFocus(),
    );
  }

  void _submitPassword() {
    _keyHoldGuard.runOnce(
      keys: _enterKeys,
      action: () => _login(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        textDirection: TextDirection.ltr,
        children: [
          const Expanded(flex: 6, child: _BrandPanel()),
          Expanded(
            flex: 5,
            child: ColoredBox(
              key: const Key('loginFormSection'),
              color: AppColors.background,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: _buildForm(context),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.tab): _focusNextField,
          const SingleActivator(LogicalKeyboardKey.tab, shift: true):
              _focusPreviousField,
        },
        child: FocusTraversalGroup(
          policy: OrderedTraversalPolicy(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'تسجيل الدخول',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'أدخل بيانات المستخدم للوصول إلى النظام',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.xl),
              FocusTraversalOrder(
                order: const NumericFocusOrder(1),
                child: AppTextField(
                  fieldKey: const Key('usernameField'),
                  controller: _username,
                  label: 'اسم المستخدم',
                  icon: Icons.person_outline_rounded,
                  focusNode: _usernameFocusNode,
                  autofocus: true,
                  textInputAction: TextInputAction.next,
                  enabled: !_isAuthenticating,
                  onChanged: (_) => _clearAuthenticationError(),
                  onSubmitted: (_) => _submitUsername(),
                  validator: (value) =>
                      value == null || value.trim().isEmpty
                          ? 'أدخل اسم المستخدم'
                          : null,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              FocusTraversalOrder(
                order: const NumericFocusOrder(2),
                child: AppTextField(
                  fieldKey: const Key('passwordField'),
                  controller: _password,
                  label: 'كلمة المرور',
                  icon: Icons.lock_outline_rounded,
                  focusNode: _passwordFocusNode,
                  obscureText: _hidePassword,
                  enabled: !_isAuthenticating,
                  onChanged: (_) => _clearAuthenticationError(),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submitPassword(),
                  suffixIcon: AppFieldIconButton(
                    buttonKey: const Key('passwordVisibilityButton'),
                    icon: _hidePassword
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    onPressed: () =>
                        setState(() => _hidePassword = !_hidePassword),
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'أدخل كلمة المرور'
                      : null,
                ),
              ),
              if (_authenticationError != null) ...[
                const SizedBox(height: AppSpacing.md),
                AppInfoBanner(
                  key: const Key('loginAuthenticationError'),
                  message: _authenticationError!,
                  icon: Icons.error_outline_rounded,
                  foregroundColor: AppColors.danger,
                  backgroundColor: AppColors.dangerSurface,
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              ExcludeFocus(
                child: AppButton(
                  key: const Key('loginButton'),
                  label: 'دخول',
                  icon: Icons.login_rounded,
                  width: double.infinity,
                  isLoading: _isAuthenticating,
                  onPressed: _isAuthenticating ? null : _login,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const AppInfoBanner(
                message: 'نسخة تصميمية: admin / password',
                icon: null,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _loginFailureMessage(Object error) {
  if (error is ServiceFailure) return error.message;
  return 'تعذر تسجيل الدخول. حاول مرة أخرى.';
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      key: const Key('loginBrandSection'),
      color: AppColors.primaryDark,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const AppLogo(
                size: 112,
                padding: 0,
                showBackground: false,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'المميز للمحاسبة',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: AppColors.onStrong,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'إدارة أعمالك بثقة، حتى بدون إنترنت',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(color: AppColors.onStrong.withAlpha(179)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
