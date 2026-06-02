# 📋 Page "Local Orders" - Commandes Locales

## 📍 Emplacement
**Fichier :** `lib/views/local_orders_screen.dart`

**Route :** `/local-orders`

**Accès :** Admin Dashboard → Tuile "Local Orders" (icône dossier)

---

## ✨ Fonctionnalités

### 1️⃣ **Statistiques en temps réel**
- **Total** - Nombre total de commandes du jour
- **Synchronisées** - Commandes envoyées au backend (isDailySynced = true)
- **En attente** - Commandes non encore synchronisées

### 2️⃣ **Filtres interactifs**
- **Toutes** - Affiche toutes les commandes du jour
- **Aujourd'hui** - Commandes de la journée actuelle
- **Synchronisées** - Uniquement les commandes sync
- **Non synchronisées** - Commandes en attente de sync

### 3️⃣ **Liste des commandes**
Chaque carte affiche :
- ✅ Numéro de commande (sourceLocalId)
- ✅ Canal (POS, API, Web, Kiosk)
- ✅ Type (on_site, pickup, delivery)
- ✅ Montant total en FCFA
- ✅ Heure et date de création
- ✅ Badge de synchronisation (Sync / En attente)
- ✅ Statut avec icône colorée

### 4️⃣ **Détails expandables**
En cliquant sur une commande :
- Statut détaillé
- Statut de paiement
- Méthode de paiement
- Nom du client
- Téléphone
- Numéro de table
- Notes
- ID du staff
- État de synchronisation

---

## 🎨 Interface

### Barre de statistiques
```
┌──────────────────────────────────────────────────┐
│ [Total: 50] [Sync: 35] [En attente: 15] [Refresh]│
└──────────────────────────────────────────────────┘
```

### Barre de filtres
```
┌──────────────────────────────────────────────────┐
│ Filtres: [Toutes] [Aujourd'hui] [Sync] [Non Sync]│
└──────────────────────────────────────────────────┘
```

### Liste des commandes
```
┌──────────────────────────────────────────────────┐
│ 🟢 CMD #123                        15000 FCFA    │
│ POS - on_site                                     │
│ ⏰ 14:30:25  📅 07/04/2026   [✓ Sync]           │
├──────────────────────────────────────────────────┤
│ [Détails expandables]                             │
└──────────────────────────────────────────────────┘
```

---

## 🚀 Utilisation

### Depuis Admin Dashboard
1. Se connecter en tant qu'**Admin**
2. Naviguer vers **Tableau de bord admin**
3. Cliquer sur la tuile **"Local Orders"** (icône dossier 📁)
4. La page s'ouvre avec toutes les commandes du jour

### Navigation
```
Admin Dashboard → "Local Orders" → Liste complète
```

---

## 🔧 Technique

### Données affichées
- **Source :** Base de données Isar locale
- **Filtre :** Commandes du jour (minuit à minuit)
- **Tri :** Plus récent en premier
- **Restaurant :** Filtré par restaurant de l'admin

### Méthodes principales
```dart
_loadOrders()          // Charge les commandes depuis Isar
_applyFilter()         // Applique le filtre sélectionné
_buildOrderCard()      // Génère une carte de commande
_buildSyncBadge()      // Affiche le badge de sync
```

### Dépendances
- `DatabaseService.getPosOrdersByDateRange()` - Récupération des commandes
- `PosOrder` - Modèle de commande avec champ `isDailySynced`
- `AdminShell` - Shell administratif pour la cohérence UI

---

## 🎯 Cas d'utilisation

### 1. **Vérifier les commandes du jour**
- Voir toutes les commandes créées aujourd'hui
- Compter le nombre total

### 2. **Suivi de synchronisation**
- Identifier les commandes non synchronisées
- Vérifier lesquelles ont été envoyées au backend

### 3. **Recherche d'informations**
- Consulter les détails d'une commande
- Voir le client, la table, le staff, etc.

### 4. **Audit**
- Vérifier l'intégrité des données
- Contrôler les statuts de paiement

---

## 📊 Exemple de données

```
Commande #123
─────────────────────────────
Canal: POS
Type: On Site
Statut: Payée
Paiement: Payé
Méthode: Espèces
Client: Jean Dupont
Téléphone: +243 123 456 789
Table: 5
Montant: 15 000 FCFA
Staff ID: 10
Synchronisé: ✅ Oui
Créée à: 14:30:25
```

---

## 🔄 Workflow avec Daily Sync

1. **Commande créée** dans POS → `isDailySynced = false`
2. **Visible** dans "Local Orders" avec badge orange "En attente"
3. **Daily Sync** exécuté → Commande envoyée au backend
4. **Flag mis à jour** → `isDailySynced = true`
5. **Badge vert** "Sync" affiché
6. **Filtre "Non synchronisées"** ne l'affiche plus

---

## 💡 Astuces

- **Rafraîchir** : Bouton en haut pour recharger les données
- **Filtres rapides** : Cliquer sur les chips pour filtrer
- **Détails** : Cliquer sur une carte pour expandre
- **Navigation** : Retour au dashboard avec le bouton back

---

## 🎨 Couleurs et statuts

| Statut | Couleur | Icône |
|--------|---------|-------|
| En attente | 🟠 Orange | `pending` |
| Confirmée | 🔵 Bleu | `check_circle_outline` |
| En préparation | 🟣 Violet | `restaurant` |
| Prête | 🔵 Cyan | `check` |
| Payée/Livrée | 🟢 Vert | `payment` / `local_shipping` |
| Annulée | 🔴 Rouge | `cancel` |

---

## ✅ Avantages

1. **Visibilité totale** sur les commandes locales
2. **Suivi de sync** en temps réel
3. **Interface intuitive** avec filtres dynamiques
4. **Détails complets** pour chaque commande
5. **Intégration parfaite** avec le Daily Sync

---

## 🔮 Améliorations futures

- [ ] Recherche par numéro de commande
- [ ] Export en CSV
- [ ] Impression de la liste
- [ ] Filtre par serveur/staff
- [ ] Filtre par méthode de paiement
- [ ] Statistiques avancées (CA par méthode, etc.)
- [ ] Sélection multiple pour sync manuelle

---

**Créé le :** 07/04/2026  
**Version :** 1.0  
**Statut :** ✅ Production-ready
