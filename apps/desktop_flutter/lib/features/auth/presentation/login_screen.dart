import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/design/app_logo.dart';
import '../../../core/design/app_theme.dart';
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
            TextFormField(
              key: const Key('usernameField'),
              controller: _username,
              style: AppTypography.fieldText,
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
              style: AppTypography.fieldText,
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
                  icon: Icon(
                    _hidePassword
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                  ),
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
                color: Color(0xFFE8F1FF),
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
                      color: Colors.white,
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
                    ?.copyWith(color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
