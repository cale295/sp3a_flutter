import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final bool isLarge;

  const StatusBadge({
    super.key,
    required this.status,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    Color textColor;
    String label;

    final normalized = status.toLowerCase().replaceAll('_', ' ');

    switch (normalized) {
      case 'lunas':
      case 'sukses':
      case 'lunas semua':
        color = AppColors.success.withAlpha(31);
        textColor = AppColors.success;
        label = normalized.toUpperCase();
        break;
      case 'belum dibayar':
      case 'belum bayar':
      case 'gagal':
      case 'ada tunggakan':
        color = AppColors.error.withAlpha(31);
        textColor = AppColors.error;
        label = normalized.toUpperCase();
        break;
      case 'pending':
        color = AppColors.warning.withAlpha(31);
        textColor = AppColors.warning;
        label = normalized.toUpperCase();
        break;
      default:
        color = AppColors.info.withAlpha(31);
        textColor = AppColors.info;
        label = status.toUpperCase();
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isLarge ? 14 : 10,
        vertical: isLarge ? 6 : 4,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: isLarge ? 13 : 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
