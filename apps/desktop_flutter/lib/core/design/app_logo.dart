import 'package:flutter/material.dart';

import 'app_theme.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 48,
    this.padding = 6,
    this.showBackground = true,
  });

  final double size;
  final double padding;
  final bool showBackground;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      'assets/png/logo.png',
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => const Icon(
        Icons.auto_graph_rounded,
        color: AppColors.primary,
      ),
    );

    if (!showBackground) {
      return SizedBox.square(
        dimension: size,
        child: image,
      );
    }

    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: image,
    );
  }
}
