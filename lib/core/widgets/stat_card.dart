// core/widgets/stat_card.dart

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'app_badge.dart';

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.subtitle,
    this.badge,
    this.badgeVariant,
    this.iconColor,
    this.iconBgColor,
    this.onTap,
    this.isLoading = false,
  });

  /// Label text below value e.g. "Active farmers"
  final String label;

  /// Main metric value e.g. "128" or "356.8 acres"
  final String value;

  /// Icon shown in top-left circle
  final IconData icon;

  /// Optional subtitle below label e.g. "Low Emissions"
  final String? subtitle;

  /// Optional badge text e.g. "Low Emissions"
  final String? badge;

  /// Badge color variant
  final BadgeVariant? badgeVariant;

  /// Icon foreground color (defaults to primary)
  final Color? iconColor;

  /// Icon background color (defaults to successBg)
  final Color? iconBgColor;

  /// Tap callback — navigates to detail screen
  final VoidCallback? onTap;

  /// Shows shimmer skeleton when true
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) return _buildSkeleton();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Icon + optional badge row ────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildIconCircle(),
                const Spacer(),
                if (badge != null)
                  AppBadge(
                    label: badge!,
                    variant: badgeVariant ?? BadgeVariant.success,
                    compact: true,
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Value ────────────────────────────────
            Text(
              value,
              style: AppTextStyles.metric,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 2),

            // ── Label ────────────────────────────────
            Text(
              label,
              style: AppTextStyles.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            // ── Subtitle ─────────────────────────────
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: AppTextStyles.caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIconCircle() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: iconBgColor ?? AppColors.successBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        icon,
        size: 20,
        color: iconColor ?? AppColors.primary,
      ),
    );
  }

  // ── Skeleton loader ───────────────────────────────
  Widget _buildSkeleton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _SkeletonBox(width: 40, height: 40, radius: 10),
              const Spacer(),
              _SkeletonBox(width: 70, height: 20, radius: 99),
            ],
          ),
          const SizedBox(height: 12),
          _SkeletonBox(width: 80, height: 24, radius: 6),
          const SizedBox(height: 6),
          _SkeletonBox(width: 110, height: 14, radius: 4),
        ],
      ),
    );
  }
}

// ── Skeleton box helper ────────────────────────────────
class _SkeletonBox extends StatefulWidget {
  const _SkeletonBox({
    required this.width,
    required this.height,
    required this.radius,
  });

  final double width;
  final double height;
  final double radius;

  @override
  State<_SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<_SkeletonBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}

// ── Horizontal StatCard (used in tight spaces) ─────────
class StatCardHorizontal extends StatelessWidget {
  const StatCardHorizontal({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.iconColor,
    this.iconBgColor,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? iconColor;
  final Color? iconBgColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBgColor ?? AppColors.successBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 18,
                color: iconColor ?? AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: AppTextStyles.labelLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    label,
                    style: AppTextStyles.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 18,
              color: AppColors.textDisabled,
            ),
          ],
        ),
      ),
    );
  }
}