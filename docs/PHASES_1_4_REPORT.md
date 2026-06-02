# Rapport Technique Phases 1 a 4

Date: 2026-03-25
Projet: `caisse_1`

## Objectif

Ce rapport resume les changements realises sur les phases 1 a 4 autour de la synchronisation POS/API, de la fiabilisation de la queue, de la session PIN/auth, de la deduplication des commandes et de la normalisation des logs.

Il sert de reference pour les prochaines taches afin d'eviter de re-analyser tout le contexte.

## Vue d'ensemble

- Phase 1: stabilisation immediate du flux de sync.
- Phase 2: fiabilisation de la queue et des resets de state.
- Phase 3: refonte sensible de la deduplication, de la session PIN et de la persistance atomique.
- Phase 4: consolidation du logger structure sur l'ensemble des `controllers` et `services`.

## Phase 1

Corrections principales:

- Suppression du `flushQueue()` bloquant dans `_enqueue()` et remplacement par un flush debonce.
- Passage du flush periodique de la queue a `45s`.
- Passage de l'auto-sync controller a `30s`.
- Validation stricte de `restaurantId` avant creation de commande POS.
- Gestion correcte des `403 staff scope` sans faux marquage "synced".
- Limitation du fallback status a `pending`, `confirmed`, `delivered`.
- Blocage des fallback sur `cancelled`.
- Ajout d'une sync immediate deboncee apres creation de commande si la session est online.

Fichiers principaux:

- `lib/services/sync_queue_service.dart`
- `lib/controllers/pos_controller.dart`
- `lib/controllers/sync_controller.dart`
- `lib/services/api_order_pull_service.dart`

## Phase 2

Corrections principales:

- Ajout d'une gestion des echecs permanents avec `retry_count`, `last_attempt_at`, `first_error`, `skip_reason`.
- Introduction d'une dead-letter queue persistante et de `getFailedItems()`.
- Protection du reset du remote state avec preservation optionnelle des commandes recentes.
- Verification locale avant `clearRemoteState()`.
- Warning utilisateur contextualise si des commandes API peuvent etre recreees.
- Renforcement du `_checkOnline()` avec timeout `5s`, multi-hosts, cache `10s` et etat partiel.

Fichiers principaux:

- `lib/services/sync_queue_service.dart`
- `lib/services/api_order_pull_service.dart`
- `lib/services/database_service.dart`
- `lib/controllers/sync_controller.dart`

## Phase 3

Corrections principales:

- Ajout de `sourceLocalId` indexe dans `PosOrder` et regeneration Isar.
- Remplissage automatique de `sourceLocalId` sur les commandes POS locales.
- Deduplication d'abord par match exact `sourceLocalId`, puis par signature stricte.
- Reduction de la tolerance de matching a `30s`.
- Suppression du matching trop faible base uniquement sur `total + temps`.
- Renforcement de la session PIN:
  - detection d'expiration de token,
  - refresh du token si besoin,
  - fallback possible via credentials sauvegardes compatibles,
  - notification si la sync reste desactivee.
- Mise en place d'une persistance atomique de l'etat de sync:
  - backup,
  - fichier transactionnel,
  - recovery au redemarrage.
- Introduction du socle `AppLogger` et migration du noyau sync/auth.

Fichiers principaux:

- `lib/models/pos_order.dart`
- `lib/models/pos_order.g.dart`
- `lib/services/database_service.dart`
- `lib/services/api_order_pull_service.dart`
- `lib/services/auth_session_service.dart`
- `lib/services/sync_queue_service.dart`
- `lib/controllers/auth_controller.dart`
- `lib/controllers/pos_controller.dart`
- `lib/controllers/sync_controller.dart`
- `lib/utils/app_logger.dart`
- `pubspec.yaml`

## Phase 4

Objectif:

- Etendre le logger structure au reste des `controllers` et `services` encore en `print/debugPrint`.

Corrections principales:

- Remplacement des `print()` et `debugPrint()` restants dans `lib/controllers` et `lib/services` par `appLogger`.
- Suppression des directives `ignore_for_file: avoid_print` sur les fichiers migres.
- Uniformisation des imports vers `lib/utils/app_logger.dart`.

Fichiers couverts en phase 4:

- `lib/controllers/delivery_controller.dart`
- `lib/controllers/product_controller.dart`
- `lib/controllers/category_controller.dart`
- `lib/controllers/restaurant_controller.dart`
- `lib/controllers/import_controller.dart`
- `lib/controllers/user_controller.dart`
- `lib/services/notification_sound_service.dart`
- `lib/services/order_api_service.dart`
- `lib/services/order_delivery_api_service.dart`
- `lib/services/api_import_service.dart`

Resultat:

- Plus aucun `print()` ni `debugPrint()` actif dans `lib/services` et `lib/controllers`.

## Validation effectuee

Commandes utilisees pendant le chantier:

- `dart run build_runner build --delete-conflicting-outputs`
- `flutter pub get`
- `dart format ...`
- `flutter analyze ...`

Validation finale:

- `flutter analyze` sur les fichiers coeur phases 1 a 3: OK
- `flutter analyze` sur les fichiers migres phase 4: OK
- residu `print/debugPrint` dans `lib/services` et `lib/controllers`: aucun

## Fichiers les plus sensibles

Ces fichiers meritent une attention particuliere lors des prochaines taches:

- `lib/services/sync_queue_service.dart`
- `lib/services/api_order_pull_service.dart`
- `lib/services/auth_session_service.dart`
- `lib/controllers/pos_controller.dart`
- `lib/controllers/sync_controller.dart`
- `lib/services/database_service.dart`
- `lib/models/pos_order.dart`

## Points de vigilance restants

- `lib/models/pos_order.g.dart` a ete regenere par `build_runner`; toute future modification du modele devra repasser par generation.
- La logique de deduplication est plus stricte: toute nouvelle source de commande devra renseigner correctement `sourceLocalId` si elle veut beneficier du match exact.
- La session PIN peut maintenant retenter une reconnexion via PIN ou credentials sauvegardes, mais tout changement de contrat backend sur `/api/login` ou `/api/login-pin` devra etre reverifie.
- La persistance atomique de l'etat de sync repose sur les fichiers de backup et de transaction; si le format de state change, il faudra penser a la compatibilite de recovery.
- Le workspace contenait deja d'autres changements locaux hors perimetre; ils n'ont pas ete revert.

## Prochaines taches suggerees

- Ajouter des tests cibles sur:
  - la deduplication par `sourceLocalId`,
  - les retries et la dead-letter queue,
  - la reprise apres crash de l'etat de sync,
  - le refresh de session PIN.
- Ajouter un ecran ou un outil admin pour inspecter la dead-letter queue.
- Enrichir progressivement les logs avec davantage de contexte metier la ou utile.
- Si besoin, preparer une phase 5 orientee tests et observabilite.

## Resume court

Les phases 1 a 4 ont stabilise la sync, rendu la queue plus sure, reduit les risques de doublons, fiabilise la session PIN/auth et unifie les logs techniques. L'etat actuel est proprement formate, documente et valide par `flutter analyze` sur les fichiers modifies.
