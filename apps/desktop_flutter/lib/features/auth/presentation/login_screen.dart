import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/design/app_logo.dart';
import '../../../core/design/app_theme.dart';
import '../../../core/responsive/responsive_shell.dart';
import '../../dashboard/presentation/dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _passwordFocus = FocusNode();
  bool _hidePassword = true;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _login() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => DashboardScreen(username: _username.text.trim()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): _login,
      },
      child: Scaffold(
        body: ResponsiveLayout(
          builder: (context, info) => Row(
            children: [
              if (!info.isCompact) const Expanded(flex: 6, child: _BrandPanel()),
              Expanded(
                flex: info.isCompact ? 1 : 5,
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 430),
                      child: _buildForm(context, info.isCompact),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, bool compact) {
    return Form(
      key: _formKey,
      child: FocusTraversalGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (compact) ...[
              const Center(child: AppLogo(size: 64)),
              const SizedBox(height: AppSpacing.md),
            ],
            Text(
              'تسجيل الدخول',
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'أدخل بيانات المستخدم للوصول إلى النظام',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xl),
            TextFormField(
              key: const Key('usernameField'),
              controller: _username,
              autofocus: true,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
              decoration: const InputDecoration(
                labelText: 'اسم المستخدم',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'أدخل اسم المستخدم'
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              key: const Key('passwordField'),
              controller: _password,
              focusNode: _passwordFocus,
              obscureText: _hidePassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _login(),
              decoration: InputDecoration(
                labelText: 'كلمة المرور',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  tooltip:
                      _hidePassword ? 'إظهار كلمة المرور' : 'إخفاء كلمة المرور',
                  onPressed: () =>
                      setState(() => _hidePassword = !_hidePassword),
                  icon: Icon(_hidePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                ),
              ),
              validator: (value) =>
                  value == null || value.isEmpty ? 'أدخل كلمة المرور' : null,
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              key: const Key('loginButton'),
              onPressed: _login,
              icon: const Icon(Icons.login_rounded),
              label: const Text('دخول'),
            ),
            const SizedBox(height: AppSpacing.md),
            const DecoratedBox(
              decoration: BoxDecoration(
                color: Color(0xFFEAF3F1),
                borderRadius: BorderRadius.all(Radius.circular(AppRadii.sm)),
              ),
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Text(
                  'نسخة تصميمية: استخدم أي اسم وكلمة مرور غير فارغين.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.primary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.primaryDark,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Spacer(),
            const AppLogo(size: 72, padding: 8),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'المميز ERP',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'إدارة أعمالك بثقة، حتى بدون إنترنت',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: Colors.white70),
            ),
            const Spacer(),
            const Text('نسخة تصميمية أولية',
                style: TextStyle(color: Colors.white54)),
          ],
        ),
      ),
    );
  }
}
