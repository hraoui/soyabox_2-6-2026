# Dialog de Paiement Espèces - 2 Étapes avec Récapitulatif

## Problème résolu

Le dialog de paiement en espèces ne permettait pas de :
1. Voir clairement le montant total à payer
2. Saisir le montant donné par le client
3. Voir le reste à retourner avant confirmation
4. Avoir un récapitulatif complet avant de valider

## Solution implémentée

### Nouveau dialog en 2 étapes

**Fichier :** `lib/views/pos_staff_orders_screen.dart`

**Méthode :** `_showCashPaymentDialog(double totalPrice)`

---

## Étape 1 : Saisie du montant donné

### Interface

```
┌─────────────────────────────────────────┐
│ 💰 Paiement en espèces                 │
├─────────────────────────────────────────┤
│ ┌───────────────────────────────────┐  │
│ │ Montant total à payer             │  │
│ │ 250.00 dh                         │  │
│ └───────────────────────────────────┘  │
│                                         │
│ Montant donné par le client (dh)       │
│ ┌─────────────────────────────────┐   │
│ │ 💵 300                          │   │
│ └─────────────────────────────────┘   │
│                                         │
│ ┌───────────────────────────────────┐  │
│ │ 🔄 Reste à retourner              │  │
│ │ 50.00 dh                          │  │
│ └───────────────────────────────────┘  │
│                                         │
│          [Annuler]  [✓ Valider]        │
└─────────────────────────────────────────┘
```

### Fonctionnalités

1. **Affichage du montant total**
   - Zone colorée en orange (couleur de la marque)
   - Police grande et lisible (24px, bold)
   - Positionnée en haut pour visibilité maximale

2. **Champ de saisie du montant donné**
   - `autofocus: true` pour saisie rapide
   - `TextInputType.numberWithOptions(decimal: true)` pour clavier numérique
   - Police 18px, bold pour bonne lisibilité
   - Hint dynamique : "Ex: 250" (basé sur le total)
   - Icône money en préfixe

3. **Calcul en temps réel du rendu**
   - Si montant donné >= total :
     - Affichage vert du reste à retourner
     - Icône `change_circle`
     - Police 22px, bold pour le montant
   - Si montant donné < total :
     - Affichage rouge d'avertissement
     - Icône `warning_amber`
     - Message : "Montant insuffisant (XXX dh)"

4. **Bouton "Valider"**
   - Désactivé si montant insuffisant
   - Activé uniquement si montant >= total
   - Icône check + label "Valider"
   - Couleur orange (marque)

---

## Étape 2 : Récapitulatif avant confirmation

### Interface

```
┌─────────────────────────────────────────┐
│ 📋 Récapitulatif du paiement           │
├─────────────────────────────────────────┤
│ Montant total :        250.00 dh       │
│ ─────────────────────────────────────   │
│ Montant donné :        300.00 dh       │
│                                         │
│ ┌───────────────────────────────────┐  │
│ │ 💳 À retourner au client :        │  │
│ │ 50.00 dh                          │  │
│ └───────────────────────────────────┘  │
│                                         │
│        [Annuler]  [✓ Confirmer]        │
└─────────────────────────────────────────┘
```

### Fonctionnalités

1. **Récapitulatif complet**
   - Montant total de la commande
   - Montant donné par le client
   - Reste à retourner (zone verte mise en évidence)

2. **Mise en page claire**
   - Lignes séparées par un Divider
   - Zone "À retourner" avec fond vert
   - Icône `account_balance_wallet`
   - Police 24px, bold pour le rendu

3. **Confirmation explicite**
   - Bouton "Confirmer le paiement"
   - Couleur verte (validation)
   - Icône `check_circle`

---

## Flux utilisateur complet

```
1. Utilisateur clique sur "Payer"
   ↓
2. Sélection "Espèces"
   ↓
3. Étape 1 - Dialog "Paiement en espèces"
   → Affiche montant total (250 dh)
   → Utilisateur saisit montant donné (300 dh)
   → Calcul automatique du rendu (50 dh)
   → Utilisateur clique sur "Valider"
   ↓
4. Étape 2 - Dialog "Récapitulatif"
   → Affiche :
     - Montant total : 250.00 dh
     - Montant donné : 300.00 dh
     - À retourner : 50.00 dh
   → Utilisateur clique sur "Confirmer"
   ↓
5. Enregistrement du paiement
   → markOrderAsPaid()
   → Libération table (si on_site)
   → Notification de succès
```

---

## Exemples de scénarios

### Scénario 1 : Montant exact
```
Total : 250 dh
Étape 1 :
  → Utilisateur saisit : 250
  → Rend à retourner : 0.00 dh (vert)
  → Utilisateur valide
Étape 2 :
  → Récapitulatif :
    - Total : 250.00 dh
    - Donné : 250.00 dh
    - À retourner : 0.00 dh
  → Utilisateur confirme
```

### Scénario 2 : Avec rendu
```
Total : 250 dh
Étape 1 :
  → Utilisateur saisit : 300
  → Rend à retourner : 50.00 dh (vert)
  → Utilisateur valide
Étape 2 :
  → Récapitulatif :
    - Total : 250.00 dh
    - Donné : 300.00 dh
    - À retourner : 50.00 dh
  → Utilisateur confirme
```

### Scénario 3 : Montant insuffisant
```
Total : 250 dh
Étape 1 :
  → Utilisateur saisit : 200
  → Message rouge : "Montant insuffisant (200.00 dh)"
  → Bouton "Valider" désactivé
  → Utilisateur doit saisir un montant >= 250
```

### Scénario 4 : Annulation
```
Total : 250 dh
Étape 1 :
  → Utilisateur saisit : 300
  → Utilisateur clique sur "Annuler"
  → Retour à l'écran précédent
  → Pas de paiement enregistré
```

---

## Code implémenté

### Méthode `_showCashPaymentDialog`

```dart
Future<double?> _showCashPaymentDialog(double totalPrice) async {
  final amountController = TextEditingController();
  double? amountGiven;

  // Étape 1 : Saisie du montant donné
  final enteredAmount = await showDialog<double>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: const Text('Paiement en espèces'),
        content: Column(
          children: [
            // Montant total à payer (zone orange)
            Container(...),
            
            // Champ de saisie
            TextField(
              controller: amountController,
              autofocus: true,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              onChanged: (value) {
                setDialogState(() {
                  amountGiven = double.tryParse(value) ?? 0;
                });
              },
            ),
            
            // Reste à retourner (zone verte)
            if (amountGiven != null && amountGiven! >= totalPrice) ...[
              Container(
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  children: [
                    Row(children: [Icon(Icons.change_circle), ...]),
                    Text('${(amountGiven! - totalPrice).toStringAsFixed(2)} dh'),
                  ],
                ),
              ),
            ],
            
            // Avertissement (zone rouge)
            if (amountGiven != null && amountGiven! < totalPrice) ...[
              Container(
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [Icon(Icons.warning_amber), ...],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(...), ...),
          ElevatedButton.icon(
            onPressed: amountGiven == null || amountGiven! < totalPrice
                ? null
                : () => Navigator.pop(...),
            icon: Icon(Icons.check),
            label: Text('Valider'),
          ),
        ],
      ),
    ),
  );

  if (enteredAmount == null) return null;

  // Étape 2 : Récapitulatif
  final change = enteredAmount - totalPrice;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (confirmContext) => AlertDialog(
      title: const Text('📋 Récapitulatif du paiement'),
      content: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Montant total :'),
              Text('${totalPrice.toStringAsFixed(2)} dh'),
            ],
          ),
          Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Montant donné :'),
              Text('${enteredAmount.toStringAsFixed(2)} dh'),
            ],
          ),
          // Zone "À retourner"
          Container(
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.account_balance_wallet),
                    SizedBox(width: 8),
                    Text('À retourner au client :'),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  '${change.toStringAsFixed(2)} dh',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(...), ...),
        ElevatedButton.icon(
          onPressed: () => Navigator.pop(...),
          icon: Icon(Icons.check_circle),
          label: Text('Confirmer le paiement'),
        ),
      ],
    ),
  );

  return confirmed == true ? enteredAmount : null;
}
```

---

## Améliorations UX

### 1. StatefulBuilder
- Permet de mettre à jour l'UI en temps réel
- Le rendu se met à jour pendant la saisie
- Bouton "Valider" activé/désactivé dynamiquement

### 2. Couleurs sémantiques
- **Orange** : Marque, montant total
- **Vert** : Validation, rendu à retourner
- **Rouge** : Erreur, montant insuffisant

### 3. Iconographie
- `Icons.money` : Champ de saisie
- `Icons.change_circle` : Rend à retourner
- `Icons.warning_amber` : Erreur
- `Icons.account_balance_wallet` : Récapitulatif
- `Icons.check` / `Icons.check_circle` : Validation

### 4. Tailles de police
- **24px** : Montants importants (total, rendu)
- **18px** : Saisie utilisateur
- **14px** : Labels secondaires
- **12-13px** : Textes d'aide

---

## Fichiers modifiés

1. `lib/views/pos_staff_orders_screen.dart`
   - Remplacement de `_showCashPaymentDialog()`
   - Ajout de l'étape de récapitulatif
   - Amélioration de l'UX avec StatefulBuilder

---

## Tests recommandés

### Test 1 : Paiement avec rendu
1. Créer une commande de 250 dh
2. Cliquer sur "Payer" → "Espèces"
3. Saisir 300 dh
4. Vérifier :
   - ✅ Zone verte "Reste à retourner : 50.00 dh"
   - ✅ Bouton "Valider" activé
5. Cliquer sur "Valider"
6. Vérifier le récapitulatif :
   - ✅ Total : 250.00 dh
   - ✅ Donné : 300.00 dh
   - ✅ À retourner : 50.00 dh
7. Cliquer sur "Confirmer"
8. Vérifier notification de succès

### Test 2 : Montant exact
1. Créer une commande de 250 dh
2. Cliquer sur "Payer" → "Espèces"
3. Saisir 250 dh
4. Vérifier :
   - ✅ Zone verte "Reste à retourner : 0.00 dh"
   - ✅ Bouton "Valider" activé
5. Valider et confirmer

### Test 3 : Montant insuffisant
1. Créer une commande de 250 dh
2. Cliquer sur "Payer" → "Espèces"
3. Saisir 200 dh
4. Vérifier :
   - ✅ Zone rouge "Montant insuffisant (200.00 dh)"
   - ✅ Bouton "Valider" désactivé (gris)
5. Modifier pour 300 dh
6. Vérifier que le bouton "Valider" s'active

### Test 4 : Annulation
1. Créer une commande de 250 dh
2. Cliquer sur "Payer" → "Espèces"
3. Saisir 300 dh
4. Cliquer sur "Annuler"
5. Vérifier :
   - ✅ Retour à l'écran précédent
   - ✅ Commande non marquée comme payée

---

## Avantages

### Pour les utilisateurs
- ✅ Clarté : Montant total bien visible
- ✅ Contrôle : Saisie du montant donné
- ✅ Transparence : Rend à retourner affiché
- ✅ Confirmation : Récapitulatif avant validation

### Pour le business
- ✅ Réduction des erreurs de paiement
- ✅ Meilleure expérience client
- ✅ Processus de paiement fluide
- ✅ Audit trail (2 étapes de validation)
