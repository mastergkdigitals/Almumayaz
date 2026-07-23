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
    _ModuleItem('المشتريات', Icons.shopping_cart_outlined, Color(0xFFB86B25)),
    _ModuleItem('المبيعات', Icons.point_of_sale_outlined, Color(0xFF1F7A65)),
    _ModuleItem('الصندوق', Icons.account_balance_wallet_outlined, Color(0xFF315D9B)),
    _ModuleItem('الزبائن والمجهزون', Icons.groups_outlined, Color(0xFF7257A5)),
    _ModuleItem('المواد', Icons.inventory_2_outlined, Color(0xFF27717A)),
    _ModuleItem('المخازن', Icons.warehouse_outlined, Color(0xFF5C6B3D)),
    _ModuleItem('النقل المخزني', Icons.swap_horiz_rounded, Color(0xFF8B5E3C)),
    _ModuleItem('المصاريف', Icons.receipt_long_outlined, Color(0xFFA44747)),
    _ModuleItem('سندات القبض والصرف', Icons.payments_outlined, Color(0xFF3D6C91)),
    _ModuleItem('الأقساط', Icons.calendar_month_outlined, Color(0xFF93672E)),
    _ModuleItem('التقارير', Icons.bar_chart_rounded, Color(0xFF385D76)),
    _ModuleItem('المستخدمون والصلاحيات', Icons.admin_panel_settings_outlined, Color(0xFF6E526E)),
    _ModuleItem('النسخ الاحتياطي', Icons.backup_outlined, Color(0xFF4A6D56)),
    _ModuleItem('الإعدادات', Icons.settings_outlined, Color(0xFF5D6865)),
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
        body: ResponsiveShell(
          builder: (context, info) {
            final columns = info.availableWidth >= 1320
                ? 4
                : info.availableWidth >= 900
                    ? 3
                    : 2;
            return SingleChildScrollView(
              padding: EdgeInsets.all(
                  info.isCompact ? AppSpacing.md : AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('لوحة التحكم',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: AppSpacing.sm),
                  const Text('اختر القسم الذي تريد العمل عليه',
                      style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: AppSpacing.lg),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: modules.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      mainAxisSpacing: AppSpacing.md,
                      crossAxisSpacing: AppSpacing.md,
                      childAspectRatio: info.isCompact ? 1.65 : 1.9,
                    ),
                    itemBuilder: (_, index) =>
                        _ModuleCard(item: modules[index]),
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

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({required this.item});
  final _ModuleItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('سيتم تصميم شاشة ${item.title} لاحقاً')),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Icon(item.icon, color: item.color, size: 28),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(item.title,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ),
              const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 16, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModuleItem {
  const _ModuleItem(this.title, this.icon, this.color);
  final String title;
  final IconData icon;
  final Color color;
}
