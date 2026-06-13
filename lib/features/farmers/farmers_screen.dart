// features/farmers/farmers_screen.dart

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class FarmersScreen extends StatelessWidget {
  const FarmersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Text('Farmers — coming in Phase 3', style: AppTextStyles.body),
      ),
    );
  }
}