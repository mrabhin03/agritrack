// features/plots/add_plot_screen.dart

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class AddPlotScreen extends StatelessWidget {
  const AddPlotScreen({super.key, this.farmerId});

  final String? farmerId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Add Plot')),
      body: Center(
        child: Text('Add Plot map — coming in Phase 6', style: AppTextStyles.body),
      ),
    );
  }
}