import 'package:flutter/material.dart';
import '../../../core/design/app_design_system.dart';
import '../../../core/design/components/app_header_button.dart';
import '../../about/presentation/about_screen.dart';
import '../../auth/presentation/login_screen.dart';
import 'dashboard_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({required this.username, super.key});

  final String username;

  static const modules = <_ModuleItem>[
    _ModuleItem(
      'purchases',
      'المشتريات',
      Icons.shopping_cart_checkout_rounded,
      palette: AppModulePalettes.purchases,
    ),
    _ModuleItem(
      'sales',
      'المبيعات',
      Icons.point_of_sale_rounded,
      palette: AppModulePalettes.sales,
    ),
    _ModuleItem(
      'cashbox',
      'الصندوق',
      Icons.account_balance_wallet_rounded,
      palette: AppModulePalettes.cashbox,
    ),
    _ModuleItem(
      'parties',
      'الأطراف',
      Icons.groups_rounded,
      palette: AppModulePalettes.parties,
    ),
    _ModuleItem(
      'company',
      'اسم الشركة + الشعار',
      Icons.apartment_rounded,
      palette: AppModulePalettes.company,
      displayOnly: true,
    ),
    _ModuleItem(
      'warehouses',
      'المخازن',
      Icons.warehouse_rounded,
      palette: AppModulePalettes.warehouses,
    ),
    _ModuleItem(
      'reports',
      'التقارير',
      Icons.analytics_rounded,
      palette: AppModulePalettes.reports,
    ),
    _ModuleItem(
      'settings',
      'الإعدادات',
      Icons.settings_rounded,
      palette: AppModulePalettes.settings,
    ),
    _ModuleItem(
      'about',
      'حول',
      Icons.info_rounded,
      palette: AppModulePalettes.about,
      isAbout: true,
    ),
  ];

  void _openModule(BuildContext context, _ModuleItem item) {
    if (item.isAbout) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const AboutScreen(),
        ),
      );
      return;
    }

    AppToast.showInfo(context, 'سيتم تصميم شاشة ${item.title} في مرحلتها');
  }

  @override
  Widget build(BuildContext context) {
    return AppShortcutScope(
      onRefresh: () => AppToast.showInfo(context, 'تم تحديث الشاشة'),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            _DashboardHeader(
              username: username,
              onLogout: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    const columns = 3;
                    const rows = 3;
                    const spacing = AppSpacing.lg;
                    final cardWidth =
                        (constraints.maxWidth - spacing * (columns - 1)) /
                            columns;
                    final cardHeight =
                        (constraints.maxHeight - spacing * (rows - 1)) / rows;
                    final aspectRatio =
                        cardHeight > 0 ? cardWidth / cardHeight : 1.6;

                    return GridView.builder(
                      clipBehavior: Clip.none,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: modules.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: spacing,
                        mainAxisSpacing: spacing,
                        childAspectRatio: aspectRatio,
                      ),
                      itemBuilder: (context, index) {
                        final item = modules[index];
                        return DashboardCard(
                          key: Key('dashboardCard_${item.id}'),
                          title: item.title,
                          icon: item.icon,
                          colors: item.palette.gradient,
                          shadowColor: item.palette.shadow,
                          onTap: item.displayOnly
                              ? null
                              : () => _openModule(context, item),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.username,
    required this.onLogout,
  });

  final String username;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppHeaderSizes.dashboard,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      decoration: const BoxDecoration(
        color: AppColors.headerBackground,
        border: Border(
          bottom: BorderSide(color: AppColors.headerBorder),
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Text(
            'المميز للمحاسبة',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'مرحباً، $username',
              key: const Key('dashboardWelcome'),
              textDirection: TextDirection.rtl,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: AppHeaderIconButton(
              key: const Key('dashboardLogout'),
              tooltipKey: const Key('dashboardLogoutTooltip'),
              icon: Icons.logout_rounded,
              tooltip: 'تسجيل الخروج',
              flipIconHorizontally: true,
              onPressed: onLogout,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModuleItem {
  const _ModuleItem(
    this.id,
    this.title,
    this.icon, {
    required this.palette,
    this.displayOnly = false,
    this.isAbout = false,
  });

  final String id;
  final String title;
  final IconData icon;
  final AppModulePalette palette;
  final bool displayOnly;
  final bool isAbout;
}
