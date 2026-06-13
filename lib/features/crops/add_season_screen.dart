// features/crops/add_season_screen.dart

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class AddSeasonScreen extends StatelessWidget {
  const AddSeasonScreen({super.key, this.farmerId});

  final String? farmerId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Add Season')),
      body: Center(
        child: Text('Add Season form — coming in Phase 5', style: AppTextStyles.body),
      ),
    );
  }
}