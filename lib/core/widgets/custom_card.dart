import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Borderless card widget with an elegant, subtle drop shadow.
/// Conforms to the Inclusive Modern Design system — no hard borders,
/// only soft depth cues for a premium, clean appearance.
class CustomCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? color;
  final bool hasBorder;

  const CustomCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.color,
    this.hasBorder = false, // Default borderless for modern look
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardColor = color ?? (isDark ? AppColors.cardDark : AppColors.cardLight);

    // Elegant, ultra-soft shadow only in light mode
    final softShadow = isDark
        ? null
        : [
            BoxShadow(
              color: Colors.black.withAlpha(8), // 0.03 opacity
              blurRadius: 12,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withAlpha(5),
              blurRadius: 4,
              spreadRadius: 0,
              offset: const Offset(0, 1),
            ),
          ];

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        // Subtle border only when explicitly requested
        border: hasBorder
            ? Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                width: 1,
              )
            : null,
        boxShadow: softShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(20),
            child: child,
          ),
        ),
      ),
    );
  }
}
