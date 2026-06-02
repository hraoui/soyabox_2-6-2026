# ✅ SYNCHRONISATION EN ARRIÈRE-PLAN IMPLÉMENTÉE

## 🎯 Fonctionnalité implémentée

La synchronisation fonctionne **maintenant en arrière-plan**, même quand :
- ✅ L'application est ouverte mais aucune page n'est active
- ✅ L'utilisateur est sur l'écran d'accueil / splash
- ✅ L'utilisateur n'est PAS connecté (mais token disponible)
- ✅ L'application est en cours d'exécution mais inactive

---

## 🔧 Modifications apportées

### Fichier : `lib/controllers/sync_controller.dart`

**Avant :**
```dart
/// Start background sync that runs even without auth
/// This checks for API orders and plays notification sound
void startBackgroundSync() {
  // Seulement vérifie les commandes API entrantes
  _backgroundSyncTick();
}

Future<void> _backgroundSyncTick() async {
  // ❌ UNIQUEMENT : Backend → Local (API orders)
  final pullResult = await _pullIncomingApiOrders();
  // Play notification sound
}
```

**Après :**
```dart
/// Start background sync that runs even without auth
/// This syncs BOTH incoming API orders AND outgoing local orders/users
void startBackgroundSync() {
  // ✅ Sync complète dans les 2 sens
  _backgroundSyncTick();
}

Future<void> _backgroundSyncTick() async {
  // ✅ Étape 1: Local → Backend (orders + users)
  await _syncLocalToBackend();
  
  // ✅ Étape 2: Backend → Local (API orders)
  final pullResult = await _pullIncomingApiOrders();
  
  // ✅ Notification si nouvelles commandes
}

/// NEW: Sync local data (orders, users) to backend
/// Works even without authentication if token is available
Future<void> _syncLocalToBackend() async {
  // ✅ Récupère le token de session (même sans login)
  final token = AuthSessionService.instance.token;
  
  if (token.isEmpty) return;
  
  // ✅ Queue les commandes non synchronisées
  await SyncQueueService.instance.queueUnsyncedOrders();
  
  // ✅ Queue les utilisateurs non synchronisés
  await SyncQueueService.instance.queueUnsyncedUsers();
  
  // ✅ Envoie tout au backend
  await SyncQueueService.instance.flushQueue();
}
```

---

## 🔄 Flux de synchronisation en arrière-plan

```
┌─────────────────────────────────────────────────────────────┐
│         SYNCHRONISATION EN ARRIÈRE-PLAN (60 secondes)        │
└─────────────────────────────────────────────────────────────┘

Étape 1: Récupération du token
   └─ AuthSessionService.instance.token
   └─ Même sans utilisateur connecté !

Étape 2: Sync LOCALE → BACKEND
   ├─ Queue unsynced orders (commandes locales)
   ├─ Queue unsynced users (utilisateurs locaux)
   └─ Flush queue → Backend API
      └─ POST /api/sync/orders/upsert
      └─ POST /api/sync/users/upsert

Étape 3: Sync BACKEND → LOCALE
   ├─ Fetch API orders (/api/orders, /api/sync/orders)
   └─ Pull incoming orders → Local DB
      └─ Notification sonore si commandes pending

Étape 4: Répéter dans 60 secondes
   └─ Timer.periodic(Duration(seconds: 60), ...)

┌─────────────────────────────────────────────────────────────┐
│                    ÉTATS DE L'APPLICATION                    │
└─────────────────────────────────────────────────────────────┘

✅ App ouverte, page POS active       → SYNC ACTIVE
✅ App ouverte, page accueil          → SYNC ACTIVE  
✅ App ouverte, aucune page           → SYNC ACTIVE
✅ App en arrière-plan (minimisée)    → SYNC ACTIF (Flutter desktop)
❌ App fermée complètement            → SYNC STOPPÉ
```

---

## 📊 Logs attendus

### Sync réussie (arrière-plan)

```
🔄 [SYNC] Background sync tick starting...
📋 [QUEUE SCAN] Scanning 5 orders for sync to backend
📥 [QUEUE ADD] Order #123 queued for sync
📋 [USER QUEUE SCAN] Scanning 3 users for sync to backend
📥 [USER QUEUE ADD] User admin@example.com queued for sync
📤 [SYNCQ] Flushing queue (2 items)...
🚀 [SYNCQ] Sending item: orders:upsert:123
✅ [SYNCQ] Sent item orders:upsert:123 => 200
🚀 [SYNCQ] Sending item: users:upsert:admin@example.com
✅ [SYNCQ] Sent item users:upsert:admin@example.com => 200
✅ [SYNC] Queued unsynced orders
✅ [SYNC] Queued unsynced users
✅ [SYNC] Flushed queue to backend
📥 API Order Pull Result: new=0, updated=0, changed=0
🔇 [SYNC] No API pending orders (api_pending=0)
✅ [SYNC] Background sync tick completed
```

### Sync avec nouvelles commandes API

```
🔄 [SYNC] Background sync tick starting...
✅ [SYNC] Local→backend sync completed
📥 API Order Pull Result: new=2, updated=0, changed=2
🔔 [SYNC] API pending orders detected: 2
🎵 [NOTIF] Playing new order alarm...
🎵 [NOTIF] Playing new order alarm (second time)...
✅ [SYNC] Notification sound played successfully
✅ [SYNC] Background sync tick completed
```

### Sync sans token (app fraîchement installée)

```
🔄 [SYNC] Background sync tick starting...
⚠️ [SYNC] No token available, skipping local→backend sync
📥 API Order Pull Result: new=0, updated=0, changed=0
🔇 [SYNC] No API pending orders
✅ [SYNC] Background sync tick completed
```

---

## 🧪 Comment tester

### Test 1 : Sync en arrière-plan (app ouverte, aucune page)

```bash
# 1. Lancer l'application
cd /Users/macbookpro/Documents/caisse1-main

flutter run -d macos \
  --dart-define=API_BASE_URL=http://localhost:8000 \
  --dart-define=API_TOKEN=205|cxoHsmsLG5b3POjB9KTAWU0jJblZ6JFYwcWdcYpDd88e706a

# 2. Attendre le splash screen (ne pas se connecter)
# 3. Attendre 60 secondes
# 4. Vérifier les logs :

🔄 [SYNC] Starting background sync (full sync, no auth required)...
🔄 [SYNC] Background sync tick starting...
✅ [SYNC] Queued unsynced orders
✅ [SYNC] Queued unsynced users
✅ [SYNC] Flushed queue to backend
✅ [SYNC] Background sync tick completed
```

### Test 2 : Créer une commande et quitter l'écran POS

```bash
# 1. Se connecter avec Super Admin
# 2. Aller dans POS
# 3. Créer une commande
# 4. Revenir à l'écran d'accueil (ne pas fermer l'app)
# 5. Attendre 60 secondes
# 6. Vérifier les logs :

🛒 [CREATE ORDER] Order #123 created
🔄 [SYNC NEW] Order #123 enqueued for sync
... (après 60s) ...
🔄 [SYNC] Background sync tick starting...
📤 [SYNCQ] Flushing queue (1 items)...
✅ [SYNCQ] Sent item orders:upsert:123 => 200
💾 [SYNC STATE] Saved sync state for Order #123
```

### Test 3 : Vérifier la sync même sans page active

```dart
// Dans le code, après avoir navigué vers null / splash
Get.offAllNamed('/splash');

// La sync continue de fonctionner en arrière-plan !
// Logs attendus toutes les 60 secondes :
🔄 [SYNC] Background sync tick starting...
✅ [SYNC] Local→backend sync completed
```

---

## 🔍 Debug et vérification

### Vérifier que la sync est active

**Dans les logs, chercher :**
```
🔄 [SYNC] Starting background sync (full sync, no auth required)...
✅ [DEP] Background sync started
```

**Si ces logs n'apparaissent PAS :**
- Le SyncController n'est pas initialisé
- Vérifier `lib/helper/dependencies.dart`

### Vérifier la période de sync

**Dans `lib/controllers/sync_controller.dart` :**
```dart
static const Duration _autoSyncInterval = Duration(seconds: 60);
```

**Pour changer la période :**
```dart
static const Duration _autoSyncInterval = Duration(seconds: 30); // Plus fréquent
static const Duration _autoSyncInterval = Duration(minutes: 2);  // Moins fréquent
```

### Vérifier le token de session

**Dans la console Flutter (temporaire) :**
```dart
import 'package:caisse_1/services/auth_session_service.dart';

final token = AuthSessionService.instance.token;
print('Token: ${token.isEmpty ? "EMPTY" : token.substring(0, 20)}...');
```

---

## 📋 Checklist de validation

- [x] `startBackgroundSync()` appelé au démarrage
- [x] `_syncLocalToBackend()` implémenté
- [x] Token récupéré depuis `AuthSessionService`
- [x] `queueUnsyncedOrders()` appelé
- [x] `queueUnsyncedUsers()` appelé
- [x] `flushQueue()` appelé
- [x] Sync fonctionne sans utilisateur connecté
- [x] Sync fonctionne sans page active
- [x] Logs détaillés ajoutés
- [x] Timer périodique configuré (60s)
- [x] 0 erreur de compilation

---

## 🎯 Résumé

| État de l'app | Sync Local→Backend | Sync Backend→Local | Notification |
|---------------|-------------------|-------------------|--------------|
| **POS actif** | ✅ Active | ✅ Active | ✅ Active |
| **Accueil** | ✅ Active | ✅ Active | ✅ Active |
| **Splash (aucune page)** | ✅ Active | ✅ Active | ✅ Active |
| **Minimisée** | ✅ Active* | ✅ Active* | ✅ Active* |
| **Fermée** | ❌ Stop | ❌ Stop | ❌ Stop |

*Flutter desktop garde les timers actifs même en arrière-plan

---

## 🚀 Commande de test rapide

```bash
# 1. Générer un nouveau token (si besoin)
cd /Applications/MAMP/htdocs/soya_caisse_backend
php artisan tinker --execute="\$u=App\Models\User::find(1008); \$u->tokens()->delete(); echo \$u->createToken('sync')->plainTextToken;"

# 2. Lancer Flutter avec le token
cd /Users/macbookpro/Documents/caisse1-main
flutter run -d macos \
  --dart-define=API_BASE_URL=http://localhost:8000 \
  --dart-define=API_TOKEN=NOUVEAU_TOKEN

# 3. Attendre le splash screen (ne rien faire)
# 4. Attendre 60 secondes
# 5. Vérifier les logs de sync
```

---

## 📊 Architecture finale

```
┌─────────────────────────────────────────────────────────────┐
│                    SYNCHRONISATION AUTO                      │
└─────────────────────────────────────────────────────────────┘

DÉMARRAGE
   ↓
DependencyInjection.init()
   ↓
SyncController créé (permanent: true)
   ↓
startBackgroundSync() appelé
   ↓
Timer démarré (60 secondes)
   ↓
┌──────────────────────────────────────┐
│  Toutes les 60 secondes :            │
│                                      │
│  1. Sync Local → Backend             │
│     - Orders                         │
│     - Users                          │
│                                      │
│  2. Sync Backend → Local             │
│     - API Orders                     │
│     - Notification si pending        │
│                                      │
│  3. Attendre 60 secondes             │
│     └─ (boucle infinie)              │
└──────────────────────────────────────┘

ARRÊT
   ↓
Seulement si :
- Logout explicite (stopSync())
- Fermeture complète de l'app
- Exception non catchée
```

---

**Date :** 2025-04-02  
**Statut :** ✅ **IMPLÉMENTÉ ET TESTÉ**  
**Version :** 2.0.0
