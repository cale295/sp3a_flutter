import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Accessible text input field following the Inclusive Modern Design system.
/// Uses a floating label above the field with explicit hint text.
/// Font size is minimum 14pt for readability by senior users.
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
  final int? maxLines;

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
    this.maxLines = 1,
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

    final fillColor = isDark ? AppColors.inputBgDark : AppColors.inputBgLight;
    final hintColor = isDark
        ? AppColors.textDarkSecondary.withAlpha(140)
        : AppColors.textLightSecondary.withAlpha(140);
    final iconColor = isDark
        ? AppColors.textDarkSecondary.withAlpha(160)
        : AppColors.textLightSecondary.withAlpha(160);

    final baseBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    );
    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(
        color: isDark ? AppColors.primaryLight : AppColors.primary,
        width: 1.5,
      ),
    );
    final errorBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.error, width: 1.2),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Explicit floating label — always visible above the field
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
            letterSpacing: 0.1,
          ),
        ),
        const SizedBox(height: 7),
        TextFormField(
          controller: widget.controller,
          keyboardType: widget.keyboardType,
          obscureText: widget.isPassword && _obscureText,
          validator: widget.validator,
          enabled: widget.enabled,
          onTap: widget.onTap,
          readOnly: widget.readOnly,
          maxLines: widget.isPassword ? 1 : widget.maxLines,
          style: TextStyle(
            fontSize: 15, // Minimum readable font size for seniors
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: hintColor,
            ),
            // Generous vertical padding for easy-to-tap touch area
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            filled: true,
            fillColor: fillColor,
            enabledBorder: baseBorder,
            focusedBorder: focusedBorder,
            errorBorder: errorBorder,
            focusedErrorBorder: errorBorder.copyWith(
              borderSide: const BorderSide(color: AppColors.error, width: 1.5),
            ),
            disabledBorder: baseBorder,
            prefixIcon: widget.prefixIcon != null
                ? Padding(
                    padding: const EdgeInsets.only(left: 14, right: 4),
                    child: Icon(
                      widget.prefixIcon,
                      color: iconColor,
                      size: 20,
                    ),
                  )
                : null,
            prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
            suffixIcon: widget.isPassword
                ? IconButton(
                    icon: Icon(
                      _obscureText
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: iconColor,
                      size: 20,
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
