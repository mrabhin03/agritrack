// core/widgets/form_field_wrapper.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

// ── Base wrapper: label + field + helper/error ─────────
class FormFieldWrapper extends StatelessWidget {
  const FormFieldWrapper({
    super.key,
    required this.label,
    required this.child,
    this.isRequired = false,
    this.helperText,
    this.errorText,
    this.padding,
  });

  final String label;
  final Widget child;
  final bool isRequired;
  final String? helperText;
  final String? errorText;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Label ──────────────────────────────────
          RichText(
            text: TextSpan(
              text: label,
              style: AppTextStyles.labelLarge,
              children: [
                if (isRequired)
                  const TextSpan(
                    text: ' *',
                    style: TextStyle(color: AppColors.error),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // ── Field ──────────────────────────────────
          child,

          // ── Helper / Error ──────────────────────────
          if (errorText != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 12,
                  color: AppColors.error,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    errorText!,
                    style: AppTextStyles.captionError,
                  ),
                ),
              ],
            ),
          ] else if (helperText != null) ...[
            const SizedBox(height: 4),
            Text(
              helperText!,
              style: AppTextStyles.caption,
            ),
          ],
        ],
      ),
    );
  }
}

// ── Text input field ───────────────────────────────────
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.validator,
    this.onChanged,
    this.onSaved,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.isRequired = false,
    this.helperText,
    this.prefixIcon,
    this.suffixIcon,
    this.enabled = true,
    this.autofocus = false,
    this.inputFormatters,
    this.focusNode,
    this.initialValue,
    this.readOnly = false,
    this.onTap,
  });

  final String label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String?)? onSaved;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final int maxLines;
  final int? minLines;
  final int? maxLength;
  final bool isRequired;
  final String? helperText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool enabled;
  final bool autofocus;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;
  final String? initialValue;
  final bool readOnly;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return FormFieldWrapper(
      label: label,
      isRequired: isRequired,
      helperText: helperText,
      child: TextFormField(
        controller: controller,
        initialValue: initialValue,
        validator: validator,
        onChanged: onChanged,
        onSaved: onSaved,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        obscureText: obscureText,
        maxLines: maxLines,
        minLines: minLines,
        maxLength: maxLength,
        enabled: enabled,
        autofocus: autofocus,
        inputFormatters: inputFormatters,
        focusNode: focusNode,
        readOnly: readOnly,
        onTap: onTap,
        style: AppTextStyles.body,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: prefixIcon != null
              ? Icon(prefixIcon, size: 18, color: AppColors.textSecondary)
              : null,
          suffixIcon: suffixIcon,
          counterText: '',
        ),
      ),
    );
  }
}

// ── Dropdown field ─────────────────────────────────────
class AppDropdownField<T> extends StatelessWidget {
  const AppDropdownField({
    super.key,
    required this.label,
    required this.items,
    required this.value,
    required this.onChanged,
    this.hint,
    this.isRequired = false,
    this.helperText,
    this.validator,
    this.enabled = true,
  });

  final String label;
  final List<T> items;
  final T? value;
  final void Function(T?) onChanged;
  final String? hint;
  final bool isRequired;
  final String? helperText;
  final String? Function(T?)? validator;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return FormFieldWrapper(
      label: label,
      isRequired: isRequired,
      helperText: helperText,
      child: DropdownButtonFormField<T>(
        value: value,
        onChanged: enabled ? onChanged : null,
        validator: validator,
        style: AppTextStyles.body,
        icon: const Icon(
          Icons.keyboard_arrow_down,
          color: AppColors.textSecondary,
        ),
        decoration: InputDecoration(
          hintText: hint ?? 'Select $label',
        ),
        items: items
            .map(
              (item) => DropdownMenuItem<T>(
                value: item,
                child: Text(
                  item.toString(),
                  style: AppTextStyles.body,
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

// ── Date picker field ──────────────────────────────────
class AppDateField extends StatelessWidget {
  const AppDateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.isRequired = false,
    this.helperText,
    this.firstDate,
    this.lastDate,
    this.validator,
  });

  final String label;
  final DateTime? value;
  final void Function(DateTime) onChanged;
  final bool isRequired;
  final String? helperText;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final String? Function(String?)? validator;

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    // DD/MM/YYYY — en-IN format
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return FormFieldWrapper(
      label: label,
      isRequired: isRequired,
      helperText: helperText,
      child: TextFormField(
        readOnly: true,
        controller: TextEditingController(text: _formatDate(value)),
        validator: validator,
        style: AppTextStyles.body,
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: value ?? DateTime.now(),
            firstDate: firstDate ?? DateTime(2020),
            lastDate: lastDate ?? DateTime(2030),
            builder: (context, child) => Theme(
              data: Theme.of(context).copyWith(
                colorScheme: Theme.of(context).colorScheme.copyWith(
                      primary: AppColors.primary,
                    ),
              ),
              child: child!,
            ),
          );
          if (picked != null) onChanged(picked);
        },
        decoration: const InputDecoration(
          hintText: 'DD/MM/YYYY',
          suffixIcon: Icon(
            Icons.calendar_today_outlined,
            size: 18,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ── GPS capture field ──────────────────────────────────
class GpsField extends StatelessWidget {
  const GpsField({
    super.key,
    this.latitude,
    this.longitude,
    required this.onCapture,
    this.isCapturing = false,
  });

  final double? latitude;
  final double? longitude;
  final VoidCallback onCapture;
  final bool isCapturing;

  String get _displayText {
    if (latitude == null || longitude == null) return 'No location captured';
    return '${latitude!.toStringAsFixed(6)}, '
        '${longitude!.toStringAsFixed(6)}';
  }

  @override
  Widget build(BuildContext context) {
    final hasFix = latitude != null && longitude != null;

    return FormFieldWrapper(
      label: 'GPS Location',
      helperText: 'Captures device location',
      child: Row(
        children: [
          // Display box
          Expanded(
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Icon(
                    hasFix
                        ? Icons.location_on
                        : Icons.location_off_outlined,
                    size: 16,
                    color: hasFix
                        ? AppColors.primary
                        : AppColors.textDisabled,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _displayText,
                      style: AppTextStyles.body.copyWith(
                        color: hasFix
                            ? AppColors.textPrimary
                            : AppColors.textDisabled,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Capture button
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: isCapturing ? null : onCapture,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: isCapturing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.textOnPrimary,
                      ),
                    )
                  : const Icon(Icons.my_location, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Photo picker field ─────────────────────────────────
class PhotoPickerField extends StatelessWidget {
  const PhotoPickerField({
    super.key,
    this.imageUrl,
    required this.onPick,
    this.isUploading = false,
  });

  final String? imageUrl;
  final VoidCallback onPick;
  final bool isUploading;

  @override
  Widget build(BuildContext context) {
    return FormFieldWrapper(
      label: 'Farmer Photo',
      helperText: 'Optional — JPEG or PNG',
      child: GestureDetector(
        onTap: isUploading ? null : onPick,
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.border,
              style: BorderStyle.solid,
            ),
          ),
          child: isUploading
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(height: 8),
                      Text('Uploading...'),
                    ],
                  ),
                )
              : imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        imageUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (_, __, ___) => _placeholder(),
                      ),
                    )
                  : _placeholder(),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_a_photo_outlined,
          size: 28,
          color: AppColors.textDisabled,
        ),
        SizedBox(height: 6),
        Text(
          'Tap to add photo',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textDisabled,
          ),
        ),
      ],
    );
  }
}

// ── Number stepper field ───────────────────────────────
class NumberStepperField extends StatelessWidget {
  const NumberStepperField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 999,
    this.step = 1,
    this.suffix,
    this.isRequired = false,
  });

  final String label;
  final double value;
  final void Function(double) onChanged;
  final double min;
  final double max;
  final double step;
  final String? suffix;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    return FormFieldWrapper(
      label: label,
      isRequired: isRequired,
      child: Row(
        children: [
          // Decrement
          _StepButton(
            icon: Icons.remove,
            onTap: value > min
                ? () => onChanged((value - step).clamp(min, max))
                : null,
          ),
          // Value display
          Expanded(
            child: Container(
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.symmetric(
                  horizontal: BorderSide(color: AppColors.border),
                ),
                color: AppColors.surface,
              ),
              child: Text(
                suffix != null
                    ? '${value % 1 == 0 ? value.toInt() : value} $suffix'
                    : '${value % 1 == 0 ? value.toInt() : value}',
                style: AppTextStyles.labelLarge,
              ),
            ),
          ),
          // Increment
          _StepButton(
            icon: Icons.add,
            onTap: value < max
                ? () => onChanged((value + step).clamp(min, max))
                : null,
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: onTap != null
              ? AppColors.surfaceVariant
              : AppColors.surfaceVariant.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(
          icon,
          size: 18,
          color: onTap != null
              ? AppColors.textPrimary
              : AppColors.textDisabled,
        ),
      ),
    );
  }
}