// features/farmers/farmer_detail_screen.dart

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class FarmerDetailScreen extends StatelessWidget {
  const FarmerDetailScreen({super.key, required this.farmerId});

  final String farmerId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Farmer Detail')),
      body: Center(
        child: Text('Farmer $farmerId — coming in Phase 3', style: AppTextStyles.body),
      ),
    );
  }
}