// features/farmers/add_farmer_screen.dart

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class AddFarmerScreen extends StatelessWidget {
  const AddFarmerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Add Farmer')),
      body: Center(
        child: Text('Add Farmer form — coming in Phase 4', style: AppTextStyles.body),
      ),
    );
  }
}