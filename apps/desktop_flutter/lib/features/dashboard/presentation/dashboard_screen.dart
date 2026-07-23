import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/design/app_logo.dart';
import '../../../core/design/app_theme.dart';
import '../../../core/responsive/responsive_shell.dart';
import '../../auth/presentation/login_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({required this.username, super.key});

  final String username;

  static const modules = <_ModuleItem>[
    _ModuleItem('purchases', 'المشتريات', Icons.shopping_cart_outlined,
        Color(0xFFB86B25)),
    _ModuleItem('sales', 'المبيعات', Icons.point_of_sale_outlined,
        Color(0xFF1F7A65)),
    _ModuleItem('cashbox', 'الصندوق', Icons.account_balance_wallet_outlined,
        Color(0xFF315D9B)),
    _ModuleItem(
        'parties', 'الأطراف', Icons.groups_outlined, Color(0xFF7257A5)),
    _ModuleItem(
      'company',
      'اسم الشركة',
      Icons.business_outlined,
      AppColors.primary,
      subtitle: 'يُحدد من الإعدادات',
      isCompany: true,
    ),
    _ModuleItem(
        'warehouses', 'المخازن', Icons.warehouse_outlined, Color(0xFF5C6B3D)),
    _ModuleItem(
        'reports', 'التقارير', Icons.bar_chart_rounded, Color(0xFF385D76)),
    _ModuleItem(
        'settings', 'الإعدادات', Icons.settings_outlined, Color(0xFF5D6865)),
    _ModuleItem('about', 'حول', Icons.info_outline_rounded, Color(0xFF8B5E3C),
        isAbout: true),
  ];

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.f5): () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم تحديث الشاشة')),
          );
        },
      },
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 72,
          backgroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          title: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppLogo(size: 38, padding: 4),
              SizedBox(width: AppSpacing.sm),
              Text('المميز ERP',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
          actions: [
            Center(
              child: Text('مرحباً، $username',
                  style: const TextStyle(color: AppColors.textSecondary)),
            ),
            const SizedBox(width: AppSpacing.sm),
            IconButton(
              tooltip: 'تسجيل الخروج',
              onPressed: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
              ),
              icon: const Icon(Icons.logout_rounded),
            ),
            const SizedBox(width: AppSpacing.md),
          ],
        ),
        body: ResponsiveLayout(
          builder: (context, info) {
            return SingleChildScrollView(
              padding: EdgeInsets.all(
                info.isCompact ? AppSpacing.md : AppSpacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'لوحة التحكم',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Text(
                    'اختر القسم الذي تريد العمل عليه',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: modules.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: info.isCompact ? 2 : 3,
                      mainAxisSpacing: AppSpacing.md,
                      crossAxisSpacing: AppSpacing.md,
                      childAspectRatio: info.isCompact ? 1.8 : 2.25,
                    ),
                    itemBuilder: (_, index) =>
                        _DashboardCard(item: modules[index]),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({required this.item});

  final _ModuleItem item;

  void _open(BuildContext context) {
    if (item.isAbout) {
      showAboutDialog(
        context: context,
        applicationName: 'المميز ERP',
        applicationVersion: '0.1.0',
        applicationIcon: const AppLogo(size: 56),
        children: const [
          Text('نظام إدارة أعمال عربي يعمل على Windows.'),
        ],
      );
      return;
    }

    final message = item.isCompany
        ? 'سيظهر اسم الشركة بعد ضبط الإعدادات'
        : 'سيتم تصميم شاشة ${item.title} في مرحلتها';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      key: Key('dashboardCard_${item.id}'),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _open(context),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              if (item.isCompany)
                const AppLogo(size: 58, padding: 5)
              else
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                  child: Icon(item.icon, color: item.color, size: 30),
                ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    if (item.subtitle != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        item.subtitle!,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModuleItem {
  const _ModuleItem(
    this.id,
    this.title,
    this.icon,
    this.color, {
    this.subtitle,
    this.isCompany = false,
    this.isAbout = false,
  });

  final String id;
  final String title;
  final IconData icon;
  final Color color;
  final String? subtitle;
  final bool isCompany;
  final bool isAbout;
}
