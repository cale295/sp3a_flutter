import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../screens/auth/login_screen.dart';

class LogoutConfirmationDialog extends ConsumerWidget {
  const LogoutConfirmationDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDark ? AppColors.cardDark : AppColors.cardLight,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Text(
        'Konfirmasi Keluar',
        style: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.bold,
          fontSize: 18,
          color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
          letterSpacing: -0.3,
        ),
      ),
      content: Text(
        'Yakin ingin keluar dari akun Anda? Anda harus masuk kembali untuk mengakses data.',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
          height: 1.5,
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Batal',
            style: GoogleFonts.plusJakartaSans(
              color: isDark ? AppColors.textDarkSecondary : Colors.grey[600],
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
        TextButton(
          onPressed: () async {
            // Dismiss dialog first
            Navigator.of(context).pop();

            try {
              // a. Call supabase.auth.signOut()
              await Supabase.instance.client.auth.signOut();

              // b. Clear any cached user data or local notifications
              try {
                await FirebaseMessaging.instance.deleteToken();
              } catch (e) {
                debugPrint('Failed to delete FCM token: $e');
              }

              // Also update the local auth provider status
              ref.read(authProvider.notifier).signOut();

              // c. Wipe stack and navigate back to login screen
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            } catch (e) {
              debugPrint('Error during logout process: $e');
            }
          },
          child: Text(
            'Ya, Keluar',
            style: GoogleFonts.plusJakartaSans(
              color: AppColors.error,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
