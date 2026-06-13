// features/crops/add_event_screen.dart

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class AddEventScreen extends StatelessWidget {
  const AddEventScreen({super.key, required this.seasonId});

  final String seasonId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Log Event')),
      body: Center(
        child: Text('Add Event form — coming in Phase 5', style: AppTextStyles.body),
      ),
    );
  }
}