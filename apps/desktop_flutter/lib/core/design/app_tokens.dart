import 'package:flutter/material.dart';

abstract final class AppColors {
  static const primary = Color(0xFF1D4ED8);
  static const primaryDark = Color(0xFF102A56);
  static const accent = Color(0xFFC89B3C);
  static const background = Color(0xFFF5F9FF);
  static const surface = Colors.white;
  static const onStrong = Colors.white;
  static const border = Color(0xFFD6E3F0);
  static const textPrimary = Color(0xFF142033);
  static const textSecondary = Color(0xFF5F7085);
  static const success = Color(0xFF0F7A4D);
  static const warning = Color(0xFFB75C00);
  static const danger = Color(0xFFB42318);
  static const info = Color(0xFF1D4ED8);
  static const disabled = Color(0xFF94A3B8);

  static const headerBackground = Color(0xFFFAF8F3);
  static const headerBorder = Color(0xFFE4E0D7);
  static const infoSurface = Color(0xFFE8F1FF);
  static const successSurface = Color(0xFFE8F7EF);
  static const warningSurface = Color(0xFFFFF3E5);
  static const dangerSurface = Color(0xFFFDECEC);
  static const neutralSurface = Color(0xFFF1F5F9);
  static const disabledSurface = Color(0xFFF8FAFC);
  static const controlHoverSurface = Color(0xFFF3F7FC);
  static const controlHoverBorder = Color(0xFFB8CAE0);
  static const tableHeaderSurface = Color(0xFFEAF2FF);
  static const menuShadow = Color(0x24102A56);
  static const switchTrack = Color(0xFFE2E8F0);
  static const switchTrackSelected = Color(0xFFBFDBFE);
}

abstract final class AppModuleColors {
  static const parties = Color(0xFF1D4ED8);
  static const purchases = Color(0xFF10B981);
  static const sales = Color(0xFF7C3AED);
  static const cashbox = Color(0xFFF97316);
  static const warehouses = Color(0xFF92400E);
  static const company = Color(0xFFD4A72C);
  static const reports = Color(0xFF14B8A6);
  static const settings = Color(0xFF6B7280);
  static const about = Color(0xFF06B6D4);
}

@immutable
class AppModulePalette {
  const AppModulePalette({
    required this.dark,
    required this.middle,
    required this.light,
    required this.shadow,
  });

  final Color dark;
  final Color middle;
  final Color light;
  final Color shadow;

  List<Color> get gradient => [dark, middle, light];
}

abstract final class AppModulePalettes {
  static const purchases = AppModulePalette(
    dark: Color(0xFF064E3B),
    middle: AppModuleColors.purchases,
    light: Color(0xFFA7F3D0),
    shadow: Color(0xFF059669),
  );
  static const sales = AppModulePalette(
    dark: Color(0xFF4C1D95),
    middle: AppModuleColors.sales,
    light: Color(0xFFC4B5FD),
    shadow: AppModuleColors.sales,
  );
  static const cashbox = AppModulePalette(
    dark: Color(0xFF9A3412),
    middle: AppModuleColors.cashbox,
    light: Color(0xFFFED7AA),
    shadow: AppModuleColors.cashbox,
  );
  static const parties = AppModulePalette(
    dark: Color(0xFF0B1F3A),
    middle: AppModuleColors.parties,
    light: Color(0xFFBFDBFE),
    shadow: AppModuleColors.parties,
  );
  static const company = AppModulePalette(
    dark: Color(0xFF6B4F00),
    middle: AppModuleColors.company,
    light: Color(0xFFFFE69A),
    shadow: Color(0xFFB8860B),
  );
  static const warehouses = AppModulePalette(
    dark: Color(0xFF5C2E0E),
    middle: AppModuleColors.warehouses,
    light: Color(0xFFD6A36A),
    shadow: AppModuleColors.warehouses,
  );
  static const reports = AppModulePalette(
    dark: Color(0xFF115E59),
    middle: AppModuleColors.reports,
    light: Color(0xFF99F6E4),
    shadow: AppModuleColors.reports,
  );
  static const settings = AppModulePalette(
    dark: Color(0xFF374151),
    middle: AppModuleColors.settings,
    light: Color(0xFFD1D5DB),
    shadow: AppModuleColors.settings,
  );
  static const about = AppModulePalette(
    dark: Color(0xFF155E75),
    middle: AppModuleColors.about,
    light: Color(0xFFA5F3FC),
    shadow: AppModuleColors.about,
  );
}

abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
}

abstract final class AppRadii {
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 18.0;
  static const xl = 24.0;
}

abstract final class AppControlHeights {
  static const compact = 40.0;
  static const standard = 48.0;
  static const large = 56.0;
}

abstract final class AppHeaderSizes {
  static const screen = 104.0;
  static const dashboard = 112.0;
}

abstract final class AppIconSizes {
  static const sm = 16.0;
  static const md = 20.0;
  static const lg = 24.0;
  static const xl = 32.0;
}

abstract final class AppDurations {
  static const fast = Duration(milliseconds: 120);
  static const normal = Duration(milliseconds: 180);
  static const slow = Duration(milliseconds: 260);
}

abstract final class AppTooltipColors {
  static const background = Color(0xFFFFF4C2);
  static const border = Color(0xFFD8A900);
  static const text = Color(0xFF332400);
}

abstract final class AppBreakpoints {
  static const designWidth = 1440.0;
  static const compactDesktop = 1280.0;
}

abstract final class AppDialogSizes {
  static const small = 480.0;
  static const medium = 680.0;
  static const large = 920.0;
  static const maxHeightFactor = 0.88;
}

abstract final class AppTypography {
  static const screenTitle = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 28,
    fontWeight: FontWeight.w800,
  );

  static const sectionTitle = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 18,
    fontWeight: FontWeight.w700,
  );

  static const fieldText = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );

  static const buttonText = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
  );

  static const tableHeader = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 14,
    fontWeight: FontWeight.w700,
  );

  static const tableCell = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );
}

abstract final class AppShadows {
  static const soft = <BoxShadow>[
    BoxShadow(
      color: Color(0x140F2742),
      blurRadius: 18,
      offset: Offset(0, 6),
    ),
  ];
}
