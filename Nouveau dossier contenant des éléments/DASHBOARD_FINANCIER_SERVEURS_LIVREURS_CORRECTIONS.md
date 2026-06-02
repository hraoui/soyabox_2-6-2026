# Dashboard Financier - Corrections Serveurs et Livreurs ✅

## Problèmes Identifiés

### 1. **Serveurs - Données Incorrectes** ❌

**Problème :**
- Les serveurs ne voyaient QUE les commandes "Web/API Pickup"
- Les commandes POS étaient exclues
- Les commandes Delivery étaient exclues
- Seules les commandes payées étaient comptées pour le revenu

**Résultat :**
- Stats serveurs incomplètes et incorrectes
- Revenus sous-évalués
- Nombre de commandes incorrect

### 2. **Livreurs - Données Incorrectes** ❌

**Problème :**
- Seules les commandes payées étaient comptées
- Les commandes en attente de paiement étaient exclues des stats livreurs

**Résultat :**
- Stats livreurs incomplètes
- Revenus de livraison sous-évalués

## Solutions Implémentées

### 1. **Correction Stats Serveurs** ✅

**Avant (Incorrect) :**
```dart
// ❌ SEULEMENT Web/API Pickup (exclut POS et Delivery)
if (!isDelivery && isApiOrder && isPickup && order.staffId > 0) {
  if (orderExists) {
    if (order.paymentStatus == 'paid') {
      stats.totalRevenue += order.totalPrice;
    }
    stats.orderCount++;
    // ...
  }
}
```

**Après (Correct) :**
```dart
// ✅ TOUTES les commandes (POS + Web/API, tous types)
if (order.staffId > 0) {
  final serverExists = servers.any((s) => s.id == order.staffId);
  if (serverExists) {
    // Count ALL non-cancelled orders for servers
    stats.orderCount++;
    stats.totalRevenue += order.totalPrice;

    // Separate by channel
    if (order.channel.toLowerCase() == 'pos') {
      stats.posRevenue += order.totalPrice;
      stats.posOrders++;
    } else {
      stats.webApiRevenue += order.totalPrice;
      stats.webApiOrders++;
    }

    // Payment method breakdown
    _updatePaymentMethodStats(stats, order);
  }
}
```

**Changements :**
- ✅ TOUTES les commandes assignées au serveur sont comptées
- ✅ POS + Web/API + Delivery (tous les types)
- ✅ Revenu total inclut toutes les commandes non annulées
- ✅ Séparation claire par channel (POS vs Web/API)
- ✅ Détails des paiements (TPE, Cash, En Compte)

### 2. **Correction Stats Livreurs** ✅

**Avant (Incorrect) :**
```dart
// ❌ SEULEMENT les commandes payées
if (order != null && order.paymentStatus == 'paid') {
  stats.totalRevenue += order.totalPrice;
  deliveryOrdersCount++;
  deliveryRevenue += order.totalPrice;
}
```

**Après (Correct) :**
```dart
// ✅ TOUTES les commandes de livraison non annulées
if (order != null) {
  stats.totalRevenue += order.totalPrice;
  deliveryOrdersCount++;
  deliveryRevenue += order.totalPrice;
}
```

**Changements :**
- ✅ TOUTES les commandes de livraison non annulées sont comptées
- ✅ Peu importe le statut de paiement
- ✅ Nombre de livraisons correct
- ✅ Revenu total des livraisons correct

## Structure des Données

### _ServerStats (Après Correction)
```dart
class _ServerStats {
  final int staffId;
  String staffName = 'Inconnu';
  
  int orderCount = 0;               // TOUTES les commandes (POS + Web/API)
  double totalRevenue = 0;          // CA total (toutes non annulées)
  
  double posRevenue = 0;            // CA des commandes POS
  int posOrders = 0;                // Nb commandes POS
  
  double webApiRevenue = 0;         // CA des commandes Web/API
  int webApiOrders = 0;             // Nb commandes Web/API
  
  // Payment breakdown
  double tpeTotal = 0;
  double cashTotal = 0;
  double enCompteTotal = 0;
}
```

### _LivreurStats (Après Correction)
```dart
class _LivreurStats {
  final int livreurId;
  final String livreurName;
  
  int deliveryCount = 0;            // TOUTES les livraisons assignées
  int completedDeliveries = 0;      // Livraisons complétées
  double totalRevenue = 0;          // CA de TOUTES les commandes livrées
}
```

## Règles de Comptabilité

### Serveurs
**Règle :** Compter TOUTES les commandes assignées au serveur (sauf annulées)

```
Server Orders = COUNT(*) WHERE staff_id = X AND status != 'cancelled'
Server Revenue = SUM(totalPrice) WHERE staff_id = X AND status != 'cancelled'
```

**Inclus :**
- ✅ Commandes POS
- ✅ Commandes Web/API Pickup
- ✅ Commandes Web/API Delivery
- ✅ Toutes les commandes non annulées

**Exclus :**
- ❌ Commandes annulées

### Livreurs
**Règle :** Compter TOUTES les livraisons assignées au livreur (sauf annulées)

```
Delivery Count = COUNT(*) WHERE livreur_id = X AND status != 'cancelled'
Delivery Revenue = SUM(totalPrice) WHERE livreur_id = X AND status != 'cancelled'
```

**Inclus :**
- ✅ Toutes les livraisons assignées
- ✅ Peu importe le statut de paiement
- ✅ Toutes les commandes non annulées

**Exclus :**
- ❌ Commandes annulées

## Testing

### Vérifier les Corrections Serveurs

1. **Créer des commandes de test :**
   - 1 commande POS (100 MAD) - staffId=1
   - 1 commande Web/API Pickup (50 MAD) - staffId=1
   - 1 commande Web/API Delivery (75 MAD) - staffId=1
   - 1 commande POS annulée (30 MAD) - staffId=1

2. **Vérifier dans le Dashboard Financier → Onglet Serveurs :**
   - Serveur #1 doit afficher :
     - **3 commandes** (pas 4, car 1 annulée exclue)
     - **CA Total : 225 MAD** (100 + 50 + 75)
     - **POS : 1 commande = 100 MAD**
     - **Web/API : 2 commandes = 125 MAD**

### Vérifier les Corrections Livreurs

1. **Créer des livraisons de test :**
   - 1 livraison assignée au livreur #1 (100 MAD) - payée
   - 1 livraison assignée au livreur #1 (50 MAD) - non payée
   - 1 livraison annulée (75 MAD) - livreur #1

2. **Vérifier dans le Dashboard Financier → Onglet Livreurs :**
   - Livreur #1 doit afficher :
     - **2 livraisons** (pas 3, car 1 annulée exclue)
     - **CA Total : 150 MAD** (100 + 50)
     - Si une livraison est marquée comme "delivered", le compteur "Livraisons complétées" doit être à 1

## Comparaison Avant/Après

### Stats Serveurs

| Métrique | Avant ❌ | Après ✅ |
|----------|---------|---------|
| Commandes POS | ❌ Exclues | ✅ Incluses |
| Commandes Delivery | ❌ Exclues | ✅ Incluses |
| Commandes non payées | ❌ Exclues du CA | ✅ Incluses dans le CA |
| CA Total | ❌ Partiel | ✅ Complet |
| Détails Paiements | ✅ Correct | ✅ Correct |

### Stats Livreurs

| Métrique | Avant ❌ | Après ✅ |
|----------|---------|---------|
| Livraisons non payées | ❌ Exclues | ✅ Incluses |
| CA Total | ❌ Partiel | ✅ Complet |
| Nombre de livraisons | ✅ Correct | ✅ Correct |
| Livraisons complétées | ✅ Correct | ✅ Correct |

## Date
April 10, 2026
