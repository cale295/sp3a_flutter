import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Accessible primary button following the Inclusive Modern Design system.
/// Default height is 54px for large, easy-to-tap touch targets.
/// Font size is 15pt for clear readability for both senior and young users.
class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutline;
  final IconData? icon;
  final Color? color;
  final double? width;
  final double height;

  const PrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isOutline = false,
    this.icon,
    this.color,
    this.width,
    this.height = 54, // Accessible minimum tap target
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final buttonColor = color ?? (isDark ? AppColors.primaryLight : AppColors.primary);

    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null && !isLoading) ...[
          Icon(
            icon,
            size: 20,
            color: isOutline ? buttonColor : Colors.white,
          ),
          const SizedBox(width: 8),
        ],
        if (isLoading)
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation<Color>(
                isOutline ? buttonColor : Colors.white,
              ),
            ),
          )
        else
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15, // Readable for seniors
                fontWeight: FontWeight.w700,
                color: isOutline ? buttonColor : Colors.white,
                letterSpacing: 0.1,
              ),
            ),
          ),
      ],
    );

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    );

    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: isOutline
          ? OutlinedButton(
              onPressed: isLoading ? null : onPressed,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: buttonColor, width: 1.5),
                shape: shape,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              child: content,
            )
          : ElevatedButton(
              onPressed: isLoading ? null : onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: shape,
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              child: content,
            ),
    );
  }
}
