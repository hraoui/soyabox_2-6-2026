# 📌 RÉSUMÉ: Status des Commandes Backend

## ❌ FAUX

```
❌ "Les commandes reçues du backend sont UNIQUEMENT 
    les commandes avec status='pending'"
```

## ✅ VRAI

```
✅ Le backend envoie TOUTES les commandes
   (toutes les statuses: pending, confirmed, paid, etc.)

✅ La requête API n'a PAS de filtre "status=pending"

✅ SEULEMENT les commandes "pending" 
   → Déclenchent notifications audio
   → Comptent pour apiPendingOrdersCount

✅ Les autres statuses sont AUSSI synchronisées en local
   → Stockées dans la DB
   → Visibles en historique
   → Pas de notification
```

---

## 📊 Diagramme Simplifié

```
Backend (100 commandes)
├─ 20 pending      ✅ Reçues + Notifiées
├─ 30 confirmed    ✅ Reçues + Pas notifiées
├─ 25 paid         ✅ Reçues + Pas notifiées
├─ 15 ready        ✅ Reçues + Pas notifiées
├─ 7 cancelled     ✅ Reçues + Pas notifiées
└─ 3 delivered     ✅ Reçues + Pas notifiées
        │
        ↓
GET /api/orders
(AUCUN filtre status)
        │
        ↓
Local Database (100 commandes aussi)
├─ 20 pending      → Notification ✓
├─ 30 confirmed    → Pas notification
├─ 25 paid         → Pas notification
├─ 15 ready        → Pas notification
├─ 7 cancelled     → Pas notification
└─ 3 delivered     → Pas notification

apiPendingOrdersCount = 20 (pending UNIQUEMENT)
```

---

## 🔑 Points Clés

### Query Parameters (Aucun filtre status)

```dart
final primaryOrdersUri = Uri.parse('$_baseUrl/api/orders').replace(
  queryParameters: {
    'restaurant_id': restaurantId.toString(),  ← Restaurant UNIQUEMENT
    'per_page': '100',
    'limit': '100',
    'order_by': 'id',
    'direction': 'desc',
    'sort': '-id',
    // ❌ PAS DE: 'status': 'pending'
    // ❌ PAS DE: 'status[]': 'pending'
    // ❌ PAS DE FILTRE AUCUN
  },
);
```

### Logique (Tous les statuses synced)

```dart
for (final raw in orders) {  // ← TOUTES les commandes
  final status = raw['status'];
  
  // SYNCHRONISER même si status != pending
  await _upsertRemoteOrder(raw);
  
  // SEULEMENT compter si pending
  if (status == 'pending') {
    apiPendingOrdersCount++;  // ← COUNTER UNIQUEMENT
  }
}
```

---

## 💼 Cas d'Usage Réel

### 1️⃣ Nouveau client commande (pending)
```
Backend: Order #2001, status=pending
    ↓
POS sync: Reçu ✓
    ↓
Local DB: Stored
    ↓
Notification audio: ✓ JOUÉ
    ↓
apiPendingOrdersCount: +1
```

### 2️⃣ Client paye en ligne (pending → paid)
```
Backend: Order #2001, status=paid (modifié)
    ↓
POS sync: Reçu ✓ (INCLUS DANS TOUTES)
    ↓
Local DB: UPDATE status=paid
    ↓
Notification audio: ✗ SILENCIEUX
    ↓
apiPendingOrdersCount: 0 (pas pending)
```

### 3️⃣ Commande prête (pending → ready)
```
Backend: Order #2001, status=ready (modifié)
    ↓
POS sync: Reçu ✓ (INCLUS DANS TOUTES)
    ↓
Local DB: UPDATE status=ready
    ↓
Notification audio: ✗ SILENCIEUX
    ↓
apiPendingOrdersCount: 0 (pas pending)
```

---

## 🎯 Garanties

✅ **Toutes les commandes sont synchronisées**  
✅ **Y compris celles avec status != pending**  
✅ **Seules les "pending" font sonner l'audio**  
✅ **Pas de commandes perdues ou filtrées**  
✅ **Historique complet en local**  

---

**Code Source:**
- Requête: `lib/services/api_order_pull_service.dart` ligne 688-755
- Logique: `lib/services/api_order_pull_service.dart` ligne 475-650
- Filtre: `lib/services/api_order_pull_service.dart` ligne 519-521

**Conclusion:** Le backend envoie TOUT. Le client en local filtre INTELLIGEMMENT.
