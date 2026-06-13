// features/carbon/add_emission_screen.dart

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class AddEmissionScreen extends StatelessWidget {
  const AddEmissionScreen({super.key, this.seasonId});

  final String? seasonId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Log Emission')),
      body: Center(
        child: Text('Add Emission form — coming in Phase 7', style: AppTextStyles.body),
      ),
    );
  }
}