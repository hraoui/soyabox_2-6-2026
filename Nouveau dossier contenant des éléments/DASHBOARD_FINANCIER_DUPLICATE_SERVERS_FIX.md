# Dashboard Financier - Correction Duplicate Serveurs ✅

## Problème

**Symptôme :** L'utilisateur n'a qu'un seul serveur mais en voit DEUX dans l'onglet "Serveurs" du dashboard financier.

**Cause Racine :**
- Les stats serveurs étaient calculées à partir de **TOUS les `staffId` > 0** trouvés dans les commandes
- Certaines commandes peuvent avoir un `staffId` qui ne correspond pas à un serveur actif (ancien staff supprimé, staff par défaut, etc.)
- Le dashboard affichait donc des "Serveur #123" pour ces staffIds orphelins

## Solution Implémentée

### Avant (Incorrect)
```dart
// Per-server stats: ONLY Web/API Pickup (exclude delivery and POS)
if (!isDelivery && isApiOrder && isPickup && order.staffId > 0) {
  serverStatsMap.putIfAbsent(
    order.staffId,
    () => _ServerStats(staffId: order.staffId),
  );
  // ... calculs ...
}
```

**Problème :** Accepte TOUS les `staffId > 0`, même ceux qui n'existent plus dans la table `users`.

### Après (Correct)
```dart
// Per-server stats: ONLY Web/API Pickup (exclude delivery and POS)
if (!isDelivery && isApiOrder && isPickup && order.staffId > 0) {
  // ✅ FILTER: Only count if staffId is in the servers list (active staff)
  final serverExists = servers.any((s) => s.id == order.staffId);
  if (serverExists) {
    serverStatsMap.putIfAbsent(
      order.staffId,
      () => _ServerStats(staffId: order.staffId),
    );
    // ... calculs ...
  }
}
```

**Solution :** Vérifie que le `staffId` de la commande correspond à un serveur actif dans la liste `_servers` (récupérée via `DatabaseService.getUsersByRole('staff')`).

## Comment Ça Marche

1. **Récupération des serveurs actifs :**
   ```dart
   final servers = await DatabaseService.getUsersByRole('staff');
   ```
   Cette ligne récupère TOUS les utilisateurs avec le rôle `'staff'` depuis la base de données.

2. **Filtrage des commandes :**
   ```dart
   final serverExists = servers.any((s) => s.id == order.staffId);
   if (serverExists) {
     // Only process if server exists
   }
   ```
   Pour chaque commande, on vérifie si le `staffId` correspond à un serveur actif.

3. **Résultat :**
   - ✅ Seuls les serveurs actifs apparaissent dans le dashboard
   - ✅ Les commandes avec des `staffId` orphelins sont ignorées pour les stats serveurs
   - ✅ Ces commandes sont TOUJOURS comptées dans le CA total et les autres stats

## Impact

### Avant la Correction
```
Serveurs affichés:
- Serveur #10002 (Ahmed) - 5 commandes - 500 MAD
- Serveur #999 (Inconnu) - 2 commandes - 200 MAD  ← FAUX! Ce serveur n'existe plus
```

### Après la Correction
```
Serveurs affichés:
- Serveur #10002 (Ahmed) - 5 commandes - 500 MAD  ← Seul serveur actif
```

**Note :** Les 2 commandes avec `staffId=999` sont toujours incluses dans :
- ✅ CA Total
- ✅ Stats par channel
- ✅ Stats par type
- ❌ MAIS exclues des stats serveurs (car le serveur n'existe plus)

## Testing

### Vérifier la Correction

1. **Lancer l'application**
2. **Naviguer vers `/financial-dashboard`**
3. **Onglet "Serveurs"** :
   - ✅ Seuls les serveurs actifs (rôle='staff') apparaissent
   - ✅ Pas de "Serveur #XXX" pour des IDs orphelins
   - ✅ Le nombre de serveurs correspond au nombre réel de serveurs dans la base

4. **Vérifier la base de données :**
   ```sql
   SELECT id, name, role FROM users WHERE role = 'staff' AND is_active = 1;
   ```
   Le nombre de résultats doit correspondre au nombre de serveurs affichés dans le dashboard.

## Notes Techniques

### Pourquoi ce Problème Survient-il ?

1. **Suppression de serveurs :** Un serveur a été supprimé mais ses commandes existent toujours
2. **Migration de données :** Anciennes commandes avec des `staffId` qui n'existent plus
3. **Bug antérieur :** Commandes créées avec un `staffId` par défaut ou incorrect

### Solution Alternative (Non Implémentée)

Une autre approche aurait été de nettoyer les données :
```sql
UPDATE orders SET staff_id = NULL WHERE staff_id NOT IN (SELECT id FROM users WHERE role = 'staff');
```

Mais cette approche est plus risquée car elle modifie les données historiques. La solution implémentée (filtrage) est plus sûre et préserve l'intégrité des données.

## Date
April 10, 2026
