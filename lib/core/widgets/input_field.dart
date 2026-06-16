import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class InputField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final bool isPassword;
  final IconData? prefixIcon;
  final String? Function(String?)? validator;
  final bool enabled;
  final VoidCallback? onTap;
  final bool readOnly;

  const InputField({
    super.key,
    required this.label,
    this.hint,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.isPassword = false,
    this.prefixIcon,
    this.validator,
    this.enabled = true,
    this.onTap,
    this.readOnly = false,
  });

  @override
  State<InputField> createState() => _InputFieldState();
}

class _InputFieldState extends State<InputField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(
        color: Colors.transparent, // Minimalist: no border unless focused
        width: 0,
      ),
    );

    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(
        color: AppColors.primary.withOpacity(0.3), // Soft primary outline on focus
        width: 1.5,
      ),
    );

    final errorBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(
        color: AppColors.error,
        width: 1,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
            letterSpacing: 0.1,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: widget.controller,
          keyboardType: widget.keyboardType,
          obscureText: widget.isPassword && _obscureText,
          validator: widget.validator,
          enabled: widget.enabled,
          onTap: widget.onTap,
          readOnly: widget.readOnly,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.textDarkSecondary.withOpacity(0.5) : AppColors.textLightSecondary.withOpacity(0.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            filled: true,
            fillColor: isDark ? AppColors.inputBgDark : AppColors.inputBgLight,
            enabledBorder: border,
            focusedBorder: focusedBorder,
            errorBorder: errorBorder,
            focusedErrorBorder: focusedBorder.copyWith(borderSide: const BorderSide(color: AppColors.error, width: 1.5)),
            prefixIcon: widget.prefixIcon != null
                ? Icon(
                    widget.prefixIcon,
                    color: isDark ? AppColors.textDarkSecondary.withOpacity(0.6) : AppColors.textLightSecondary.withOpacity(0.6),
                    size: 18,
                  )
                : null,
            suffixIcon: widget.isPassword
                ? IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: isDark ? AppColors.textDarkSecondary.withOpacity(0.6) : AppColors.textLightSecondary.withOpacity(0.6),
                      size: 18,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
