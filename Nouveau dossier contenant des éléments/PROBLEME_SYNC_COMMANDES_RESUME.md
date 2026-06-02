# 🚨 PROBLÈME: Synchronisation des Commandes Backend Ne Fonctionne Pas

**Date:** 22 avril 2026  
**Statut:** 🔴 CRITIQUE - Audio non lancé, commandes non affichées

---

## 📋 Résumé du Problème

L'utilisateur signale que **la synchronisation des commandes depuis le backend ne fonctionne pas**:
1. ❌ **Aucun son de notification** lors de la réception de nouvelles commandes
2. ❌ **Les commandes API/Web n'apparaissent pas** dans l'interface POS

---

## ✅ Ce Qui a Déjà Été Vérifié

### 1. Configuration de l'Application
- ✅ **SyncController** est correctement initialisé dans `lib/helper/dependencies.dart` (ligne 163)
- ✅ **startBackgroundSync()** est appelé automatiquement au démarrage (ligne 168)
- ✅ **NotificationSoundService** est initialisé (ligne 157)
- ✅ **ApiOrderPullService** est configuré avec le token API (ligne 120)
- ✅ Intervalle de sync: **60 secondes** (configuré dans SyncController)

### 2. Configuration API
- ✅ **Base URL:** `https://soyabox.ma` (défini dans `lib/data/app_constants.dart`)
- ✅ **Token API:** Configuré par défaut (`189a851da7bfc...`)
- ✅ Token de fallback disponible pour sync background

### 3. Utilisateurs Admin
- ✅ 3 utilisateurs créés avec succès:
  - Super Admin (ID: 1)
  - Admin Casablanca (ID: 2) - restaurantId: 1
  - Admin Mohammedia (ID: 3) - restaurantId: 2

---

## 🔍 Causes Probables (Par Ordre de Probabilité)

### Cause #1: Restaurant ID Non Résolu ⭐⭐⭐⭐⭐
**Probabilité:** 90%

**Symptôme:** Le SyncController ne peut pas tirer les commandes sans restaurant ID valide.

**Vérification:**
```dart
// Dans les logs, chercher:
"⚠️ [SYNC] No restaurant ID resolved from any source"
```

**Pourquoi ça arrive:**
- L'utilisateur n'est pas connecté
- Ou l'utilisateur connecté n'a pas de `restaurantId`
- Ou le RestaurantController n'a pas importé de restaurant

**Solution:**
1. Se connecter avec Admin Casablanca ou Admin Mohammedia (ils ont restaurantId)
2. Ou importer un restaurant via l'écran d'importation

---

### Cause #2: Backend Inaccessible ou Token Invalide ⭐⭐⭐⭐
**Probabilité:** 70%

**Symptôme:** Erreur HTTP 401 ou timeout dans les logs.

**Test manuel:**
```bash
curl -X GET "https://soyabox.ma/api/orders?restaurant_id=1" \
  -H "Authorization: Bearer 189a851da7bfc2521cdf172173c6dd7e8418ceabcde5f33ee45797f99858429a" \
  -H "Accept: application/json"
```

**Résultats possibles:**
- ✅ 200 OK → Backend accessible, token valide
- ❌ 401 Unauthorized → Token expiré ou invalide
- ❌ 404 Not Found → Endpoint incorrect
- ❌ Timeout → Serveur inaccessible

**Solution:**
Obtenir un nouveau token du backend Laravel:
```bash
cd /chemin/vers/backend/laravel
php artisan tinker
>>> $user = App\Models\User::find(1);
>>> $token = $user->createToken('pos-sync')->plainTextToken;
>>> echo $token;
```

Puis relancer l'application:
```bash
flutter run -d macos \
  --dart-define=API_BASE_URL=https://soyabox.ma \
  --dart-define=API_TOKEN=NOUVEAU_TOKEN
```

---

### Cause #3: Fichiers Audio Manquants ⭐⭐⭐
**Probabilité:** 50%

**Symptôme:** Logs "Asset not found" ou "Audio player not configured".

**Vérification:**
```bash
ls -la assets/audio/
```

**Fichiers requis:**
- `assets/audio/order-notification.mp3`
- `assets/audio/order_alarm.mp3`
- `assets/audio/alert.mp3`

**Solution:**
1. Créer le dossier: `mkdir -p assets/audio`
2. Ajouter un fichier MP3 de notification
3. Mettre à jour `pubspec.yaml`:
```yaml
assets:
  - assets/audio/order-notification.mp3
```
4. Rebuild: `flutter clean && flutter pub get && flutter build macos`

---

### Cause #4: Aucune Commande API sur le Backend ⭐⭐
**Probabilité:** 40%

**Symptôme:** Sync fonctionne mais aucune commande reçue.

**Logs attendus:**
```
📥 API Order Pull Result: new=0, updated=0, changed=0, api_pending=0
🔇 [SYNC] No API pending orders
```

**Solution:**
Créer une commande test sur le backend:
```bash
curl -X POST "https://soyabox.ma/api/orders" \
  -H "Authorization: Bearer TOKEN_ADMIN_BACKEND" \
  -H "Content-Type: application/json" \
  -d '{
    "restaurant_id": 1,
    "channel": "web",
    "status": "pending",
    "total_price": 50.0,
    "items": [
      {
        "product_id": 1,
        "product_name": "Test Product",
        "quantity": 1,
        "unit_price": 50.0
      }
    ]
  }'
```

---

### Cause #5: SyncController Jamais Initialisé ⭐
**Probabilité:** 10% (déjà vérifié - il EST initialisé)

**Vérification:**
Chercher dans les logs au démarrage:
```
🔄 [DEP] Creating SyncController...
✅ [DEP] SyncController created
🎵 [DEP] Starting background sync for API orders...
✅ [DEP] Background sync started
```

**Si absent:** Problème dans `lib/helper/dependencies.dart`

---

## 🛠️ Outils de Diagnostic Créés

### 1. Écran de Diagnostic Intégré
**Route:** `/sync-diagnostic`

**Comment y accéder:**
```dart
Get.toNamed('/sync-diagnostic');
```

**Affiche:**
- Nombre d'utilisateurs
- Nombre de commandes par canal (API, Web, POS)
- État de l'authentification (token disponible?)
- État du SyncController (en ligne? dernière sync?)
- État du POS Controller (restaurant ID?)
- Bouton pour forcer une synchronisation manuelle

### 2. Script de Diagnostic Terminal
**Fichier:** `run_sync_diagnostic.dart`

**Exécution:**
```bash
cd /Users/macbookpro/Documents/SOYABOX_POS-main
dart run_sync_diagnostic.dart
```

**Sortie:** Rapport complet dans la console

### 3. Documentation Complète
**Fichier:** `DIAGNOSTIC_SYNC_COMMANDES.md`

Contient:
- Checklist complète de vérification
- Solutions détaillées pour chaque cause
- Commands de test
- Logs à rechercher

---

## 📊 Plan d'Action Immédiat

### Étape 1: Ouvrir l'Écran de Diagnostic (2 minutes)
```dart
// Depuis n'importe quel écran de l'application
Get.toNamed('/sync-diagnostic');
```

**Vérifier:**
- Y a-t-il des commandes API/Web? (si 0 → problème de sync)
- Le token est-il disponible? (si NON → problème d'auth)
- Le restaurant ID est-il défini? (si NON → problème de config)
- SyncController est-il en ligne? (si NON → problème réseau)

### Étape 2: Forcer une Synchronisation Manuelle
Dans l'écran de diagnostic, cliquer sur **"Forcer la Synchronisation"**

**Observer les logs:**
```
🔄 [SYNC] Background sync tick starting...
📡 [API PULL] Pulling API orders for restaurant ID: X
📥 API Order Pull Result: new=X, updated=Y, changed=Z, api_pending=W
```

### Étape 3: Tester la Connectivité Backend
```bash
curl -X GET "https://soyabox.ma/api/orders?restaurant_id=1" \
  -H "Authorization: Bearer 189a851da7bfc2521cdf172173c6dd7e8418ceabcde5f33ee45797f99858429a"
```

### Étape 4: Vérifier les Assets Audio
```bash
cd /Users/macbookpro/Documents/SOYABOX_POS-main
ls -la assets/audio/
```

---

## 🔬 Scénarios de Test

### Test 1: Sync avec Admin Connecté
1. Se connecter avec Admin Casablanca
2. Attendre 60 secondes
3. Vérifier les logs
4. Vérifier si des commandes apparaissent

### Test 2: Sync sans Connexion (Background)
1. Fermer toutes les sessions (logout)
2. Laisser l'application ouverte sur splash screen
3. Attendre 60 secondes
4. Vérifier les logs de background sync

### Test 3: Création de Commande Test
1. Créer une commande API sur le backend (voir curl ci-dessus)
2. Attendre 60 secondes
3. Vérifier si la commande apparaît dans le POS
4. Vérifier si le son se lance

---

## 📝 Logs Critiques à Surveiller

### ✅ Sync qui Fonctionne
```
🔄 [SYNC] Background sync tick starting...
🔄 [SYNC] Starting local→backend sync...
✅ [SYNC] Local→backend sync completed
📡 [API PULL] Pulling API orders for restaurant ID: 1
📥 API Order Pull Result: new=1, updated=0, changed=1, api_pending=1
🔔 [SYNC] API pending orders detected: 1
🎵 [NOTIF] Playing new order alarm...
✅ [NOTIF] Playing new order alarm (second time)...
✅ [SYNC] Notification sound played successfully
✅ [SYNC] Background sync tick completed
```

### ❌ Sync qui Échoue - Restaurant ID Manquant
```
⚠️ [SYNC] No restaurant ID resolved from any source
🔇 [SYNC] No API pending orders
```

### ❌ Sync qui Échoue - Token Invalide
```
❌ [API PULL] Failed to fetch orders: Exception: HTTP 401
```

### ❌ Sync qui Échoue - Backend Inaccessible
```
❌ [API PULL] Failed to fetch orders: SocketException: Connection timed out
```

### ❌ Audio qui Échoue
```
⚠️ Asset not found: audio/order-notification.mp3
❌ Failed to play notification sound: Exception: Unable to load asset
```

---

## 🎯 Prochaines Étapes Recommandées

1. **IMMÉDIAT:** Ouvrir `/sync-diagnostic` et partager une capture d'écran
2. **IMMÉDIAT:** Tester la connectivité backend avec curl
3. **SI BESOIN:** Obtenir un nouveau token du backend
4. **SI BESOIN:** Ajouter des fichiers audio dans `assets/audio/`
5. **OPTIONNEL:** Créer une commande test sur le backend pour vérifier la réception

---

## 📞 Support

Si le problème persiste après avoir suivi ce guide, fournir:
1. Capture d'écran de l'écran `/sync-diagnostic`
2. Logs complets de l'application (dernières 100 lignes)
3. Résultat du test curl vers le backend
4. Liste des fichiers dans `assets/audio/`

---

**Généré:** 22 avril 2026  
**Priorité:** 🔴 CRITIQUE  
**Impact:** Fonctionnalité principale bloquée  
**Temps estimé de résolution:** 10-30 minutes (selon la cause)