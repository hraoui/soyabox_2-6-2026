# 📊 Table: Comportement des Commandes par Status

## Matrice Complète

| Status | Backend | Requis? | Reçu? | LocalDB? | Notification? | Compte Pending? | Visible UI? |
|--------|---------|---------|-------|----------|---------------|-----------------|-------------|
| **pending** | ✅ | Oui* | ✅ | ✅ | ✅ OUIN | ✅ OUI | ✅ OUI |
| **confirmed** | ✅ | Non** | ✅ | ✅ | ❌ NON | ❌ NON | ✅ OUI |
| **preparing** | ✅ | Non** | ✅ | ✅ | ❌ NON | ❌ NON | ✅ OUI |
| **ready** | ✅ | Non** | ✅ | ✅ | ❌ NON | ❌ NON | ✅ OUI |
| **delivered** | ✅ | Non** | ✅ | ✅ | ❌ NON | ❌ NON | ✅ OUI |
| **cancelled** | ✅ | Non** | ✅ | ✅ | ❌ NON | ❌ NON | ✅ OUI |
| **completed** | ✅ | Non** | ✅ | ✅ | ❌ NON | ❌ NON | ✅ OUI |
| **paid** | ✅ | Non** | ✅ | ✅ | ❌ NON | ❌ NON | ✅ OUI |

*Déclenche notification  
**Inclus dans TOUTES

---

## 🔑 Légende

```
Requis?             = Seulement ce statut est demandé au backend?
Reçu?               = Ce statut est reçu du backend?
LocalDB?            = Ce statut est stocké localement?
Notification?       = Déclenche notification audio?
Compte Pending?     = Comptabilisé dans apiPendingOrdersCount?
Visible UI?         = Visible dans l'interface utilisateur?
```

---

## 📝 Explication Ligne par Ligne

### Pending: ✅ ✅ ✅ ✅ ✅ ✅

```
• Backend: OUI
  → Commande nouvellement créée ou en attente
  
• Requis dans requête: OUI
  → Déclenche notifications → Important
  
• Reçu du backend: OUI
  → Inclus explicitement ET implicitement
  
• Stocké localement: OUI
  → En base de données Isar
  
• Notification audio: OUI
  → playNotificationSound()
  
• Compte pour pending: OUI
  → apiPendingOrdersCount++
  
• Visible en UI: OUI
  → Affiché dans la section "Commandes en attente"
```

### Confirmed: ✅ ❌ ✅ ✅ ❌ ❌ ✅

```
• Backend: OUI
  → Caissier a confirmé la commande
  
• Requis dans requête: NON
  → Pas de filtre « status=confirmed »
  → Mais inclus DANS LES TOUTES commandes
  
• Reçu du backend: OUI
  → Reçu via GET /api/orders (sans filtre)
  
• Stocké localement: OUI
  → Conservé en historique
  
• Notification audio: NON
  → Pas d'intérêt pour le caissier
  
• Compte pour pending: NON
  → apiPendingOrdersCount reste inchangé
  
• Visible en UI: OUI
  → Visible en historique/détails
```

### Ready/Delivered/Cancelled: ✅ ❌ ✅ ✅ ❌ ❌ ✅

```
Même logique que "confirmed":
• Inclus dans TOUTES les commandes du backend
• Pas de notification (pas pending)
• Comptabilisé dans le total, pas en pending
• Visible en historique
```

---

## 🔄 Flux pour Chaque Status

### Scenario 1: Status change (pending → confirmed)

```
Backend API:
order #2001 (status: pending)
    ↓
GET /api/orders → Reçu ✓
    ↓
POS Local: order#100 (status: pending)
    ↓
Caissier confirme
backend: order #2001 (status: changed to confirmed)
    ↓
Next sync (30s later):
GET /api/orders → Reçu (TOUTES incluant confirmed) ✓
    ↓
POS Local: order#100
UPDATE status: confirmed
    ↓
Notification: ❌ (pas pending)
apiPendingOrdersCount: inchangé
```

### Scenario 2: New order (pending)

```
Client web:
New order → Backend (status: pending)
    ↓
GET /api/orders → Reçu ✓
    ↓
POS Local: CREATE order#101 (status: pending)
    ↓
Notification: ✅ JOUÉ
apiPendingOrdersCount: +1
```

### Scenario 3: Cancelled order

```
Backend API:
order #2002 (status: cancelled)
    ↓
GET /api/orders → Reçu ✓
    ↓
POS Local: order#102 (status: cancelled)
    ↓
Notification: ❌
apiPendingOrdersCount: 0
Visible: ✅ (en historique)
```

---

## 🎯 Implication Pratique

### Si le backend filtre par status=pending

```markdown
Backend filtre: GET /api/orders?status=pending

Résultat ATTENDU:
└─ Seulement les commandes pending
   └─ Toutes les autres IGNORÉES

Risque si NOT implémenté:
└─ Les commandes confirmées ne seraient jamais synchronisées
└─ Status local ne suivrait pas le backend
```

### Comportement RÉEL de votre app

```markdown
Pas de filtre status dans la requête GET

Résultat RÉEL:
└─ TOUTES les commandes reçues
   ├─ pending → Notification ✓
   └─ others → Silencieuses ✓

Avantage:
└─ Status local TOUJOURS à jour
└─ Pas de commandes "oubliées"
└─ Historique complet
```

---

## 🔐 Garanties

✅ **Aucune commande n'est perdue**  
✓ Même les non-pending sont récupérées

✅ **Status local = Status backend**  
✓ Toutes les modifications sont reçues

✅ **Notifications intelligentes**  
✓ Uniquement pour pending

✅ **Historique complet**  
✓ Tous les statuses stockés

---

## 📍 Où dans le Code

### Requête (Aucun filtre)

```dart
// lib/services/api_order_pull_service.dart:688-710

final primaryOrdersUri = Uri.parse('$_baseUrl/api/orders').replace(
  queryParameters: {
    'restaurant_id': restaurantId.toString(),
    'per_page': '100',
    'limit': '100',
    'order_by': 'id',
    'direction': 'desc',
    'sort': '-id',
    // ❌ Aucun 'status' ici
  },
);
```

### Traitement (TOUTES les commandes)

```dart
// lib/services/api_order_pull_service.dart:475-530

for (final raw in orders) {  // ← TOUTES!
  
  final status = raw['status'];  // Extraire le status
  final isPending = status == 'pending';
  
  // Synchroniser même si NOT pending
  await _upsertRemoteOrder(raw);
  
  // Notifier SEULEMENT si pending
  if (isPending) {
    playNotificationSound();
    apiPendingOrdersCount++;
  }
}
```

### Comptage (UNIQUEMENT pending)

```dart
// lib/services/api_order_pull_service.dart:595-630

if (isApiOrder && isPending && shouldCountForAudio) {
  apiPendingOrdersCount++;  // ← SEULEMENT pending
  appLogger.i('📱 API Order pending detected: $remoteOrderId');
}

// Return result
return ApiOrderSyncResult(
  changedCount: changedCount,
  newOrdersCount: newOrdersCount,
  updatedOrdersCount: updatedOrdersCount,
  apiPendingOrdersCount: apiPendingOrdersCount,  // ← Pending count
);
```

---

## ✨ Conclusion

Le comportement est **CORRECT et OPTIMISÉ**:

1. **Backend envoie TOUTES** → Aucune perte
2. **Local stocke TOUTES** → Historique complet
3. **Notifications SEULEMENT pending** → UX intelligent
4. **Comptage SEULEMENT pending** → Métrique correcte

**Pas de problème détecté.** ✅
