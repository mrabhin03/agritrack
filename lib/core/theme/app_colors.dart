// core/theme/app_colors.dart

import 'package:flutter/material.dart';

class AppColors {
  AppColors._(); // prevent instantiation

  // ── Brand ──────────────────────────────────────────
  static const Color primary        = Color(0xFF2D6A4F); // dark green
  static const Color primaryDark    = Color(0xFF1A3A2A); // sidebar
  static const Color accent         = Color(0xFF40916C); // secondary green
  static const Color accentLight    = Color(0xFF74C69D); // hover/highlight

  // ── Background ─────────────────────────────────────
  static const Color background     = Color(0xFFF5F7F5); // scaffold bg
  static const Color surface        = Color(0xFFFFFFFF); // card bg
  static const Color surfaceVariant = Color(0xFFEEF2EE); // subtle bg

  // ── Status ─────────────────────────────────────────
  static const Color success        = Color(0xFF2D6A4F);
  static const Color successBg      = Color(0xFFD8F3DC); // green pill bg
  static const Color warning        = Color(0xFFF57F17);
  static const Color warningBg      = Color(0xFFFFF9C4);
  static const Color error          = Color(0xFFB00020);
  static const Color errorBg        = Color(0xFFFFEDED);
  static const Color info           = Color(0xFF1565C0);
  static const Color infoBg         = Color(0xFFE3F2FD);

  // ── Crop Stage Colors ───────────────────────────────
  static const Color stageNursery   = Color(0xFFE65100);  // deep orange
  static const Color stagePlanting  = Color(0xFF2E7D32);  // dark green
  static const Color stageGrowth    = Color(0xFF1565C0);  // blue
  static const Color stageFlowering = Color(0xFF6A1B9A);  // purple
  static const Color stageHarvest   = Color(0xFFF57F17);  // amber

  static const Color stageNurseryBg   = Color(0xFFFFF3E0);
  static const Color stagePlantingBg  = Color(0xFFE8F5E9);
  static const Color stageGrowthBg    = Color(0xFFE3F2FD);
  static const Color stageFloweringBg = Color(0xFFF3E5F5);
  static const Color stageHarvestBg   = Color(0xFFFFF9C4);

  // ── Carbon Chart Colors ─────────────────────────────
  static const Color chartN2O       = Color(0xFF40916C); // green
  static const Color chartDiesel    = Color(0xFFF4A261); // orange
  static const Color chartGrid      = Color(0xFF2196F3); // blue

  // ── Text ───────────────────────────────────────────
  static const Color textPrimary    = Color(0xFF1A1A1A);
  static const Color textSecondary  = Color(0xFF6B6B6B);
  static const Color textDisabled   = Color(0xFFAAAAAA);
  static const Color textOnPrimary  = Color(0xFFFFFFFF);
  static const Color textOnBadge    = Color(0xFF1A3A2A);

  // ── Border / Divider ───────────────────────────────
  static const Color border         = Color(0xFFDDE3DD);
  static const Color divider        = Color(0xFFEEF2EE);

  // ── Shadow ─────────────────────────────────────────
  static const Color shadow         = Color(0x1A000000); // 10% black

  // ── Nav ────────────────────────────────────────────
  static const Color navSelected    = Color(0xFF2D6A4F);
  static const Color navUnselected  = Color(0xFF6B6B6B);
  static const Color navBackground  = Color(0xFFFFFFFF);

  // ── Helpers ────────────────────────────────────────

  /// Returns stage foreground color by stage name
  static Color stageColor(String stage) {
    switch (stage) {
      case 'Nursery':   return stageNursery;
      case 'Planting':  return stagePlanting;
      case 'Growth':    return stageGrowth;
      case 'Flowering': return stageFlowering;
      case 'Harvest':   return stageHarvest;
      default:          return accent;
    }
  }

  /// Returns stage background color by stage name
  static Color stageBgColor(String stage) {
    switch (stage) {
      case 'Nursery':   return stageNurseryBg;
      case 'Planting':  return stagePlantingBg;
      case 'Growth':    return stageGrowthBg;
      case 'Flowering': return stageFloweringBg;
      case 'Harvest':   return stageHarvestBg;
      default:          return successBg;
    }
  }
}