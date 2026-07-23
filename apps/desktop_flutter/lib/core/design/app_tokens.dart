import 'package:flutter/material.dart';

abstract final class AppColors {
  static const primary = Color(0xFF1D4ED8);
  static const primaryDark = Color(0xFF102A56);
  static const accent = Color(0xFFC89B3C);
  static const background = Color(0xFFF5F9FF);
  static const surface = Colors.white;
  static const border = Color(0xFFD6E3F0);
  static const textPrimary = Color(0xFF142033);
  static const textSecondary = Color(0xFF5F7085);
  static const success = Color(0xFF0F7A4D);
  static const warning = Color(0xFFB75C00);
  static const danger = Color(0xFFB42318);
  static const info = Color(0xFF1D4ED8);
  static const disabled = Color(0xFF94A3B8);
}

abstract final class AppModuleColors {
  static const parties = Color(0xFF1D4ED8);
  static const purchases = Color(0xFF10B981);
  static const sales = Color(0xFF7C3AED);
  static const cashbox = Color(0xFFF97316);
  static const warehouses = Color(0xFF92400E);
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
