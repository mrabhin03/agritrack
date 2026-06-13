// core/widgets/empty_state.dart

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.illustration,
    this.actionLabel,
    this.onAction,
    this.compact = false,
  });

  // ── Preset constructors ───────────────────────────

  /// No farmers found
  const EmptyState.noFarmers({
    super.key,
    this.onAction,
    this.compact = false,
  })  : title = 'No farmers yet',
        subtitle = 'Add your first farmer to get started',
        icon = Icons.people_outline,
        illustration = null,
        actionLabel = 'Add Farmer';

  /// No search results
  const EmptyState.noResults({
    super.key,
    this.compact = false,
  })  : title = 'No results found',
        subtitle = 'Try a different name, phone, or village',
        icon = Icons.search_off_outlined,
        illustration = null,
        actionLabel = null,
        onAction = null;

  /// No plots mapped
  const EmptyState.noPlots({
    super.key,
    this.onAction,
    this.compact = false,
  })  : title = 'No plots mapped',
        subtitle = 'Draw your first plot boundary on the map',
        icon = Icons.map_outlined,
        illustration = null,
        actionLabel = 'Add Plot';

  /// No seasons recorded
  const EmptyState.noSeasons({
    super.key,
    this.onAction,
    this.compact = false,
  })  : title = 'No crop seasons',
        subtitle = 'Start a new turmeric season for this farmer',
        icon = Icons.grass_outlined,
        illustration = null,
        actionLabel = 'Add Season';

  /// No emission records
  const EmptyState.noEmissions({
    super.key,
    this.onAction,
    this.compact = false,
  })  : title = 'No emissions logged',
        subtitle = 'Log fertiliser or fuel usage to calculate footprint',
        icon = Icons.eco_outlined,
        illustration = null,
        actionLabel = 'Log Emission';

  /// Offline — no cached data
  const EmptyState.offline({
    super.key,
    this.compact = false,
  })  : title = 'You are offline',
        subtitle = 'Cached data unavailable. Connect to load records.',
        icon = Icons.wifi_off_outlined,
        illustration = null,
        actionLabel = null,
        onAction = null;

  /// Generic error state
  const EmptyState.error({
    super.key,
    this.onAction,
    this.compact = false,
  })  : title = 'Something went wrong',
        subtitle = 'Could not load data. Tap to retry.',
        icon = Icons.error_outline,
        illustration = null,
        actionLabel = 'Retry';

  // ── Fields ────────────────────────────────────────
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? illustration;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final iconSize  = compact ? 48.0 : 72.0;
    final vPadding  = compact ? 24.0 : 48.0;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 32,
          vertical: vPadding,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Illustration or icon ─────────────────
            if (illustration != null)
              illustration!
            else if (icon != null)
              _buildIconCircle(iconSize),

            SizedBox(height: compact ? 16 : 24),

            // ── Title ────────────────────────────────
            Text(
              title,
              style: compact ? AppTextStyles.h3 : AppTextStyles.h2,
              textAlign: TextAlign.center,
            ),

            // ── Subtitle ─────────────────────────────
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],

            // ── Action button ─────────────────────────
            if (actionLabel != null && onAction != null) ...[
              SizedBox(height: compact ? 16 : 24),
              SizedBox(
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: onAction,
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(actionLabel!),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 0,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIconCircle(double iconSize) {
    return Container(
      width: iconSize,
      height: iconSize,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: iconSize * 0.5,
        color: AppColors.textDisabled,
      ),
    );
  }
}

// ── Inline empty (used inside cards, not full screen) ──
class InlineEmpty extends StatelessWidget {
  const InlineEmpty({
    super.key,
    required this.message,
    this.icon,
  });

  final String message;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: AppColors.textDisabled),
            const SizedBox(width: 8),
          ],
          Text(
            message,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textDisabled,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Error retry widget ─────────────────────────────────
class ErrorRetry extends StatelessWidget {
  const ErrorRetry({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}