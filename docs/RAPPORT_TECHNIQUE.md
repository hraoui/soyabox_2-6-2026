# Rapport Technique - `caisse_1`

Date: 2026-02-23

## 1) Workflow applicatif

### Demarrage
- Initialisation DI via `DependencyInjection.init()` (`lib/helper/dependencies.dart`).
- Initialisation services: session auth, settings, queue sync, pull API, notifications.
- Controllers GetX enregistres (auth, users, restaurants, settings, categories, products, POS, sync).

### Authentification
- Login classique: `POST /api/login` (telephone + mot de passe).
- Login POS PIN: `POST /api/login-pin`.
- Le token est propage a:
  - `ApiClient`
  - `SyncQueueService`
  - `ApiOrderPullService`
  - session locale (`AuthSessionService`)

### Donnees et persistence
- Base locale: Isar (`User`, `Product`, `Category`, `PosOrder`, `PosOrderItem`, `PosTable`).
- Fonctionnement offline-first: creation/modification locale puis sync asynchrone.

### Synchronisation
- Upload sortant: `SyncQueueService` (`/api/sync/{entity}/{upsert|delete}`).
- Download entrant commandes API/web: `ApiOrderPullService` (`/api/orders`, `/api/sync/orders`).
- Strategie anti-surcharge implementee:
  - cadence auto-sync: 15s (`SyncController`)
  - flush periodique queue: 30s (`SyncQueueService`)
  - gestion `429` (Retry-After + backoff exponentiel)
  - filtrage scope staff (evite sync de commandes d'un autre staff)

## 2) Structure du projet (Dart, hors fichiers generes)

| Dossier | Fichiers `.dart` | Lignes |
|---|---:|---:|
| `lib/views` | 21 | 12,125 |
| `lib/services` | 8 | 4,124 |
| `lib/controllers` | 10 | 3,093 |
| `lib/theme` | 3 | 592 |
| `lib/utils` | 6 | 546 |
| `lib/widgets` | 3 | 403 |
| `lib/models` | 8 | 291 |
| `lib/data` | 3 | 233 |
| `lib/seeders` | 2 | 149 |
| `lib/api` | 1 | 105 |
| `lib/config` | 1 | 82 |
| `lib/helper` | 1 | 62 |
| `lib/repos` | 2 | 39 |
| `lib/bindings` | 1 | 28 |

## 3) Technologies

### Stack principale
- Flutter
- Dart (SDK `^3.10.8`)
- GetX (state management, DI, navigation)
- Isar (base locale)
- HTTP (`package:http`)

### Packages majeurs
- `get`, `isar`, `isar_flutter_libs`, `http`, `path_provider`
- `file_picker`, `crypto`, `printing`, `pdf`
- `google_fonts`, `desktop_multi_window`, `audioplayers`, `cached_network_image`

### Outils dev
- `build_runner`, `isar_generator`, `flutter_lints`, `flutter_launcher_icons`

## 4) Metriques code

### Lignes de code
- `lib` total (avec generes): **33,352** lignes
- `lib` hors generes (`*.g.dart` exclus): **22,356** lignes
- Fichiers generes `*.g.dart`: **10,995** lignes
- `test`: **30** lignes

### Nombre de fonctions (estimation technique)
Comptage par regex sur declarations de fonctions/methodes/constructeurs dans `lib`:
- Hors generes: **~536**
- Avec generes: **~1,062**

Note: c'est une estimation statique (regex), utile pour pilotage macro, pas un comptage AST exact.

## 5) Sources externes (integrations)

### API backend
- Base URL: `https://soyabox.ma` (par defaut), surchargeable via `API_BASE_URL`.
- Token service/session: `API_TOKEN` ou token login.

### Endpoints principaux consommes
- Auth:
  - `/api/login`
  - `/api/login-pin`
- Sync:
  - `/api/sync/users/{upsert,delete}`
  - `/api/sync/categories/{upsert,delete}`
  - `/api/sync/products/{upsert,delete}`
  - `/api/sync/orders/{upsert,delete}`
- Commandes:
  - `/api/orders`
  - `/api/sync/orders`
  - `/api/orders/{id}/status`
  - `/api/orders/{id}/update-status`
- Import:
  - `/api/restaurants`
  - `/api/categories`
  - `/api/products`
  - `/api/users`
  - `/api/tables`

### Services externes techniques
- Isar Inspector (runtime dev): `https://inspect.isar.dev`
- Registry packages: `pub.dev` (dependances Flutter/Dart)

## 6) Sources internes utilisees pour ce rapport
- `pubspec.yaml`
- `docs/WORKFLOW.md`
- `lib/data/app_constants.dart`
- `lib/services/sync_queue_service.dart`
- `lib/controllers/sync_controller.dart`
- `lib/helper/dependencies.dart`
