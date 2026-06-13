// features/plots/plots_screen.dart

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class PlotsScreen extends StatelessWidget {
  const PlotsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Text('Plots & Coverage — coming in Phase 6', style: AppTextStyles.body),
      ),
    );
  }
}