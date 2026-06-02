# 🚀 Guide Rapide: Diagnostiquer le Problème de Sync des Commandes

## En 3 Étapes Simples

### Étape 1: Ouvrir l'Écran de Diagnostic (30 secondes)

Depuis l'application, exécutez cette commande dans la console Flutter ou ajoutez un bouton temporaire:

```dart
Get.toNamed('/sync-diagnostic');
```

**Ou** modifiez temporairement la route initiale dans `lib/main.dart`:
```dart
initialRoute: '/sync-diagnostic', // Au lieu de '/splash'
```

Puis relancez l'application.

---

### Étape 2: Vérifier les Points Clés

Sur l'écran de diagnostic, vérifiez:

| Point | Ce qu'il faut voir | Si problème |
|-------|-------------------|-------------|
| **Commandes API** | Doit être > 0 si commandes existent sur backend | Si = 0 → Voir Étape 3 |
| **Token disponible** | ✅ OUI | Si ❌ NON → Token manquant |
| **Restaurant ID** | Doit afficher un nombre (ex: 1 ou 2) | Si "Non défini" → Pas connecté avec bon compte |
| **Sync en ligne** | ✅ (vert) | Si ❌ → Problème réseau |
| **Dernière sync** | Date récente (< 2 min) | Si "Jamais" → Sync ne fonctionne pas |

---

### Étape 3: Actions Correctives

#### A. Si Restaurant ID = "Non défini"
**Solution:** Se connecter avec Admin Casablanca ou Admin Mohammedia
- Email: `admin.casablanca@soyabox.com` / PIN: `casa123`
- OU Email: `admin.mohammedia@soyabox.com` / PIN: `moha123`

#### B. Si Token = ❌ NON
**Solution:** Le token par défaut devrait fonctionner. Vérifiez que l'application est lancée normalement.

#### C. Si Commandes API = 0 mais backend a des commandes
**Test:** Vérifiez la connectivité backend:
```bash
curl -X GET "https://soyabox.ma/api/orders?restaurant_id=1" \
  -H "Authorization: Bearer 189a851da7bfc2521cdf172173c6dd7e8418ceabcde5f33ee45797f99858429a"
```

- Si erreur 401 → Token invalide, obtenir nouveau token
- Si erreur 404 → URL incorrecte
- Si timeout → Backend inaccessible

#### D. Si Sync ne se lance jamais
**Vérifier les logs au démarrage:**
```
🔄 [DEP] Creating SyncController...
✅ [DEP] Background sync started
```

Si absent → Problème d'initialisation (rare)

---

### Étape 4: Tester la Synchronisation Manuelle

Dans l'écran de diagnostic, cliquez sur **"Forcer la Synchronisation"**

**Logs attendus:**
```
📡 [API PULL] Pulling API orders for restaurant ID: X
📥 API Order Pull Result: new=X, updated=Y, changed=Z
```

**Si vous voyez:**
- `new=0, updated=0, changed=0` → Aucune commande sur le backend OU restaurant ID incorrect
- Erreur HTTP → Problème de connexion ou token
- `api_pending=X` (X > 0) → Les commandes sont reçues! Vérifiez l'audio maintenant.

---

### Étape 5: Tester l'Audio

Si des commandes pending sont détectées (`api_pending > 0`), le son DOIT se lancer automatiquement.

**Si pas de son:**
1. Vérifier le volume système macOS
2. Vérifier les logs: "❌ Failed to play notification"
3. Vérifier les fichiers audio: `ls assets/audio/`

**Solution rapide:** Ajouter un fichier MP3 dans `assets/audio/order-notification.mp3`

---

## 🎯 Checklist Finale

Après avoir suivi les étapes, vous devriez voir:

- [ ] Restaurant ID défini (> 0)
- [ ] Token disponible (✅ OUI)
- [ ] SyncController en ligne (✅)
- [ ] Dernière sync < 2 minutes
- [ ] Commandes API affichées (si elles existent sur backend)
- [ ] Son joué lors de nouvelles commandes pending

---

## 📞 Besoin d'Aide?

Partagez:
1. Capture d'écran de `/sync-diagnostic`
2. Logs des dernières 30 secondes
3. Résultat du test curl

---

**Temps estimé:** 5-10 minutes  
**Difficulté:** ⭐ Facile