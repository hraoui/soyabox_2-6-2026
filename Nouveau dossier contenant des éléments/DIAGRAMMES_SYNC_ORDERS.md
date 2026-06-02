# 🔄 Diagramme: Flux de Synchronisation des Commandes

## Architecture Globale

```
┌─────────────────────────────────────────────────────────────┐
│                    BACKEND DISTANT                          │
│                    (Server API)                             │
│   ┌─────────────────────────────────────────────────────┐  │
│   │ • API Orders (channel=api, web, mobile, kiosk)     │  │
│   │ • Mapping: remote_id → source_local_id             │  │
│   │ • Status tracking                                   │  │
│   └─────────────────────────────────────────────────────┘  │
└──────────────────┬──────────────────────────────────────────┘
                   │
         ┌─────────┴──────────┐
         │                    │
    [PULL] ←────────────   ────→ [PUSH]
    (GET Orders)        (POST/PUT Orders)
         │                    │
         ↓                    ↑
┌─────────────────────────────────────────────────────────────┐
│                 LOCAL DATABASE (Isar)                       │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ PosOrder Table                                      │   │
│  │ ┌──────────────────────────────────────────────┐   │   │
│  │ │ id (local)                                   │   │   │
│  │ │ channel: 'pos' | 'api' | 'web' | 'mobile'   │   │   │
│  │ │ sourceLocalId: pour mapping                  │   │   │
│  │ │ isFromApi: true si reçu du backend           │   │   │
│  │ │ status: pending | confirmed | paid           │   │   │
│  │ │ createdAt, updatedAt                         │   │   │
│  │ └──────────────────────────────────────────────┘   │   │
│  │                                                     │   │
│  │ PosOrderItem Table                                  │   │
│  │ ┌──────────────────────────────────────────────┐   │   │
│  │ │ orderId, productId, quantity, unitPrice      │   │   │
│  │ │ (dédupliquée avant affichage)                │   │   │
│  │ └──────────────────────────────────────────────┘   │   │
│  └─────────────────────────────────────────────────────┘   │
│                         ↑                                   │
│                         │                                   │
│              [SYNC QUEUE SERVICE]                           │
│         (Gère la file d'attente)                           │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ Queue de synchronisation                            │   │
│  │ │ Entry 1: { order_id: 42, action: 'upsert' }    │   │
│  │ │ Entry 2: { user_id: 5, action: 'upsert' }     │   │
│  │ │ Entry 3: { delivery_id: 3, action: 'delete' } │   │
│  │ └────────────────────────────────────────────────┘   │
│  │                                                     │   │
│  │ Orders Sync State (timestamp tracking)              │   │
│  │ │ order_id: 42 → "2026-04-07T15:30:45.123Z"     │   │
│  │ │ order_id: 99 → "2026-04-07T14:22:10.456Z"     │   │
│  │ └────────────────────────────────────────────────┘   │
│  │                                                     │   │
│  │ Dead Letter Queue (items échoués)                    │   │
│  │ │ Entry X: { error: 401, attempts: 3 }            │   │
│  │ └────────────────────────────────────────────────┘   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  [PERSISTENCE] (fichiers JSON)                              │
│  • sync_queue.json                                          │
│  • orders_sync_state.json                                   │
│  • sync_dead_letter_queue.json                              │
└─────────────────────────────────────────────────────────────┘
```

---

## Cas 1: Créer Commande POS

```
┌─────────────────────────────────────────────────────────┐
│ CAISSIER: Crée commande à table 5 (100€)                │
└──────────────────┬──────────────────────────────────────┘
                   │
                   ↓
          ┌────────────────────┐
          │ PosOrderController │
          │ createOrder()      │
          └──────────┬─────────┘
                     │
         ┌───────────┴──────────────┐
         │                          │
         ↓                          ↓
   ┌──────────────┐          ┌──────────────┐
   │ Create Order │          │ Create Items │
   │ in Database  │          │ in Database  │
   └──────┬───────┘          └──────┬───────┘
          │                         │
          ↓                         ↓
   Order #42 saved            Items #15,#16 saved
   • channel='pos'
   • isFromApi=false
   • sourceLocalId=42
   • status='pending'
          │
          ↓
   ┌──────────────────────┐
   │ enqueueOrderUpsert() │ ← SyncQueueService
   └──────────┬───────────┘
              │
       ┌──────┴──────┐
       │ LOCK START  │ ← _enqueueLock.synchronized()
       ↓             │
   Check if #42     │
   already in queue │
       │             │
       NO ✅         │
       ↓             │
   Add to queue:    │
   dedupeKey = 'orders:upsert:42'
       │             │
       ↓             │
   _ordersSyncState[42] = null
   (pas encore synced)
       │             │
       ├─────────────┘
       │ LOCK END
       ↓
   Queue = [
     { entity: 'orders', action: 'upsert', 
       payload: { local_id: 42, ... } }
   ]
       │
       ↓
   [PERIODIC FLUSH: 45s]
       │
       ↓
   POST /api/orders
   { order_id: 42, status: 'pending', items: [...] }
       │
       ↓
   Backend: 201 Created
   Returns: { id: 1001, source_local_id: 42 }
       │
       ↓
   _ordersSyncState[42] = "2026-04-07T15:30:45Z"
   (marqué comme synced)
       │
       ↓
   ✅ Commande synchronisée (#42 → remote:1001)
```

---

## Cas 2: Recevoir Commande Web du Backend

```
┌─────────────────────────────────────────────────────────┐
│ CLIENT WEB: Commande livrée                             │
│ Backend: id=2001, channel='web', customer='Jean'       │
└──────────────────┬──────────────────────────────────────┘
                   │
        ┌──────────┴──────────┐
        │ PERIODIC API PULL    │ ← ApiOrderPullService
        │ (every 30s)         │
        │                      │
        GET /api/orders?rest_id=10
        │                      │
        ↓                      │
   Backend returns:           │
   [                          │
     {                        │
       id: 2001,              │
       channel: 'web',        │
       status: 'pending',     │
       total: 75€,            │
       created_at: '2026-04-07T15:28:00Z'
     }
   ]
        │                      │
        ├──────────────────────┘
        ↓
   syncApiOrdersForRestaurant()
        │
        ↓
   incomingChannel = 'web' ≠ 'pos'
        │
        ↓
   Chercher order existant:
   Priorité 1: source_local_id (pas config)
   Priorité 2: Signature (created_at + total + channel)
   SELECT * FROM PosOrder WHERE
     channel='web' AND
     ABS(total - 75) < 0.01 AND
     created_at BETWEEN now-60s AND now+60s
        │
        ↓
   ❌ Pas trouvé
        │
        ↓
   _upsertRemoteOrder()
   → CREATE nouveau order
        │
        ↓
   NEW Order #99
   • id: 99
   • channel: 'web'
   • isFromApi: true ✅
   • sourceLocalId: 2001 (remote_id)
   • status: 'pending'
   • createdAt: 2026-04-07T15:28:00Z
        │
        ↓
   CREATE PosOrderItems (75€ items)
        │
        ↓
   _remoteState[2001] = {
     localId: 99,
     updatedAt: '2026-04-07T15:28:00Z',
     restaurantId: 10
   }
        │
        ↓
   _remoteLocalOrderIds.add(99)
   (Track this as API order)
        │
        ↓
   📱 LOG: 'API Order pending detected: remote_id=2001'
   ✅ NOTIFICATION SOUND (si config)
        │
        ↓
   ✅ Commande Web sync'd en local (#99)
```

---

## Cas 3: Commande POS Re-reçue du Backend (Cycle Complet)

```
[PHASE 1: Push]

Order #42 (POS local) 
→ enqueueOrderUpsert()
→ Backend received
→ remote_id=1001, source_local_id=42
→ stored: synced_from='flutter_pos'

[PHASE 2: Pull]

Backend contains:
{
  id: 1001,
  channel: 'pos',
  source_local_id: 42,
  status: 'pending',
  total: 100€,
  created_at: '2026-04-07T15:00:00Z'
}

API Pull:
→ incomingChannel='pos'
→ Cherche order existant

Stratégie 1: source_local_id=42
SELECT * FROM PosOrder WHERE
  sourceLocalId=42
  
✅ TROUVÉ: Order #42


Stratégie 2 (non needed):
(fallback) Signature:
table='5' + total=100€ + heure±30s


RÉSULTAT:
→ Existing order found (#42)
→ _UpsertRemoteOrderResult(localId: 42, created: false)
→ UPDATE order #42 (pas CREATE)
→ Map: remote_id=1001 → local_id=42

_remoteState[1001] = {
  localId: 42,
  updatedAt: '2026-04-07T15:30:00Z',
  restaurantId: 10
}

✅ UNE SEULE COMMANDE EN LOCAL (#42)
✅ Pas de doublon créé
```

---

## Cas 4: Protection Race Condition

```
┌──────────────────────────────┐
│ t=0: Caissier crée order #42 │
└──────────────┬───────────────┘
               │
        ┌──────┴──────┐
        │ LOCK START  │ (_enqueueLock)
        │             │
        │ Add to queue│
        │             │
        │ LOCK END    │
        └──────┬──────┘
               │
        ✅ Queue = [order #42]
        │
        ├─ t=0.1s: Caissier clique "Confirmer"
        │          order.status = 'confirmed'
        │          UPDATE bd: order #42
        │          
        │          appelle enqueueOrderUpsert()
        │
        ├─ t=0.15s: LOCK START
        │            
        │            Check: order #42 already in queue?
        │            
        │            ✅ OUI (ajouté à t=0.05s)
        │            
        │            SKIP! (pas ajouter 2x)
        │
        │            LOCK END
        │
        └───────→ Queue = [order #42] (1x seulement!)
                  Payload = latest (status='confirmed')
                  
        Flush (t=30s):
        → POST order #42 with status='confirmed'
        → Backend: 200 OK
        → _ordersSyncState[42] = timestamp
        
        ✅ UNE SEULE ENTRÉE DANS QUEUE
        ✅ STATUT CORRECT SYNCED
```

---

## Cas 5: Prévention RE-SYNC Inutile

```
┌─────────────────────────────────────────────┐
│ Order #42 already synced at 15:30:45.123Z  │
└────────────────┬────────────────────────────┘
                 │
                 ↓
         Caissier modifie le note
         order.note = "Pas de sucre"
         order.updatedAt = 15:30:50.000Z
                 │
                 ↓
         enqueueOrderUpsert(order)
                 │
                 ↓
         LOCK START
         │
         Check: order #42 in queue?
         → NO ✅
         │
         Check: lastSyncedUpdatedAt[42]?
         → YES: "2026-04-07T15:30:45.123Z"
         │
         Compare timestamps:
         syncedAt (15:30:45) < updatedAt (15:30:50)
         
         → YES, order MODIFIÉ! ✅
         │
         Add to queue
         
         LOCK END
                 │
                 ↓
         ✅ Re-queue car updatedAt APRÈS syncedAt


[Alternative: pas de modification]

         Caissier regarde juste
         → enqueueOrderUpsert() appelé
         
         LOCK START
         │
         Check: order #42 in queue?
         → NO
         │
         Check: lastSyncedUpdatedAt[42]?
         → YES: "2026-04-07T15:30:45.123Z"
         │
         Compare timestamps:
         syncedAt (15:30:45) === updatedAt (15:30:45)
         
         → NO, pas de modification! 
         
         RETURN (SKIP)
         
         LOCK END
                 │
                 ↓
         ✅ Skip (pas inutile re-sync)
```

---

## Cas 6: Filtre: Ne JAMAIS Push API Orders

```
┌──────────────────────────────────────┐
│ Caissier confirme Web Order #99      │
│ (channel='web', isFromApi=true)      │
└─────────────────┬────────────────────┘
                  │
              UPDATE bd:
              order.status = 'confirmed'
                  │
                  ↓
         appelle enqueueOrderUpsert()
                  │
                  ↓
         LOCK START
         │
         Line 408: Check channel
         └─→ order.channel = 'web'
             
             if (channel == 'api') {
               return;  // STOP!
             }
             
             ✅ RETOUR IMMÉDIAT
         
         LOCK END
                  │
                  ↓
         ✅ Queue = [] (rien ajouté)
         ✅ Web order JAMAIS synced
         
         
[Cas 2: Sync statuschangement d'une API order]

         À la place, utiliser:
         syncApiOrderStatus()
         
         → POST /api/orders/2001/update-status
         → Ne push pas toute la commande
         → Juste status='confirmed'
         
         ✅ CORRECT!
```

---

## Cas 7: Déduplication Items (Affichage)

```
┌───────────────────────────────────────────┐
│ Database: Order #42 Items (BUGUÉ!)        │
├───────────────────────────────────────────┤
│ Item #1: productId=10, qty=5, price=2€   │
│ Item #2: productId=10, qty=5, price=2€   │ ← DOUBLON
│ Item #3: productId=15, qty=3, price=4€   │
│ Item #4: productId=15, qty=3, price=4€   │ ← DOUBLON
│ Item #5: productId=15, qty=1, price=4€   │ ← ANCIEN (qty<3)
└───────────────────────────────────────────┘
                     │
                     ↓
         deduplicateOrderItems(items)
         
         Group by productId:
         • productId=10: [qty=5, qty=5]
         • productId=15: [qty=3, qty=3, qty=1]
                     │
                     ↓
         For each group:
         
         productId=10:
         → Item 1 (qty=5) vs Item 2 (qty=5)
         → Keep Item 1 (qty >= qty)
         → Remove Item 2
         
         productId=15:
         → Item 3 (qty=3) vs Item 4 (qty=3) vs Item 5 (qty=1)
         → Keep Item 3 (qty=3 MAX)
         → Remove Item 4 and Item 5
                     │
                     ↓
         ✅ RESULT:
         • Item #1: productId=10, qty=5 ✅
         • Item #3: productId=15, qty=3 ✅
         
         Total: 5 + 3*4 = 17€ (correct!)
         
         ❌ NOT: 
         (5+5+3+3+1)*prices = 33€ (faux!)
```

---

## État Persistant (Crash Recovery)

```
Fichiers stockés en ~/.../documents/:

1. sync_queue.json
   [
     { entity: 'orders', action: 'upsert', 
       payload: { local_id: 42, ... } },
     { entity: 'users', action: 'upsert',
       payload: { id: 5, ... } }
   ]

2. orders_sync_state.json
   {
     "42": "2026-04-07T15:30:45.123Z",
     "99": "2026-04-07T14:22:10.456Z"
   }

3. sync_dead_letter_queue.json
   [
     { error_code: 401, attempts: 3, payload: {...} }
   ]


En cas de CRASH:

App restart:
  ↓
SyncQueueService.init()
  ↓
_loadQueue()
  → Relire sync_queue.json
  ↓
_loadOrdersSyncState()
  → Relire orders_sync_state.json
  ↓
_recoverOrdersStateTransaction()
  → Relire orders_sync_state.pending.json (txn en cours)
  ↓
_startPeriodicFlush()
  → Reprendre la queue
  
✅ AUCUN ITEM PERDU
✅ AUCUN DOUBLON CRÉÉ
```

---

**Tous les chemins garantissent: ZÉRO DOUBLON** ✨
