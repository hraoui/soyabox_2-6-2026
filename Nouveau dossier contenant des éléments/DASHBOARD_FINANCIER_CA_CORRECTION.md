# Dashboard Financier - Correction Calcul du CA ✅

## Problème

**Symptôme :** Le CA (Chiffre d'Affaires) affiché dans le dashboard financier était **inférieur** à celui affiché dans la comptabilité (AdminAccountingScreen).

**Cause Racine :**
Le dashboard financier ne comptabilisait que les commandes **payées** (`paymentStatus == 'paid'`), alors que la comptabilité comptabilise **TOUTES les commandes non annulées** (payées ET non payées).

## Comparaison Avant/Après

### Comptabilité (AdminAccountingScreen) - CORRECT ✅
```dart
// Comptabilité: TOUTES les commandes non annulées
for (final order in orders) {
  final status = order.status.trim().toLowerCase();
  // Exclure uniquement les commandes annulées du CA total
  if (status == 'cancelled' || status == 'canceled') {
    continue;
  }
  totalRevenue += order.totalPrice; // ← TOUTES les commandes non annulées
  
  // Paiements...
}
```

### Dashboard Financier (Avant) - INCORRECT ❌
```dart
for (final order in allOrders) {
  final status = order.status.trim().toLowerCase();
  if (status == 'cancelled' || status == 'canceled') {
    continue;
  }

  // ❌ INCORRECT: Seulement les commandes payées
  if (order.paymentStatus == 'paid') {
    totalRevenue += order.totalPrice; // ← SEULEMENT les payées!
    // ...
  }
}
```

### Dashboard Financier (Après) - CORRECT ✅
```dart
for (final order in allOrders) {
  final status = order.status.trim().toLowerCase();
  if (status == 'cancelled' || status == 'canceled') {
    continue;
  }

  // ✅ CORRECT: TOUTES les commandes non annulées (payées et non payées)
  totalRevenue += order.totalPrice; // ← TOUTES les non annulées

  final channel = order.channel.toLowerCase();
  final fulfillmentType = order.fulfillmentType.toLowerCase();

  // Channel breakdown
  _ordersByChannelCount[channel] =
      (_ordersByChannelCount[channel] ?? 0) + 1;
  _ordersByChannelRevenue[channel] =
      (_ordersByChannelRevenue[channel] ?? 0) + order.totalPrice;

  // ...
}
```

## Ce Qui a Changé

### 1. **CA Total** ✅
**Avant :** Uniquement les commandes avec `paymentStatus == 'paid'`  
**Après :** TOUTES les commandes non annulées (payées ET non payées)

**Impact :** Le CA affiché correspond maintenant à celui de la comptabilité.

### 2. **Breakdown par Channel** ✅
**Avant :** Uniquement les commandes payées  
**Après :** TOUTES les commandes non annulées

**Impact :** Les totaux POS et Web/API sont maintenant corrects.

### 3. **Breakdown par Type** ✅
**Avant :** Uniquement les commandes payées  
**Après :** TOUTES les commandes non annulées

**Impact :** Les totaux on_site, pickup, delivery sont maintenant corrects.

## Règle de Comptabilité

**CA Total = Somme de TOUTES les commandes non annulées**

```
CA = Σ(totalPrice) WHERE status != 'cancelled' AND status != 'canceled'
```

**Peu importe le statut de paiement :**
- ✅ `pending` → Inclus dans le CA
- ✅ `paid` → Inclus dans le CA
- ✅ `partial` → Inclus dans le CA
- ❌ `cancelled` → EXCLUS du CA

## Testing

### Vérifier la Correction

1. **Créer des commandes de test :**
   - 1 commande payée (100 MAD)
   - 1 commande en attente (50 MAD)
   - 1 commande annulée (75 MAD)

2. **Vérifier dans la Comptabilité (AdminAccountingScreen) :**
   - CA Total attendu : **150 MAD** (100 + 50)
   - La commande annulée (75 MAD) doit être exclue

3. **Vérifier dans le Dashboard Financier :**
   - CA Total attendu : **150 MAD** (100 + 50)
   - ✅ Doit correspondre à la comptabilité

### Vérifier les Breakdowns

**Par Channel :**
- POS: X commandes = XXX MAD (toutes non annulées)
- Web/API: X commandes = XXX MAD (toutes non annulées)

**Par Type :**
- On Site: X commandes = XXX MAD (toutes non annulées)
- Pickup: X commandes = XXX MAD (toutes non annulées)
- Delivery: X commandes = XXX MAD (toutes non annulées)

## Notes Importantes

### Différence Entre CA et Revenus Encaissés

- **CA (Chiffre d'Affaires)** = Toutes les commandes non annulées
- **Revenus Encaissés** = Uniquement les commandes payées

Le dashboard affiche le **CA**, pas les revenus encaissés. C'est correct d'un point de vue comptable.

### Pourquoi Inclure les Commandes Non Payées ?

D'un point de vue comptable :
- Une commande confirmée (non annulée) représente un **engagement de paiement**
- Elle fait partie du chiffre d'affaires, même si le paiement n'est pas encore reçu
- Le suivi des impayés se fait séparément ( Aging Report )

## Date
April 10, 2026
