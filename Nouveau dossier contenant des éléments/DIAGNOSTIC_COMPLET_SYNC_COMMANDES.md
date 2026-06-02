# 🔴 DIAGNOSTIC: Commandes POS non visibles + Erreurs de synchronisation

**Date**: 2026-04-23  
**Statut**: CRITIQUE - Synchronisation backend cassée

---

## 📋 Résumé du Problème

Les commandes ne s'affichent pas dans "Mes Commandes" du staff. Après analyse des logs, **DEUX problèmes majeurs** ont été identifiés:

### 1. ❌ Erreur Backend - Colonne `local_id` manquante
```
SQLSTATE[42S22]: Column not found: 1054 Unknown column 'local_id' in 'where clause'
(Connection: mysql, SQL: select * from `orders` where `local_id` = 5 and `restaurant_id` = 2 limit 1)
```

**Impact**: Les commandes POS (#5) ne peuvent PAS être synchronisées vers le backend Laravel.

### 2. ❌ Erreurs d'authentification (401 Unauthorized)
```
⚠️ Pull skipped /api/sync/orders: HTTP 401
📥 Response status: 401 for /api/users
❌ Failed to load users: 401
```

**Impact**: L'app ne peut PAS récupérer les commandes API/Web depuis le backend.

---

## 🔍 Analyse Détaillée

### Workflow Attendu (selon vos spécifications):

#### Pour les commandes Web/API:
```
User passe commande 
    ↓
Enregistrement DB backend (Laravel) ✅
    ↓
Synchronisation Flutter app (toutes les 60s) ❌ BLOQUÉ (401)
    ↓
Détection: channel=web/api + status=pending ❌ JAMAIS ATTEINT
    ↓
Enregistrement dans Isar DB locale ❌
    ↓
Alerte audio jouée ❌
    ↓
Confirmation affichée ❌
```

#### Pour les commandes POS:
```
Staff crée commande sur POS ✅
    ↓
Enregistrement Isar DB locale ✅
    ↓
Synchronisation automatique (60s) ✅
    ↓
Envoi vers backend via SyncQueueService ✅
    ↓
Backend retourne ID distant ❌ ERREUR SQL (local_id manquant)
    ↓
Commande marquée syncStatus='synced' ❌ JAMAIS ATTEINT
```

---

## 🎯 Causes Racines Identifiées

### Cause #1: Backend - Colonne `local_id` manquante

**Fichier concerné**: Backend Laravel (`app/Http/Controllers/Api/PublicSyncController.php`)

Le code Flutter envoie ce payload:
```dart
{
  'local_id': 5,                    // ID local Isar
  'source_local_id': 5,             // Même valeur
  'staff_id': 232,
  'restaurant_id': 2,
  'channel': 'pos',
  // ... autres champs
}
```

Le backend essaie de chercher la commande avec:
```sql
SELECT * FROM orders WHERE local_id = 5 AND restaurant_id = 2
```

**Problème**: La colonne `local_id` n'existe PAS dans la table `orders` du backend.

### Cause #2: Token d'authentification invalide ou expiré

**Logs observés**:
```
🔑 [SYNC] Using token: admin_pin_1776951934853...
📥 Response status: 401 for /api/sync/orders
📥 Response status: 401 for /api/users
```

**Causes possibles**:
- Token PIN généré localement n'est pas reconnu par le backend
- Middleware d'authentification du backend rejette le format du token
- Token expiré ou révoqué côté serveur

---

## ✅ Solutions Requises

### Solution #1: Ajouter la colonne `local_id` au backend (URGENT)

**Action requise sur le serveur Laravel**:

1. Créer une migration:
```bash
php artisan make:migration add_local_id_to_orders_table
```

2. Contenu de la migration:
```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->unsignedBigInteger('local_id')->nullable()->index();
            $table->string('source_local_id')->nullable()->index();
        });
    }

    public function down(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->dropColumn(['local_id', 'source_local_id']);
        });
    }
};
```

3. Exécuter la migration:
```bash
php artisan migrate
```

4. Mettre à jour le contrôleur `PublicSyncController.php`:
```php
// Dans la méthode upsert ou similaire
public function upsert(Request $request)
{
    $localId = $request->input('local_id');
    $sourceLocalId = $request->input('source_local_id');
    $restaurantId = $request->input('restaurant_id');
    
    // Chercher par local_id OU source_local_id
    $order = Order::where(function($query) use ($localId, $sourceLocalId) {
        $query->where('local_id', $localId)
              ->orWhere('source_local_id', $sourceLocalId);
    })
    ->where('restaurant_id', $restaurantId)
    ->first();
    
    if ($order) {
        // Mise à jour
        $order->update($request->all());
    } else {
        // Création
        $order = Order::create(array_merge($request->all(), [
            'local_id' => $localId,
            'source_local_id' => $sourceLocalId,
        ]));
    }
    
    return response()->json([
        'success' => true,
        'data' => ['id' => $order->id]
    ]);
}
```

### Solution #2: Corriger l'authentification API

**Vérifications à faire sur le backend**:

1. Vérifier que le middleware auth accepte les tokens PIN:
```php
// Dans app/Http/Kernel.php ou config/auth.php
'guards' => [
    'api' => [
        'driver' => 'token',  // ou 'sanctum' si utilisé
        'provider' => 'users',
    ],
],
```

2. Vérifier que la route `/api/sync/orders` est accessible avec le token PIN:
```php
// Dans routes/api.php
Route::middleware('auth:sanctum')->group(function () {
    Route::post('/sync/orders', [PublicSyncController::class, 'upsert']);
});
```

3. Si vous utilisez Sanctum, générer un token valide:
```php
// Dans AuthController ou similaire
$token = $user->createToken('flutter-pos')->plainTextToken;
```

4. Alternative: Créer une route publique pour la sync (si sécurité acceptable):
```php
Route::post('/sync/public/orders', [PublicSyncController::class, 'upsert']);
```

---

## 🧪 Tests de Validation

Après avoir appliqué les corrections backend:

### Test 1: Synchronisation d'une commande POS
1. Créer une nouvelle commande sur le POS
2. Attendre 60 secondes ou forcer la sync
3. Vérifier les logs:
   ```
   ✅ Sync successful [orders/upsert] endpoint=/api/sync/public/orders/upsert status=200
   💾 [ORDER SYNC STATE] Saved sync state for Order #X
   ```
4. Vérifier dans la base de données backend que la commande apparaît

### Test 2: Récupération des commandes API/Web
1. Créer une commande directement dans le backend (channel='api' ou 'web')
2. Attendre 60 secondes
3. Vérifier les logs:
   ```
   📥 [PULL] Fetched 1 orders across 1 page(s)
   ✅ [API PULL] Completed: 1 pending, 1 new, 0 updated
   🔊 [NOTIF] Playing notification sound
   🔄 [SYNC] Refreshing POS display to show pending orders...
   ```
4. Vérifier que la commande apparaît dans "Mes Commandes"

### Test 3: Diagnostic complet
Exécuter l'écran de diagnostic créé:
```dart
Get.to(() => const StaffOrdersDiagnostic());
```

Vérifier que:
- ✅ Total Orders in Database > 0
- ✅ Remote Channel Orders affiche les commandes API/Web
- ✅ Visible Orders correspond aux attentes
- ❌ Filtered Orders = 0 (ou explique pourquoi)

---

## 📊 État Actuel du Système

| Composant | Statut | Détails |
|-----------|--------|---------|
| Base Isar locale | ✅ OK | Commandes stockées correctement |
| Sync Local → Backend | ❌ BLOQUÉ | Erreur SQL `local_id` manquant |
| Sync Backend → Local | ❌ BLOQUÉ | Erreur 401 Unauthorized |
| Affichage "Mes Commandes" | ⚠️ PARTIEL | Seulement les commandes locales POS |
| Notifications audio | ❌ INACTIF | Jamais déclenché (pas de pull API) |
| Queue de synchronisation | ⚠️ BLOQUÉE | 1 commande en attente (#5) |

---

## 🚀 Actions Immédiates Requises

### Priorité 1 - CRITIQUE (à faire maintenant):
1. **Ajouter la colonne `local_id`** à la table `orders` du backend
2. **Tester la synchronisation** d'une commande POS
3. **Vérifier** que l'erreur SQL disparaît

### Priorité 2 - HAUTE (après correction #1):
4. **Diagnostiquer l'erreur 401** sur les appels API
5. **Vérifier le middleware d'auth** du backend
6. **Tester** la récupération des commandes API/Web

### Priorité 3 - MOYENNE:
7. **Ajouter des logs détaillés** côté backend pour faciliter le debug
8. **Implémenter un système de retry** plus robuste pour les erreurs 401
9. **Créer un dashboard admin** pour monitorer la synchronisation

---

## 📞 Support Technique

Si vous avez besoin d'aide pour modifier le backend Laravel:

1. Partagez le fichier `PublicSyncController.php`
2. Partagez la structure de la table `orders` (migration ou schema)
3. Partagez la configuration d'authentification API (`config/auth.php`, `config/sanctum.php`)

Je pourrai alors fournir le code exact à ajouter/modifier.

---

## 📝 Notes Supplémentaires

- Un écran de diagnostic a été créé: `/lib/views/diagnostics/staff_orders_diagnostic.dart`
- Des logs améliorés ont été ajoutés dans `pos_controller.dart` pour tracer la visibilité des commandes
- La mémoire workspace a été mise à jour avec ce problème pour référence future

**Dernière mise à jour**: 2026-04-23 14:53 UTC
