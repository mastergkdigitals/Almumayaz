import 'package:flutter/material.dart';

import '../../../core/design/app_design_system.dart';
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
  bool _hidePassword = true;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
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
      child: FocusTraversalGroup(
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
            AppTextField(
              fieldKey: const Key('usernameField'),
              controller: _username,
              label: 'اسم المستخدم',
              icon: Icons.person_outline_rounded,
              autofocus: true,
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => AppFocusTraversal.next(context),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'أدخل اسم المستخدم'
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              fieldKey: const Key('passwordField'),
              controller: _password,
              label: 'كلمة المرور',
              icon: Icons.lock_outline_rounded,
              obscureText: _hidePassword,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _login(),
              suffixIcon: AppFieldIconButton(
                icon: _hidePassword
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded,
                tooltip: _hidePassword
                    ? 'إظهار كلمة المرور'
                    : 'إخفاء كلمة المرور',
                onPressed: () =>
                    setState(() => _hidePassword = !_hidePassword),
              ),
              validator: (value) =>
                  value == null || value.isEmpty ? 'أدخل كلمة المرور' : null,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              key: const Key('loginButton'),
              label: 'دخول',
              icon: Icons.login_rounded,
              width: double.infinity,
              onPressed: _login,
            ),
            const SizedBox(height: AppSpacing.md),
            const AppInfoBanner(
              message: 'نسخة تصميمية: استخدم أي اسم وكلمة مرور غير فارغين.',
              icon: null,
              textAlign: TextAlign.center,
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
