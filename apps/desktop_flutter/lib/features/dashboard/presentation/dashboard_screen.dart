import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/design/app_logo.dart';
import '../../../core/design/app_theme.dart';
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
      colors: [Color(0xFF064E3B), Color(0xFF10B981), Color(0xFFA7F3D0)],
      shadowColor: Color(0xFF059669),
    ),
    _ModuleItem(
      'sales',
      'المبيعات',
      Icons.point_of_sale_rounded,
      colors: [Color(0xFF4C1D95), Color(0xFF7C3AED), Color(0xFFC4B5FD)],
      shadowColor: Color(0xFF7C3AED),
    ),
    _ModuleItem(
      'cashbox',
      'الصندوق',
      Icons.account_balance_wallet_rounded,
      colors: [Color(0xFF9A3412), Color(0xFFF97316), Color(0xFFFED7AA)],
      shadowColor: Color(0xFFF97316),
    ),
    _ModuleItem(
      'parties',
      'الأطراف',
      Icons.group_rounded,
      colors: [Color(0xFF0B1F3A), Color(0xFF1D4ED8), Color(0xFFBFDBFE)],
      shadowColor: Color(0xFF1D4ED8),
    ),
    _ModuleItem(
      'company',
      'اسم الشركة + الشعار',
      Icons.apartment_rounded,
      colors: [Color(0xFF6B4F00), Color(0xFFD4A72C), Color(0xFFFFE69A)],
      shadowColor: Color(0xFFB8860B),
      displayOnly: true,
    ),
    _ModuleItem(
      'warehouses',
      'المخازن',
      Icons.warehouse_rounded,
      colors: [Color(0xFF5C2E0E), Color(0xFF92400E), Color(0xFFD6A36A)],
      shadowColor: Color(0xFF92400E),
    ),
    _ModuleItem(
      'reports',
      'التقارير',
      Icons.analytics_rounded,
      colors: [Color(0xFF115E59), Color(0xFF14B8A6), Color(0xFF99F6E4)],
      shadowColor: Color(0xFF14B8A6),
    ),
    _ModuleItem(
      'settings',
      'الإعدادات',
      Icons.settings_rounded,
      colors: [Color(0xFF374151), Color(0xFF6B7280), Color(0xFFD1D5DB)],
      shadowColor: Color(0xFF6B7280),
    ),
    _ModuleItem(
      'about',
      'حول',
      Icons.info_rounded,
      colors: [Color(0xFF155E75), Color(0xFF06B6D4), Color(0xFFA5F3FC)],
      shadowColor: Color(0xFF06B6D4),
      isAbout: true,
    ),
  ];

  void _openModule(BuildContext context, _ModuleItem item) {
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('سيتم تصميم شاشة ${item.title} في مرحلتها')),
    );
  }

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
                          subtitle: item.subtitle,
                          icon: item.icon,
                          colors: item.colors,
                          shadowColor: item.shadowColor,
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
      height: 112,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      decoration: const BoxDecoration(
        color: Color(0xFFFAF8F3),
        border: Border(
          bottom: BorderSide(color: Color(0xFFE4E0D7)),
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
            child: Semantics(
              button: true,
              label: 'تسجيل الخروج',
              child: Material(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: Color(0xFFD1D5DB)),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  key: const Key('dashboardLogout'),
                  onTap: onLogout,
                  hoverColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  splashColor: Colors.transparent,
                  child: const SizedBox.square(
                    dimension: 52,
                    child: Icon(
                      Icons.logout_rounded,
                      size: 24,
                      color: Color(0xFF111827),
                    ),
                  ),
                ),
              ),
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
    required this.colors,
    required this.shadowColor,
    this.subtitle,
    this.displayOnly = false,
    this.isAbout = false,
  });

  final String id;
  final String title;
  final IconData icon;
  final List<Color> colors;
  final Color shadowColor;
  final String? subtitle;
  final bool displayOnly;
  final bool isAbout;
}
