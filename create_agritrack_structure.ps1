# Create folders
$folders = @(
"lib/core/theme",
"lib/core/constants",
"lib/core/utils",
"lib/core/widgets",

"lib/features/dashboard/providers",

"lib/features/farmers/models",
"lib/features/farmers/providers",
"lib/features/farmers/repositories",

"lib/features/crops/models",
"lib/features/crops/providers",
"lib/features/crops/repositories",

"lib/features/plots/models",
"lib/features/plots/providers",
"lib/features/plots/repositories",

"lib/features/carbon/models",
"lib/features/carbon/providers",
"lib/features/carbon/repositories",

"lib/features/auth/providers",

"lib/services",
"lib/models",
"lib/hive_adapters"
)

foreach ($folder in $folders) {
    New-Item -ItemType Directory -Force -Path $folder | Out-Null
}

# Create files
$files = @(
"lib/main.dart",
"lib/app.dart",

"lib/core/theme/app_theme.dart",
"lib/core/theme/app_colors.dart",
"lib/core/theme/app_text_styles.dart",

"lib/core/constants/crop_constants.dart",
"lib/core/constants/supabase_constants.dart",

"lib/core/utils/validators.dart",
"lib/core/utils/formatters.dart",
"lib/core/utils/emission_calc.dart",

"lib/core/widgets/app_card.dart",
"lib/core/widgets/app_badge.dart",
"lib/core/widgets/stat_card.dart",
"lib/core/widgets/empty_state.dart",
"lib/core/widgets/loading_overlay.dart",
"lib/core/widgets/form_field_wrapper.dart",
"lib/core/widgets/section_header.dart",

"lib/features/dashboard/dashboard_screen.dart",
"lib/features/dashboard/providers/dashboard_provider.dart",

"lib/features/farmers/farmers_screen.dart",
"lib/features/farmers/farmer_detail_screen.dart",
"lib/features/farmers/add_farmer_screen.dart",
"lib/features/farmers/models/farmer_model.dart",
"lib/features/farmers/providers/farmers_provider.dart",
"lib/features/farmers/repositories/farmers_repository.dart",

"lib/features/crops/crops_screen.dart",
"lib/features/crops/season_detail_screen.dart",
"lib/features/crops/add_season_screen.dart",
"lib/features/crops/add_event_screen.dart",
"lib/features/crops/models/season_model.dart",
"lib/features/crops/models/crop_event_model.dart",
"lib/features/crops/providers/crops_provider.dart",
"lib/features/crops/repositories/crops_repository.dart",

"lib/features/plots/plots_screen.dart",
"lib/features/plots/add_plot_screen.dart",
"lib/features/plots/models/plot_model.dart",
"lib/features/plots/providers/plots_provider.dart",
"lib/features/plots/repositories/plots_repository.dart",

"lib/features/carbon/carbon_screen.dart",
"lib/features/carbon/add_emission_screen.dart",
"lib/features/carbon/models/emission_model.dart",
"lib/features/carbon/providers/carbon_provider.dart",
"lib/features/carbon/repositories/carbon_repository.dart",

"lib/features/auth/login_screen.dart",
"lib/features/auth/otp_screen.dart",
"lib/features/auth/providers/auth_provider.dart",

"lib/services/supabase_service.dart",
"lib/services/hive_service.dart",
"lib/services/sync_service.dart",
"lib/services/location_service.dart"
)

foreach ($file in $files) {
    New-Item -ItemType File -Force -Path $file | Out-Null
}

Write-Host "AgriTrack folder structure created successfully!"