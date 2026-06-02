# 🔍 DIAGNOSTIC: Synchronisation des Commandes Backend

**Date:** 22 avril 2026  
**Problème:** La synchronisation des commandes depuis le backend ne fonctionne pas - audio non lancé et commandes non affichées

---

## 📋 État Actuel du Système

### ✅ Ce qui fonctionne
1. **3 utilisateurs admin créés avec succès:**
   - Super Admin (ID: 1) - PIN: superadmin123
   - Admin Casablanca (ID: 2) - PIN: casa123
   - Admin Mohammedia (ID: 3) - PIN: moha123

2. **Configuration API par défaut:**
   - Base URL: `https://soyabox.ma`
   - Token API: Configuré (lecture seule)

### ❌ Problèmes Identifiés

#### 1. Audio Non Lancé
**Symptôme:** Aucune notification sonore lors de la réception de nouvelles commandes API

**Causes Possibles:**
- [ ] Service de notification non initialisé
- [ ] Fichiers audio manquants dans les assets
- [ ] Permissions audio non accordées sur macOS
- [ ] Volume système à zéro
- [ ] Code de notification jamais appelé (sync ne fonctionne pas)

#### 2. Commandes Non Affichées
**Symptôme:** Les commandes du backend n'apparaissent pas dans l'interface POS

**Causes Possibles:**
- [ ] SyncController non initialisé
- [ ] Background sync non démarré
- [ ] Restaurant ID non configuré
- [ ] Token API invalide/expiré
- [ ] Endpoint backend inaccessible
- [ ] Erreur de parsing des données API
- [ ] Filtre restaurant incorrect

---

## 🔧 Étapes de Diagnostic

### Étape 1: Vérifier si le SyncController est Initialisé

Le SyncController doit être initialisé au démarrage de l'application.

**Fichier:** `lib/helper/dependencies.dart` ou `lib/main.dart`

Vérifiez que ce code existe:
```dart
// Dans main() ou initDependencies()
Get.lazyPut(() => SyncController());
```

### Étape 2: Vérifier si le Background Sync est Démarré

Le background sync doit être démarré après le login ou au démarrage.

**Rechercher dans les logs:**
```
🔄 [SYNC] Starting background sync (full sync, no auth required)...
✅ [DEP] Background sync started with 60s interval
```

**Si ces logs n'apparaissent PAS:**
- Le sync n'est pas démarré
- Ajouter dans `main.dart` après l'initialisation:
```dart
if (Get.isRegistered<SyncController>()) {
  Get.find<SyncController>().startBackgroundSync();
}
```

### Étape 3: Vérifier le Restaurant ID

La synchronisation nécessite un restaurant ID valide.

**Logs à rechercher:**
```
🍽️ [SYNC] Using imported restaurant ID: X
⚠️ [SYNC] No restaurant ID resolved from any source
```

**Solution si restaurant ID manquant:**
1. Se connecter avec un compte admin qui a un restaurantId
2. Ou importer un restaurant via RestaurantController

### Étape 4: Vérifier la Connectivité API

**Test manuel:**
```bash
curl -X GET "https://soyabox.ma/api/orders?restaurant_id=1" \
  -H "Authorization: Bearer 189a851da7bfc2521cdf172173c6dd7e8418ceabcde5f33ee45797f99858429a" \
  -H "Accept: application/json"
```

**Résultats attendus:**
- ✅ 200 OK avec liste de commandes
- ❌ 401 Unauthorized → Token invalide
- ❌ 404 Not Found → Endpoint incorrect
- ❌ Timeout → Serveur inaccessible

### Étape 5: Vérifier les Logs de Sync

**Logs critiques à rechercher:**

#### A. Début de Sync
```
🔄 [SYNC] Background sync tick starting...
🔄 [SYNC] Starting local→backend sync...
```

#### B. Pull des Commandes API
```
📡 [API PULL] Pulling API orders for restaurant ID: X
📥 API Order Pull Result: new=X, updated=Y, changed=Z, api_pending=W
```

#### C. Notifications
```
🔔 [SYNC] API pending orders detected: W
🎵 [NOTIF] Playing new order alarm...
✅ [SYNC] Notification sound played successfully
```

#### D. Erreurs
```
❌ [SYNC] Background sync failed: ERROR_MESSAGE
❌ [API PULL] Failed to fetch orders: ERROR_MESSAGE
❌ [NOTIF] Failed to play notification: ERROR_MESSAGE
```

### Étape 6: Vérifier les Assets Audio

**Fichiers requis dans `pubspec.yaml`:**
```yaml
assets:
  - assets/audio/order-notification.mp3
  - assets/audio/order_alarm.mp3
  - assets/audio/alert.mp3
```

**Vérifier l'existence:**
```bash
ls -la assets/audio/
```

### Étape 7: Vérifier la Base de Données Locale

**Commandes à exécuter:**
```dart
// Dans l'application ou script de test
import 'package:soyabox_pos/services/database_service.dart';

await DatabaseService.init();

// Compter les commandes
final allOrders = await DatabaseService.getPosOrdersByChannel('all');
print('Total orders: ${allOrders.length}');

final apiOrders = await DatabaseService.getPosOrdersByChannel('api');
print('API orders: ${apiOrders.length}');

// Afficher les détails
for (final order in apiOrders) {
  print('Order #${order.id}: status=${order.status}, total=${order.totalPrice}');
}
```

---

## 🎯 Solutions Probables

### Solution 1: SyncController Non Initialisé

**Symptôme:** Aucun log de sync dans la console

**Fix:**
Dans `lib/main.dart`, ajouter après `runApp()`:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDependencies();
  
  // ✅ Démarrer le background sync
  if (Get.isRegistered<SyncController>()) {
    Get.find<SyncController>().startBackgroundSync();
  }
  
  runApp(const MyApp());
}
```

### Solution 2: Restaurant ID Manquant

**Symptôme:** Log "No restaurant ID resolved from any source"

**Fix:**
1. Se connecter avec un compte admin ayant un restaurantId
2. Ou configurer manuellement:
```dart
// Dans RestaurantController
await RestaurantController.instance.setImportedRestaurantId(1);
```

### Solution 3: Token API Invalide

**Symptôme:** Erreur 401 dans les logs

**Fix:**
1. Obtenir un nouveau token du backend Laravel:
```bash
cd /chemin/vers/backend/laravel
php artisan tinker
>>> $user = App\Models\User::find(1);
>>> $token = $user->createToken('pos-sync')->plainTextToken;
>>> echo $token;
```

2. Lancer l'application avec le nouveau token:
```bash
flutter run -d macos \
  --dart-define=API_BASE_URL=https://soyabox.ma \
  --dart-define=API_TOKEN=NOUVEAU_TOKEN_ICI
```

### Solution 4: Fichiers Audio Manquants

**Symptôme:** "Asset not found" dans les logs

**Fix:**
1. Créer le dossier:
```bash
mkdir -p assets/audio
```

2. Télécharger ou créer un fichier MP3 de notification

3. Mettre à jour `pubspec.yaml`:
```yaml
assets:
  - assets/audio/order-notification.mp3
```

4. Rebuild:
```bash
flutter clean
flutter pub get
flutter build macos
```

### Solution 5: Endpoint Backend Incorrect

**Symptôme:** Erreur de connexion ou 404

**Fix:**
Vérifier l'URL dans `lib/data/app_constants.dart`:
```dart
static String get baseUrl {
  return 'https://soyabox.ma'; // Vérifier que c'est correct
}
```

Tester manuellement:
```bash
curl https://soyabox.ma/api/orders
```

---

## 📊 Checklist de Vérification Rapide

- [ ] SyncController initialisé dans dependencies
- [ ] startBackgroundSync() appelé dans main()
- [ ] Restaurant ID configuré (> 0)
- [ ] Token API valide et non expiré
- [ ] Backend accessible (test curl)
- [ ] Fichiers audio présents dans assets/
- [ ] Logs de sync visibles dans la console
- [ ] Utilisateur connecté (ou session active)
- [ ] Connexion internet fonctionnelle
- [ ] Pas d'erreurs dans les logs

---

## 🔬 Test Complet

Pour tester complètement la synchronisation:

1. **Lancer l'application avec logs détaillés:**
```bash
cd /Users/macbookpro/Documents/SOYABOX_POS-main
flutter run -d macos --verbose 2>&1 | grep -E "(SYNC|API PULL|NOTIF)" 
```

2. **Créer une commande test sur le backend:**
```bash
curl -X POST "https://soyabox.ma/api/orders" \
  -H "Authorization: Bearer TOKEN_ADMIN" \
  -H "Content-Type: application/json" \
  -d '{
    "restaurant_id": 1,
    "channel": "web",
    "status": "pending",
    "total_price": 50.0,
    "items": [...]
  }'
```

3. **Attendre 60 secondes** (intervalle de sync)

4. **Vérifier les logs:**
```
📡 [API PULL] Pulling API orders for restaurant ID: 1
📥 API Order Pull Result: new=1, updated=0, changed=1, api_pending=1
🔔 [SYNC] API pending orders detected: 1
🎵 [NOTIF] Playing new order alarm...
```

5. **Vérifier la base locale:**
```dart
final apiOrders = await DatabaseService.getPosOrdersByChannel('api');
print('API orders count: ${apiOrders.length}');
```

---

## 📝 Prochaines Étapes

1. **Exécuter le diagnostic automatique:**
```bash
cd /Users/macbookpro/Documents/SOYABOX_POS-main
dart run_sync_diagnostic.dart
```

2. **Partager les logs complets** pour analyse approfondie

3. **Vérifier la configuration backend** (endpoints disponibles)

4. **Tester manuellement l'endpoint API** avec curl

---

**Généré:** 22 avril 2026  
**Statut:** En attente de diagnostic utilisateur  
**Priorité:** Haute - Fonctionnalité critique bloquée