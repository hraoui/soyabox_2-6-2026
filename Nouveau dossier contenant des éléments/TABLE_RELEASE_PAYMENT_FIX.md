# Libération de Table et Mise à Jour UI après Paiement

## Problèmes résolus

1. **Erreur ScaffoldMessenger** : `ScaffoldMessenger.showSnackBar was called, but there are currently no descendant Scaffolds to present to`
2. **Table non libérée** : Les tables "on_site" n'étaient pas libérées après paiement
3. **UI non mise à jour** : L'interface ne se mettait pas à jour immédiatement après paiement

## Solutions implémentées

### 1. Correction de l'erreur ScaffoldMessenger

**Fichier :** `lib/views/pos_screen.dart`

**Problème :** Dans `_showCustomerSelectionDialog`, le `context` utilisé pour `ScaffoldMessenger` était celui du dialog, pas le contexte parent.

**Solution :** Utiliser `this.context` (le contexte du widget parent) au lieu de `context` (le contexte du dialog).

```dart
// AVANT (dans le dialog)
ScaffoldMessenger.of(context).showSnackBar(...)

// APRÈS
ScaffoldMessenger.of(this.context).showSnackBar(...)
```

**Explication :**
- `context` dans le builder du dialog pointe vers le contexte du dialog
- `this.context` pointe vers le contexte du widget `_PosScreenState` qui contient le Scaffold
- Le ScaffoldMessenger doit être appelé avec le contexte qui contient le Scaffold

### 2. Libération de table après paiement

**Fichier :** `lib/controllers/pos_controller.dart`

**Méthode modifiée :** `markOrderAsPaid()`

```dart
Future<void> markOrderAsPaid(PosOrder order, String paymentMethod) async {
  final normalized = normalizePaymentMethod(paymentMethod);
  order.paymentMethod = normalized.isEmpty ? paymentMethod : normalized;
  order.paymentStatus = 'paid';
  order.updatedAt = DateTime.now();
  
  // Libérer la table pour les commandes "on_site"
  if (order.fulfillmentType == 'on_site' && order.tableNumber != null) {
    await markTableFree(order.tableNumber!);
    appLogger.d('🔓 [TABLE FREE] Table ${order.tableNumber} libérée...');
  }
  
  await DatabaseService.updatePosOrder(order);
  
  // Mettre à jour l'UI immédiatement
  update();
  
  // Recharger les commandes pour afficher l'état mis à jour
  await loadOrdersToday();
  
  appLogger.i('✅ [PAYMENT] Commande #${order.id} marquée comme payée');
}
```

**Fonctionnalités :**
- Libère automatiquement la table après paiement pour les commandes "on_site"
- Met à jour l'UI immédiatement avec `update()`
- Recharge les commandes avec `loadOrdersToday()` pour afficher l'état mis à jour
- Log l'action pour le débogage

### 3. Mise à jour UI immédiate avec notification de succès

**Fichier :** `lib/views/pos_staff_orders_screen.dart`

**Méthode modifiée :** `_showPaymentOptions()`

```dart
// Étape 4 : Enregistrer le paiement
final methodName = paymentMethodLabel(paymentMethod);

// Afficher un indicateur de chargement
_notify(
  'Traitement du paiement...',
  title: 'Paiement en cours',
  type: POSSnackType.info,
);

await pos.markOrderAsPaid(order, paymentMethod);

if (!mounted) return;

// Notification de succès avec détails
String successMessage = 'Paiement enregistré en $methodName';
if (amountGiven != null) {
  final change = amountGiven - order.totalPrice;
  if (change > 0) {
    successMessage += ' (Rendu : ${change.toStringAsFixed(2)} dh)';
  }
}

_notify(
  successMessage,
  title: '✅ Paiement validé',
  type: POSSnackType.success,
);
```

**Fonctionnalités :**
- Notification "Paiement en cours" avant l'enregistrement
- Notification de succès avec :
  - Mode de paiement
  - Montant du rendu (pour espèces)
- Emoji ✅ pour une meilleure visibilité
- L'UI se met à jour automatiquement grâce à `loadOrdersToday()`

## Flux complet de paiement

### Pour les commandes "on_site" (Sur place)

```
1. Utilisateur clique sur "Payer"
   ↓
2. Sélection du mode de paiement (TPE / Espèces / En compte)
   ↓
3. Si Espèces → Saisie du montant donné + calcul du rendu
   ↓
4. Confirmation du paiement
   ↓
5. Notification "Paiement en cours..."
   ↓
6. markOrderAsPaid() exécute :
   → Met à jour paymentStatus = 'paid'
   → Libère la table (markTableFree)
   → Met à jour la base de données
   → Appelle update() pour l'UI
   → Appelle loadOrdersToday() pour rafraîchir
   ↓
7. Notification "✅ Paiement validé" (+ rendu si espèces)
   ↓
8. L'UI affiche :
   → Commande marquée comme "Payée"
   → Table libérée (disponible pour nouvelle commande)
```

### Pour les autres types de commandes

**Pickup (À emporter) et Delivery (Livraison) :**
- Même flux, mais sans libération de table
- Mise à jour UI immédiate
- Notification de succès

## Exemples de notifications

### Paiement TPE (montant exact)
```
┌─────────────────────────────────┐
│ ℹ️ Paiement en cours            │
│ Traitement du paiement...       │
└─────────────────────────────────┘

↓ Après validation

┌─────────────────────────────────┐
│ ✅ Paiement validé              │
│ Paiement enregistré en TPE      │
└─────────────────────────────────┘
```

### Paiement Espèces (avec rendu)
```
┌─────────────────────────────────┐
│ ℹ️ Paiement en cours            │
│ Traitement du paiement...       │
└─────────────────────────────────┘

↓ Après validation

┌─────────────────────────────────┐
│ ✅ Paiement validé              │
│ Paiement enregistré en Espèces  │
│ (Rendu : 50.00 dh)              │
└─────────────────────────────────┘
```

### Paiement On_site (avec libération de table)
```
┌─────────────────────────────────┐
│ ℹ️ Paiement en cours            │
│ Traitement du paiement...       │
└─────────────────────────────────┘

↓ Après validation

┌─────────────────────────────────┐
│ ✅ Paiement validé              │
│ Paiement enregistré en TPE      │
└─────────────────────────────────┘

Log console :
🔓 [TABLE FREE] Table 5 libérée après paiement de la commande #123
✅ [PAYMENT] Commande #123 marquée comme payée (method: tpe)
```

## Mise à jour UI immédiate

### Avant
- La commande restait affichée comme "Non payée"
- La table restait occupée
- Il fallait rafraîchir manuellement

### Après
- La commande passe immédiatement à "Payée"
- La table est libérée et disponible
- L'UI se rafraîchit automatiquement
- Notification de succès visible

## Fichiers modifiés

1. `lib/views/pos_screen.dart`
   - Correction de `ScaffoldMessenger.of(context)` → `ScaffoldMessenger.of(this.context)`

2. `lib/controllers/pos_controller.dart`
   - Ajout de la libération de table dans `markOrderAsPaid()`
   - Ajout de `loadOrdersToday()` pour rafraîchir l'UI
   - Ajout de logs pour le débogage

3. `lib/views/pos_staff_orders_screen.dart`
   - Ajout de la notification "Paiement en cours"
   - Amélioration de la notification de succès
   - Affichage du rendu pour le paiement espèces

## Compatibilité

- ✅ Commandes "on_site" (Sur place) - Libération de table
- ✅ Commandes "pickup" (À emporter)
- ✅ Commandes "delivery" (Livraison)
- ✅ Paiement TPE (Carte bancaire)
- ✅ Paiement Espèces (avec rendu)
- ✅ Paiement En compte (Crédit client)

## Tests recommandés

### Test 1 : Paiement On_site avec libération de table
1. Créer une commande "Sur place" pour la Table 5
2. Payer la commande (TPE ou Espèces)
3. Vérifier :
   - ✅ Notification "Paiement validé"
   - ✅ Commande marquée comme "Payée"
   - ✅ Table 5 libérée (disponible dans l'écran des tables)
   - ✅ Log console : "🔓 [TABLE FREE] Table 5 libérée"

### Test 2 : Paiement Pickup
1. Créer une commande "À emporter"
2. Payer la commande
3. Vérifier :
   - ✅ Notification "Paiement validé"
   - ✅ Commande marquée comme "Payée"
   - ✅ Pas de libération de table (normal)

### Test 3 : Paiement Espèces avec rendu
1. Créer une commande de 250 dh
2. Payer avec 300 dh
3. Vérifier :
   - ✅ Notification avec "Rendu : 50.00 dh"
   - ✅ Calcul correct du rendu

### Test 4 : Correction ScaffoldMessenger
1. Ouvrir l'écran POS
2. Créer une commande Livraison
3. Saisir les infos client
4. Valider avec un champ vide
5. Vérifier :
   - ✅ Pas d'erreur ScaffoldMessenger
   - ✅ SnackBar s'affiche correctement

## Logs de débogage

Après paiement, vérifier dans la console :

```
🔓 [TABLE FREE] Table 5 libérée après paiement de la commande #123
✅ [PAYMENT] Commande #123 marquée comme payée (method: tpe)
📊 [LOAD ORDERS] Total BDD: X, restId=Y, staffId=Z
```
