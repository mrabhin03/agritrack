# AgriTrack

**Offline-first farm & carbon monitoring app for field agents — built with Flutter.**

AgriTrack helps field agents and agronomists register farmers, track crop seasons and field events, and calculate greenhouse-gas emissions for turmeric cultivation — all fully usable offline in low-connectivity rural areas, with data syncing to the cloud once a connection is available.


---

## ✨ Features

- **Dashboard** — daily check-in, KPI overview, and quick stats for the field agent's assigned farmers.
- **Farmer registry** — add farmers with contact info, village, land area, GPS location, and growth stage.
- **Plots** — record and manage individual field plots per farmer.
- **Crop seasons & events** — track a season from planting to harvest, logging fertiliser, irrigation, harvest, and monitoring events against IISR variety-specific yield targets and growth-stage timelines.
- **Carbon accounting** — calculate CO₂e emissions per season using IPCC (2006) default emission factors:
  - N₂O from synthetic & organic nitrogen inputs
  - CO₂ from diesel combustion
  - CO₂ from grid electricity use
  - Per-hectare and per-tonne emission intensity, with a configurable "low emissions" threshold
- **Offline-first storage** — all data is cached locally with [Hive](https://pub.dev/packages/hive) so the app is fully functional without a network connection.
- **Cloud sync (planned)** — a [Supabase](https://supabase.com/) backend and background sync queue for multi-device and multi-agent data consistency.

## 🧱 Tech Stack

| Layer | Choice |
|---|---|
| Framework | Flutter |
| State management | [Riverpod](https://riverpod.dev/) |
| Routing | [go_router](https://pub.dev/packages/go_router) |
| Local storage | [Hive](https://pub.dev/packages/hive) / `hive_flutter` |
| Backend (planned) | [Supabase](https://supabase.com/) (Postgres, Auth, Storage, Realtime) |
| Location (planned) | Device GPS via a location service |

## 📂 Project Structure

```
lib/
├── main.dart                 # App entrypoint — Hive init, system UI setup
├── app.dart                  # Root widget, router, bottom-nav shell
├── core/
│   ├── constants/            # Crop config, Supabase table/box names, IPCC factors
│   ├── theme/                # Colors, text styles, ThemeData
│   ├── utils/                # Emission calculations, formatters, validators
│   ├── widgets/               # Shared UI components (cards, badges, empty states)
│   └── fake/                 # Sample/seed data for local development
├── services/
│   ├── hive_service.dart     # Adapter registration, box setup, data seeding
│   ├── supabase_service.dart # Backend integration (stub — not yet implemented)
│   ├── sync_service.dart     # Offline → online sync queue (stub — not yet implemented)
│   └── location_service.dart # GPS capture (stub — not yet implemented)
└── features/
    ├── dashboard/            # Home screen, KPIs, check-in
    ├── farmers/               # Farmer list, detail, add/edit
    ├── plots/                 # Plot list, add/edit
    ├── crops/                 # Seasons, season detail, crop events
    ├── carbon/                 # Emission records, add emission
    └── auth/                   # Login / OTP (stub — not yet implemented)
```

Each feature module follows the same internal layout: `models/` (Hive-backed data models with generated adapters), `providers/` (Riverpod state), `repositories/` (data access), and the screens themselves.

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable channel)
- A configured Android/iOS emulator or physical device

### Setup

1. Clone the repo:
   ```bash
   git clone https://github.com/mrabhin03/agritrack.git
   cd agritrack
   ```
2. Add a `pubspec.yaml` declaring the following dependencies (add versions as appropriate):
   ```yaml
   dependencies:
     flutter:
       sdk: flutter
     flutter_riverpod: ^2.0.0
     go_router: ^13.0.0
     hive: ^2.0.0
     hive_flutter: ^1.1.0
     intl: ^0.19.0

   dev_dependencies:
     hive_generator: ^2.0.0
     build_runner: ^2.0.0
   ```
3. Install dependencies:
   ```bash
   flutter pub get
   ```
4. Run the code generator for Hive model adapters (`.g.dart` files are already checked in, but re-run if you change a model):
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```
5. Run the app:
   ```bash
   flutter run
   ```



## 🧮 Emission Methodology

Carbon calculations follow IPCC (2006) Tier 1 default emission factors:

- **N₂O from synthetic N**: 1.25% of applied nitrogen, converted to N₂O and scaled by GWP₁₀₀ = 298
- **N₂O from organic N**: 0.8% emission factor
- **Diesel combustion**: 2.68 kg CO₂e/litre
- **Grid electricity**: 0.82 kg CO₂e/kWh (India grid average)

A season is flagged **"Low emissions"** if it falls under 500 kg CO₂e per hectare (configurable in `crop_constants.dart`).
