// core/constants/supabase_constants.dart

class SupabaseConstants {
  SupabaseConstants._();

  // ── Credentials (replace with your real values) ────
  // Get these from: Supabase Dashboard → Settings → API
  static const String supabaseUrl    = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';

  // ── Table Names ────────────────────────────────────
  static const String tableProfiles        = 'profiles';
  static const String tableFarmers         = 'farmers';
  static const String tablePlots           = 'plots';
  static const String tableSeasons         = 'seasons';
  static const String tableCropEvents      = 'crop_events';
  static const String tableEmissionRecords = 'emission_records';

  // ── View Names ─────────────────────────────────────
  static const String viewDashboardKpis   = 'dashboard_kpis';

  // ── Storage Buckets ────────────────────────────────
  static const String bucketFarmerPhotos  = 'farmer-photos';

  // ── Storage Paths ──────────────────────────────────
  static String farmerPhotoPath(String farmerId) =>
      'public/$farmerId/profile.jpg';

  // ── Realtime channels ──────────────────────────────
  static const String channelFarmers      = 'farmers-changes';
  static const String channelSeasons      = 'seasons-changes';

  // ── Query defaults ─────────────────────────────────
  static const int defaultPageSize        = 50;
  static const int searchDebounceMs       = 300;

  // ── Hive box names ─────────────────────────────────
  static const String hiveBoxFarmers      = 'farmers_cache';
  static const String hiveBoxPlots        = 'plots_cache';
  static const String hiveBoxSeasons      = 'seasons_cache';
  static const String hiveBoxCropEvents = 'crop_events_cache';
  static const String hiveBoxEmissions    = 'emissions_cache';
  static const String hiveBoxPendingOps   = 'pending_ops';
  static const String hiveBoxSettings     = 'app_settings';

  // ── Hive TypeAdapter IDs ───────────────────────────
  // Reserve these IDs — never reuse a deleted ID
  static const int hiveAdapterFarmer      = 0;
  static const int hiveAdapterPlot        = 1;
  static const int hiveAdapterSeason      = 2;
  static const int hiveAdapterCropEvent   = 3;
  static const int hiveAdapterEmission    = 4;
  static const int hiveAdapterPendingOp   = 5;

  // ── Pending op types (sync queue) ──────────────────
  static const String opInsertFarmer      = 'insert_farmer';
  static const String opUpdateFarmer      = 'update_farmer';
  static const String opDeleteFarmer      = 'delete_farmer';
  static const String opInsertPlot        = 'insert_plot';
  static const String opInsertSeason      = 'insert_season';
  static const String opInsertEvent       = 'insert_event';
  static const String opInsertEmission    = 'insert_emission';

  // ── User roles ─────────────────────────────────────
  static const String roleFieldAgent      = 'field_agent';
  static const String roleAgronomist      = 'agronomist';
  static const String roleAdmin           = 'admin';

  // ── App settings keys (Hive settings box) ──────────
  static const String settingUserId       = 'user_id';
  static const String settingUserRole     = 'user_role';
  static const String settingUserName     = 'user_name';
  static const String settingLastSync     = 'last_sync_at';
  static const String settingCheckedIn    = 'is_checked_in';
  static const String settingCheckInTime  = 'check_in_time';
}