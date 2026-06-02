# 📅 Synchronisation Automatique - Every 5 Minutes

## ✅ Activé !

La synchronisation automatique des commandes locales vers le backend est maintenant **active** et tourne **toutes les 5 minutes**.

---

## 🔄 Comment ça marche

### 2 Types de Sync en parallèle :

#### 1️⃣ **Sync Continue (toutes les 60 secondes)**
- Utilise `SyncQueueService`
- Envoie les commandes **une par une**
- Temps réel

#### 2️⃣ **Daily Batch Sync (toutes les 5 minutes)** ✨ NOUVEAU
- Utilise `OrderDailySyncRepository`
- Envoie **toutes les commandes du jour en batch**
- Plus efficace pour les grosses quantités

---

## 📊 Workflow Automatique

```
┌─────────────────────────────────────────────┐
│   App démarre                               │
│   ↓                                         │
│   startBackgroundSync()                     │
│   ↓                                         │
│   ┌─────────────────────┐                   │
│   │ Timer 1: 60 secondes│                   │
│   │ SyncQueueService    │                   │
│   │ (commande par cmd)  │                   │
│   └─────────────────────┘                   │
│   ↓                                         │
│   ┌─────────────────────┐                   │
│   │ Timer 2: 5 minutes ⭐│                   │
│   │ Daily Batch Sync    │                   │
│   │ (toutes les cmd)    │                   │
│   └─────────────────────┘                   │
│   ↓                                         │
│   Les 2 tournent en parallle                │
└─────────────────────────────────────────────┘
```

---

## 🎯 Avantages

### ✅ **Automatique**
- Aucune action requise de l'utilisateur
- Tourne en arrière-plan
- Silencieux (pas de notifications)

### ✅ **Intelligent**
- Vérifie si un token est disponible
- Skip si pas de connexion backend
- Retry en cas d'échec

### ✅ **Efficace**
- Batch = moins de requêtes HTTP
- Réduit la charge serveur
- Plus rapide pour beaucoup de commandes

---

## 📝 Logs

Vous verrez ces logs dans la console :

```
📅 [DAILY SYNC] Automatic sync triggered...
📅 [DAILY SYNC] Syncing orders for restaurant 5...
📤 [DailySync] Sending 15 orders batch...
📥 [DailySync] Response received: 200
✅ [DAILY SYNC] Successful: Inserted=15, Skipped=0, Failed=0
✅ [DAILY SYNC] Automatic sync completed
```

Ou si pas de token :

```
⏭️ [DAILY SYNC] No token, skipping automatic sync
```

---

## ⏱️ Configuration

### Intervalle actuel : **5 minutes**

**Pour changer l'intervalle :**

Modifier cette ligne dans `lib/controllers/sync_controller.dart` :

```dart
static const Duration _dailyBatchInterval = Duration(minutes: 5);
```

**Options possibles :**
```dart
Duration(minutes: 1)   // 1 minute
Duration(minutes: 3)   // 3 minutes
Duration(minutes: 5)   // 5 minutes (actuel)
Duration(minutes: 10)  // 10 minutes
Duration(minutes: 15)  // 15 minutes
Duration(minutes: 30)  // 30 minutes
Duration(hours: 1)     // 1 heure
```

---

## 🛑 Arrêter la sync auto

### Temporairement :
```dart
Get.find<SyncController>().stopSync();
```

### Redémarrer :
```dart
Get.find<SyncController>().startBackgroundSync();
```

---

## 🔍 Vérifier que ça marche

### 1. Regarder les logs console
```bash
flutter run | grep "DAILY SYNC"
```

### 2. Vérifier manuellement
```
Admin Dashboard → Local Orders → Voir les badges "Sync" 🟢
```

### 3. Tester immédiatement
```dart
// Dans la console Flutter :
Get.find<SyncController>().triggerDailyBatchSync(showNotifications: true);
```

---

## 📊 Comparaison

| Fonctionnalité | SyncQueueService | Daily Batch Sync |
|---|---|---|
| **Intervalle** | 60 secondes | 5 minutes |
| **Méthode** | Commande par commande | Toutes en batch |
| **Requêtes HTTP** | Nombreuses | 1 seule |
| **Charge serveur** | Plus élevée | Réduite |
| **Réal-time** | ✅ Oui | ❌ Non (5 min) |
| **Efficacité** | Moyenne | ⭐ Excellente |

---

## 🎯 Résultat

Vos commandes sont maintenant synchronisées :

- ✅ **En temps réel** (toutes les 60s via SyncQueue)
- ✅ **En batch** (toutes les 5min via Daily Batch)
- ✅ **Automatiquement** sans intervention
- ✅ **Silencieusement** sans notifications

**Double garantie** que rien ne se perd ! 🎉

---

## 🐛 Troubleshooting

### La sync ne se déclenche pas ?

**Vérifier :**
1. Token disponible : `AuthSessionService.instance.token`
2. Restaurant configuré : `RestaurantController`
3. App pas en background (Flutter peut être suspendu)

### Logs d'erreur ?

```
❌ [DAILY SYNC] Automatic sync failed
```

→ Vérifier la connexion backend et le token

### Les commandes ne sync pas ?

```
Admin Dashboard → Local Orders → Voir "En attente" 🟠
```

→ Cliquer sur "Daily Sync" manuellement pour forcer

---

**Status :** ✅ Production-ready  
**Modifié :** `lib/controllers/sync_controller.dart`  
**Erreurs :** 0
