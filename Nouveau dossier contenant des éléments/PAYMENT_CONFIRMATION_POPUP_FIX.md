# Popup de Paiement avec Confirmation - Écran Serveur

## Problème résolu

Dans l'écran "Mes commandes" des serveurs (`pos_staff_orders_screen.dart`), le bouton "Payer" n'affichait pas de popup de confirmation avec :
- Le montant donné par le client pour le paiement en espèces
- Le reste à retourner
- Une confirmation avant enregistrement

## Solution implémentée

### Nouveau flux de paiement en 4 étapes

**Fichier :** `lib/views/pos_staff_orders_screen.dart`

#### Étape 1 : Sélection du mode de paiement
```dart
// Dialog avec 3 options : TPE, Espèces, En compte
final paymentMethod = await Get.dialog<String>(AlertDialog(...));
```

#### Étape 2 : Pour le paiement en espèces - Saisie du montant donné
```dart
if (paymentMethod == 'cash') {
  amountGiven = await _showCashPaymentDialog(order.totalPrice);
}
```

**Fonctionnalités du dialog espèces :**
- Affiche le montant total de la commande
- Champ de saisie pour le montant donné par le client
- Calcul automatique du reste à retourner
- Affichage en vert du reste à retourner si montant suffisant
- Affichage en rouge d'avertissement si montant insuffisant
- Bouton "Valider" désactivé si montant insuffisant

#### Étape 3 : Confirmation avant enregistrement
```dart
final confirmed = await _showPaymentConfirmationDialog(
  order,
  paymentMethod,
  amountGiven,
);
```

**Informations affichées dans la confirmation :**
- Mode de paiement (icône + libellé)
- Numéro de commande
- Type de commande (Sur place / À emporter / Livraison)
- Montant total
- Montant donné (pour espèces)
- Reste à retourner (pour espèces, en vert)

#### Étape 4 : Enregistrement du paiement
```dart
await pos.markOrderAsPaid(order, paymentMethod);
_notify('Paiement enregistré en $methodName', ...);
```

### Méthodes ajoutées

#### 1. `_showPaymentOptions(PosController pos, PosOrder order)`
Méthode principale qui orchestre le flux de paiement en 4 étapes.

#### 2. `_showCashPaymentDialog(double totalPrice)`
Affiche le dialog pour saisir le montant donné par le client.

**Retourne :** `double?` (le montant donné, ou `null` si annulé)

**Fonctionnalités :**
- Pré-rempli avec le montant total
- Validation en temps réel du montant
- Affichage dynamique du reste à retourner
- Blocage si montant insuffisant

#### 3. `_showPaymentConfirmationDialog(...)`
Affiche le dialog de confirmation avant enregistrement.

**Retourne :** `bool` (`true` si confirmé, `false` si annulé)

**Paramètres :**
- `order` : La commande à payer
- `paymentMethod` : Le mode de paiement sélectionné
- `amountGiven` : Le montant donné (pour espèces)

#### 4. `_confirmationRow(String label, String value, {Color? valueColor})`
Widget helper pour afficher les lignes de la confirmation.

## Interface utilisateur

### Dialog "Paiement en espèces"

```
┌─────────────────────────────────────┐
│ 💰 Paiement en espèces             │
├─────────────────────────────────────┤
│ Montant total : 250.00 dh          │
│                                     │
│ Montant donné par le client (dh)   │
│ ┌─────────────────────────────┐   │
│ │ 💵 260.00                   │   │
│ └─────────────────────────────┘   │
│                                     │
│ ┌─────────────────────────────┐   │
│ │ 🔄 Reste à retourner :      │   │
│ │ 10.00 dh                    │   │
│ └─────────────────────────────┘   │
│                                     │
│        [Annuler]  [Valider]       │
└─────────────────────────────────────┘
```

### Dialog "Confirmation de paiement"

```
┌─────────────────────────────────────┐
│ ✅ Confirmer le paiement           │
├─────────────────────────────────────┤
│ 💵 Paiement par Espèces            │
│ ─────────────────────────────────   │
│ Commande          #123             │
│ Type              Sur place        │
│ Total             250.00 dh        │
│ Montant donné     260.00 dh        │
│ Reste à retourner 10.00 dh (vert)  │
│                                     │
│        [Annuler]  [Confirmer]      │
└─────────────────────────────────────┘
```

## Règles métier

### Commandes éligibles au paiement

**POS :**
- `fulfillmentType == 'on_site'` (Sur place)
- `fulfillmentType == 'pickup'` (À emporter)

**Web/API/Mobile :**
- `fulfillmentType == 'pickup'` (À emporter)
- `status != 'cancelled'`

### Conditions de paiement

- La commande ne doit pas être déjà payée (`paymentStatus != 'paid'`)
- La commande ne doit pas être livrée (`status != 'delivered'`)

### Validation du montant (Espèces)

- Le montant donné doit être >= au montant total
- Si montant insuffisant :
  - Message d'erreur rouge affiché
  - Bouton "Valider" désactivé
- Si montant suffisant :
  - Affichage du reste à retourner en vert
  - Bouton "Valider" activé

## Flux complet

```
1. Utilisateur clique sur "Payer"
   ↓
2. Dialog "Mode de paiement"
   → Sélection : TPE / Espèces / En compte
   ↓
3. Si Espèces → Dialog "Montant donné"
   → Saisie du montant
   → Calcul du reste à retourner
   → Validation si montant suffisant
   ↓
4. Dialog "Confirmation"
   → Affiche tous les détails
   → Confirmation ou annulation
   ↓
5. Enregistrement du paiement
   → markOrderAsPaid()
   → Notification de succès
```

## Exemples

### Exemple 1 : Paiement TPE
```
Total : 250 dh
1. Sélection "TPE"
2. Confirmation directe
3. Validation → Payé
```

### Exemple 2 : Paiement Espèces (montant exact)
```
Total : 250 dh
1. Sélection "Espèces"
2. Saisie : 250 dh
3. Confirmation → Affiche "Reste à retourner : 0.00 dh"
4. Validation → Payé
```

### Exemple 3 : Paiement Espèces (avec rendu)
```
Total : 250 dh
1. Sélection "Espèces"
2. Saisie : 300 dh
3. Confirmation → Affiche "Reste à retourner : 50.00 dh"
4. Validation → Payé
```

### Exemple 4 : Paiement Espèces (montant insuffisant)
```
Total : 250 dh
1. Sélection "Espèces"
2. Saisie : 200 dh
3. Erreur : "Montant insuffisant (200.00 dh)"
4. Bouton "Valider" désactivé
5. Utilisateur doit saisir un montant >= 250 dh
```

## Permissions

- ✅ **Serveurs** : Peuvent enregistrer un paiement
- ✅ **Admins** : Peuvent enregistrer un paiement

## Fichiers modifiés

1. `lib/views/pos_staff_orders_screen.dart`
   - Modification de `_showPaymentOptions()`
   - Ajout de `_showCashPaymentDialog()`
   - Ajout de `_showPaymentConfirmationDialog()`
   - Ajout de `_confirmationRow()`

## Compatibilité

- ✅ Commandes POS (Sur place, À emporter)
- ✅ Commandes Web/API/Mobile (À emporter uniquement)
- ✅ Paiement TPE (Carte bancaire)
- ✅ Paiement Espèces (avec rendu)
- ✅ Paiement En compte (Crédit client)

## Tests recommandés

1. **Paiement TPE**
   - Cliquer sur "Payer"
   - Sélectionner "TPE"
   - Confirmer
   - Vérifier que la commande est marquée comme payée

2. **Paiement Espèces (montant exact)**
   - Cliquer sur "Payer"
   - Sélectionner "Espèces"
   - Saisir le montant exact
   - Confirmer
   - Vérifier le reste à retourner (0.00 dh)

3. **Paiement Espèces (avec rendu)**
   - Cliquer sur "Payer"
   - Sélectionner "Espèces"
   - Saisir un montant supérieur
   - Vérifier le calcul du reste à retourner
   - Confirmer

4. **Paiement Espèces (montant insuffisant)**
   - Cliquer sur "Payer"
   - Sélectionner "Espèces"
   - Saisir un montant inférieur
   - Vérifier le message d'erreur
   - Vérifier que le bouton "Valider" est désactivé

5. **Annulation**
   - Annuler à chaque étape
   - Vérifier que la commande n'est pas marquée comme payée

6. **Commandes non éligibles**
   - Vérifier que le bouton "Payer" n'apparaît pas pour :
     - Les commandes déjà payées
     - Les commandes livrées
     - Les commandes de livraison (fulfillmentType == 'delivery')
     - Les commandes annulées
