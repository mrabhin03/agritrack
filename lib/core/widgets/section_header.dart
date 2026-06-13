// core/widgets/section_header.dart

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

// ── Standard section header ────────────────────────────
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.subtitle,
    this.padding,
    this.icon,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? subtitle;
  final EdgeInsetsGeometry? padding;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ??
          const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Icon ───────────────────────────────
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 16,
                  color: AppColors.accent,
                ),
                const SizedBox(width: 6),
              ],

              // ── Title ──────────────────────────────
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: AppTextStyles.sectionTitle,
                ),
              ),

              // ── Action link ────────────────────────
              if (actionLabel != null && onAction != null)
                GestureDetector(
                  onTap: onAction,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          actionLabel!,
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 10,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          // ── Subtitle ─────────────────────────────
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: AppTextStyles.caption,
            ),
          ],
        ],
      ),
    );
  }
}

// ── Section header with count badge ───────────────────
class SectionHeaderWithCount extends StatelessWidget {
  const SectionHeaderWithCount({
    super.key,
    required this.title,
    required this.count,
    this.actionLabel,
    this.onAction,
    this.padding,
    this.icon,
  });

  final String title;
  final int count;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry? padding;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Icon ─────────────────────────────────
          if (icon != null) ...[
            Icon(icon, size: 16, color: AppColors.accent),
            const SizedBox(width: 6),
          ],

          // ── Title ────────────────────────────────
          Text(
            title.toUpperCase(),
            style: AppTextStyles.sectionTitle,
          ),

          const SizedBox(width: 8),

          // ── Count pill ───────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              '$count',
              style: AppTextStyles.badge.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),

          const Spacer(),

          // ── Action ───────────────────────────────
          if (actionLabel != null && onAction != null)
            GestureDetector(
              onTap: onAction,
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      actionLabel!,
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 10,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Divider section header ─────────────────────────────
class DividerSectionHeader extends StatelessWidget {
  const DividerSectionHeader({
    super.key,
    required this.title,
    this.padding,
  });

  final String title;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Row(
        children: [
          // Left divider
          const Expanded(child: Divider(endIndent: 12)),
          Text(
            title.toUpperCase(),
            style: AppTextStyles.sectionTitle,
          ),
          // Right divider
          const Expanded(child: Divider(indent: 12)),
        ],
      ),
    );
  }
}

// ── Page header (top of screen) ───────────────────────
class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.padding,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ??
          const EdgeInsets.fromLTRB(16, 16, 16, 12),
      color: AppColors.surface,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Titles ───────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.h1),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── Trailing widget ───────────────────────
          if (trailing != null) ...[
            const SizedBox(width: 12),
            trailing!,
          ],
        ],
      ),
    );
  }
}

// ── Info row (label + value pair) ─────────────────────
// Used in detail sheets
class InfoRow extends StatelessWidget {
  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.valueColor,
    this.padding,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color? valueColor;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ??
          const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Icon ─────────────────────────────────
          if (icon != null) ...[
            Icon(icon, size: 16, color: AppColors.accent),
            const SizedBox(width: 8),
          ],

          // ── Label ────────────────────────────────
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: AppTextStyles.label,
            ),
          ),

          // ── Value ────────────────────────────────
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.body.copyWith(
                color: valueColor ?? AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Offline banner ────────────────────────────────────
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({
    super.key,
    this.pendingCount = 0,
  });

  final int pendingCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      color: AppColors.warningBg,
      child: Row(
        children: [
          const Icon(
            Icons.wifi_off,
            size: 16,
            color: AppColors.warning,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              pendingCount > 0
                  ? 'Offline — $pendingCount record(s) pending sync'
                  : 'You are offline — data saved locally',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.warning,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}