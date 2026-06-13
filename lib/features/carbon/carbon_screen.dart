// features/carbon/carbon_screen.dart

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class CarbonScreen extends StatelessWidget {
  const CarbonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Text('Carbon Footprint — coming in Phase 7', style: AppTextStyles.body),
      ),
    );
  }
}