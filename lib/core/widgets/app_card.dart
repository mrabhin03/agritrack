// core/widgets/app_card.dart

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.color,
    this.borderColor,
    this.borderRadius,
    this.elevation,
    this.width,
    this.height,
  });

  final Widget? child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;
  final double? borderRadius;
  final double? elevation;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? 12.0;

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? AppColors.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: borderColor ?? AppColors.border,
          width: 1,
        ),
        boxShadow: elevation != null && elevation! > 0
            ? [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: elevation! * 2,
                  offset: Offset(0, elevation!),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: onTap != null
            ? Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  splashColor: AppColors.primary.withOpacity(0.08),
                  highlightColor: AppColors.primary.withOpacity(0.04),
                  child: Padding(
                    padding: padding ?? const EdgeInsets.all(16),
                    child: child,
                  ),
                ),
              )
            : Padding(
                padding: padding ?? const EdgeInsets.all(16),
                child: child,
              ),
      ),
    );
  }
}

// ── Variants ──────────────────────────────────────────

/// Card with colored left border accent (used in event logs)
class AppAccentCard extends StatelessWidget {
  const AppAccentCard({
    super.key,
    required this.child,
    required this.accentColor,
    this.padding,
    this.margin,
    this.onTap,
  });

  final Widget child;
  final Color accentColor;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Left accent bar
              Container(
                width: 4,
                color: accentColor,
              ),
              // Content
              Expanded(
                child: onTap != null
                    ? Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: onTap,
                          child: Padding(
                            padding: padding ??
                                const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                            child: child,
                          ),
                        ),
                      )
                    : Padding(
                        padding: padding ??
                            const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                        child: child,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Flat surface card — no border, subtle bg (used inside sections)
class AppFlatCard extends StatelessWidget {
  const AppFlatCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: onTap != null
            ? Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  child: Padding(
                    padding: padding ?? const EdgeInsets.all(12),
                    child: child,
                  ),
                ),
              )
            : Padding(
                padding: padding ?? const EdgeInsets.all(12),
                child: child,
              ),
      ),
    );
  }
}