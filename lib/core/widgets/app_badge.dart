// core/widgets/app_badge.dart

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

// ── Badge Variant Enum ─────────────────────────────────
enum BadgeVariant { success, warning, error, info, neutral, stage }

class AppBadge extends StatelessWidget {
  const AppBadge({
    super.key,
    required this.label,
    this.variant = BadgeVariant.success,
    this.icon,
    this.compact = false,
  });

  /// For stage badges — auto picks color from stage name
  const AppBadge.stage({
    super.key,
    required String stage,
    this.compact = false,
  })  : label = stage,
        variant = BadgeVariant.stage,
        icon = null;

  final String label;
  final BadgeVariant variant;
  final IconData? icon;

  /// compact = smaller padding, used in tight lists
  final bool compact;

  // ── Color resolution ──────────────────────────────
  Color _bgColor() {
    if (variant == BadgeVariant.stage) {
      return AppColors.stageBgColor(label);
    }
    switch (variant) {
      case BadgeVariant.success: return AppColors.successBg;
      case BadgeVariant.warning: return AppColors.warningBg;
      case BadgeVariant.error:   return AppColors.errorBg;
      case BadgeVariant.info:    return AppColors.infoBg;
      case BadgeVariant.neutral: return AppColors.surfaceVariant;
      default:                   return AppColors.successBg;
    }
  }

  Color _fgColor() {
    if (variant == BadgeVariant.stage) {
      return AppColors.stageColor(label);
    }
    switch (variant) {
      case BadgeVariant.success: return AppColors.success;
      case BadgeVariant.warning: return AppColors.warning;
      case BadgeVariant.error:   return AppColors.error;
      case BadgeVariant.info:    return AppColors.info;
      case BadgeVariant.neutral: return AppColors.textSecondary;
      default:                   return AppColors.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = _bgColor();
    final fg = _fgColor();
    final vPad = compact ? 3.0 : 5.0;
    final hPad = compact ? 8.0 : 12.0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: compact ? 10 : 12, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppTextStyles.badge.copyWith(color: fg),
          ),
        ],
      ),
    );
  }
}

// ── Status Badge (with dot indicator) ─────────────────
class AppStatusBadge extends StatelessWidget {
  const AppStatusBadge({
    super.key,
    required this.label,
    required this.variant,
    this.compact = false,
  });

  final String label;
  final BadgeVariant variant;
  final bool compact;

  Color _dotColor() {
    switch (variant) {
      case BadgeVariant.success: return AppColors.success;
      case BadgeVariant.warning: return AppColors.warning;
      case BadgeVariant.error:   return AppColors.error;
      case BadgeVariant.info:    return AppColors.info;
      default:                   return AppColors.textSecondary;
    }
  }

  Color _bgColor() {
    switch (variant) {
      case BadgeVariant.success: return AppColors.successBg;
      case BadgeVariant.warning: return AppColors.warningBg;
      case BadgeVariant.error:   return AppColors.errorBg;
      case BadgeVariant.info:    return AppColors.infoBg;
      default:                   return AppColors.surfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dotSize = compact ? 6.0 : 7.0;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: _bgColor(),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: dotSize,
            height: dotSize,
            decoration: BoxDecoration(
              color: _dotColor(),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTextStyles.badge.copyWith(color: _dotColor()),
          ),
        ],
      ),
    );
  }
}

// ── Count Badge (notification style) ──────────────────
class AppCountBadge extends StatelessWidget {
  const AppCountBadge({
    super.key,
    required this.count,
    this.max = 99,
  });

  final int count;
  final int max;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();

    final label = count > max ? '$max+' : '$count';

    return Container(
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.error,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: AppTextStyles.badge.copyWith(
          color: AppColors.textOnPrimary,
          fontSize: 10,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// ── Emission Badge ─────────────────────────────────────
class EmissionBadge extends StatelessWidget {
  const EmissionBadge({
    super.key,
    required this.isLow,
  });

  final bool isLow;

  @override
  Widget build(BuildContext context) {
    return AppBadge(
      label: isLow ? 'Low Emissions' : 'High Emissions',
      variant: isLow ? BadgeVariant.success : BadgeVariant.error,
      icon: isLow ? Icons.eco_outlined : Icons.warning_amber_outlined,
    );
  }
}

// ── Season Status Badge ────────────────────────────────
class SeasonStatusBadge extends StatelessWidget {
  const SeasonStatusBadge({
    super.key,
    required this.status,
  });

  final String status; // 'On track' | 'Delayed' | 'Complete'

  BadgeVariant get _variant {
    switch (status) {
      case 'On track':  return BadgeVariant.success;
      case 'Delayed':   return BadgeVariant.warning;
      case 'Complete':  return BadgeVariant.info;
      default:          return BadgeVariant.neutral;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppStatusBadge(label: status, variant: _variant);
  }
}