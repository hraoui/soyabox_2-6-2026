# Bouton "Assigner un livreur" dans les commandes serveur

## Problème résolu

Dans l'écran des commandes serveur (`pos_staff_orders_screen.dart`), il n'y avait pas de bouton pour assigner un livreur aux commandes de livraison. Les serveurs ne pouvaient pas assigner de livreur directement depuis la carte de commande.

## Solution implémentée

### 1. Ajout du bouton "Assigner un livreur" dans la carte de commande

**Fichier :** `lib/views/pos_staff_orders_screen.dart`

**Emplacement :** Dans `_orderCard()`, après les boutons "Détails" et "Imprimer"

```dart
// ✅ Bouton Assigner un livreur (pour les commandes de livraison)
if (order.fulfillmentType == 'delivery')
  _actionButtonCompact(
    icon: Icons.person_add_outlined,
    label: order.deliveryLivreurId != null
        ? 'Changer livreur'
        : 'Assigner livreur',
    color: order.deliveryLivreurId != null
        ? Colors.teal.shade700
        : Colors.orange.shade700,
    onTap: () => _showAssignLivreurDialog(pos, order),
  ),
```

**Fonctionnalités :**
- Le bouton n'apparaît que pour les commandes de livraison (`fulfillmentType == 'delivery'`)
- Le label change selon qu'un livreur est déjà assigné ou non
- La couleur change pour indiquer l'état :
  - Orange : Aucun livreur assigné
  - Teal (vert bleuté) : Livreur déjà assigné

### 2. Affichage du livreur assigné dans la carte

**Ajout d'un badge** dans l'en-tête de la carte quand un livreur est assigné :

```dart
// ✅ Afficher le livreur assigné pour les livraisons
if (order.fulfillmentType == 'delivery' &&
    order.deliveryLivreurId != null) ...[
  const SizedBox(height: 6),
  Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
    decoration: BoxDecoration(
      color: Colors.teal.shade50.withAlpha(100),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: Colors.teal.shade700, width: 1),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.assignment_ind, size: 10, color: Colors.teal.shade700),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            order.deliveryLivreurName ?? 'Livreur assigné',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: Colors.teal.shade700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  ),
],
```

**Visuel :**
- Badge vert bleuté avec icône
- Affiche le nom du livreur
- Ellipsis si le nom est trop long

### 3. Modification du dialog d'assignation

**Fichier :** `lib/views/pos_staff_orders_screen.dart`

**Méthode :** `_showAssignLivreurDialog()`

**Changement :** Utilisation de `assignLivreurToDelivery()` au lieu de `assignLivreurToOrder()`

```dart
// Utiliser assignLivreurToDelivery pour les serveurs et admins
final result = await pos.assignLivreurToDelivery(
  order: order,
  livreurId: selectedLivreurId!,
  livreurName: selectedLivreurName,
  livreurPhone: selectedLivreurPhone,
);
```

**Pourquoi :**
- `assignLivreurToOrder()` est réservé aux admins
- `assignLivreurToDelivery()` est accessible par les serveurs, livreurs et admins
- Permet d'assigner un livreur même si la commande est `pending`

## Interface utilisateur

### Avant
```
┌─────────────────────────────────────┐
│ 🚚 #123  [En attente]              │
│ 👤 Jean Dupont                     │
│ 📞 06 12 34 56 78                  │
│ 📍 123 Rue de la Paix              │
│ ⏰ 14:30                           │
│                             250dh  │
│                          [Non payée]│
├─────────────────────────────────────┤
│ [Détails] [Imprimer] [Confirmer]   │
└─────────────────────────────────────┘
```

### Après
```
┌─────────────────────────────────────┐
│ 🚚 #123  [En attente]              │
│ 👤 Jean Dupont                     │
│ 📞 06 12 34 56 78                  │
│ 📍 123 Rue de la Paix              │
│ ⏰ 14:30                           │
│ [✓] Mohamed - Livreur              │  ← Nouveau badge
│                             250dh  │
│                          [Non payée]│
├─────────────────────────────────────┤
│ [Détails] [Imprimer]               │
│ [Changer livreur] [Confirmer]      │  ← Nouveau bouton
└─────────────────────────────────────┘
```

## Flux d'utilisation

1. **Serveur voit une commande de livraison sans livreur**
   - Bouton orange "Assigner livreur" visible
   - Aucun badge de livreur

2. **Serveur clique sur "Assigner livreur"**
   - Dialog s'ouvre avec la liste des livreurs disponibles
   - Serveur sélectionne un livreur
   - Validation

3. **Livreur assigné**
   - Badge vert bleuté apparaît avec le nom du livreur
   - Bouton change à "Changer livreur" (couleur teal)

4. **Serveur peut changer le livreur**
   - Clique sur "Changer livreur"
   - Sélectionne un nouveau livreur
   - Mise à jour immédiate

## Permissions

- ✅ **Serveurs** : Peuvent assigner/changer un livreur
- ✅ **Livreurs** : Peuvent s'assigner eux-mêmes
- ✅ **Admins** : Peuvent assigner/changer un livreur

## Fichiers modifiés

1. `lib/views/pos_staff_orders_screen.dart`
   - Ajout du bouton "Assigner un livreur" dans `_orderCard()`
   - Ajout du badge de livreur assigné
   - Modification de `_showAssignLivreurDialog()` pour utiliser `assignLivreurToDelivery()`

## Compatibilité

- ✅ Commandes de livraison (fulfillmentType == 'delivery')
- ✅ Tous les canaux (POS, API, Web, Mobile)
- ✅ Tous les statuts (sauf `cancelled`)
- ✅ Serveurs, livreurs et admins

## Tests recommandés

1. **Commande sans livreur**
   - Vérifier que le bouton "Assigner livreur" apparaît
   - Vérifier qu'aucun badge n'est affiché

2. **Assignation d'un livreur**
   - Cliquer sur "Assigner livreur"
   - Sélectionner un livreur
   - Vérifier que le badge apparaît
   - Vérifier que le bouton change à "Changer livreur"

3. **Changement de livreur**
   - Cliquer sur "Changer livreur"
   - Sélectionner un nouveau livreur
   - Vérifier que le badge se met à jour

4. **Permissions**
   - Tester avec un compte serveur
   - Tester avec un compte livreur
   - Tester avec un compte admin
