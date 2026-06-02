# 📋 Stratégie de Synchronisation

## ✅ Configuration Finale

### Synchronisation AUTOMATIQUE (Orders uniquement)

| Entité | Sync Auto | Déclencheur | Notes |
|--------|-----------|-------------|-------|
| **Commandes (PosOrder)** | ✅ OUI | - Création commande<br>- Modification statut<br>- Polling 30s<br>- Login utilisateur | Uniquement les commandes POS locales → backend |

### Synchronisation MANUELLE (Via écran "Importer les Données")

| Entité | Sync Auto | Import Manuel | Notes |
|--------|-----------|---------------|-------|
| **Users / Staff** | ❌ NON | ✅ OUI | Via Import Data screen |
| **Restaurants** | ❌ NON | ✅ OUI | Via Import Data screen |
| **Categories** | ❌ NON | ✅ OUI | Via Import Data screen |
| **Products** | ❌ NON | ✅ OUI | Via Import Data screen |
| **Tables** | ❌ NON | ✅ OUI | Via Import Data screen |
| **Delivery Drivers** | ❌ NON | ✅ OUI | Via Import Data screen |

---

## 🔧 Modifications à Appliquer

### 1. ProductController - Désactiver auto-fetch

```dart
// lib/controllers/product_controller.dart
@override
void onInit() {
  super.onInit();
  // ❌ NE PAS charger automatiquement
  // fetchAllProducts(); 
  
  // ✅ Attendre import manuel via Import Data screen
  print('🛍️ [PRODUCT] ProductController initialized (waiting for manual import)');
}

// ✅ Méthode publique pour import manuel
Future<void> fetchAllProducts() async {
  // ... existing code
}
```

### 2. CategoryController - Désactiver auto-fetch

```dart
// lib/controllers/category_controller.dart
@override
void onInit() {
  super.onInit();
  // ❌ NE PAS charger automatiquement
  // fetchAllCategories();
  
  print('📂 [CATEGORY] CategoryController initialized (waiting for manual import)');
}
```

### 3. RestaurantController - Désactiver auto-fetch

```dart
// lib/controllers/restaurant_controller.dart
@override
void onInit() {
  super.onInit();
  // ❌ NE PAS charger automatiquement
  // fetchAllRestaurants();
  
  print('🍽️ [RESTAURANT] RestaurantController initialized (waiting for manual import)');
}
```

### 4. TableController - Désactiver auto-fetch

```dart
// lib/controllers/table_controller.dart
@override
void onInit() {
  super.onInit();
  // ❌ NE PAS charger automatiquement
  // loadTables();
  
  print('🪑 [TABLE] TableController initialized (waiting for manual import)');
}
```

### 5. DeliveryController - Déjà correct

```dart
// lib/controllers/delivery_controller.dart
@override
void onInit() {
  super.onInit();
  // ✅ Déjà correct - ne charge pas automatiquement
  // "Don't auto-fetch deliveries on init"
}
```

---

## 📊 Flux de Synchronisation

### Au Démarrage (Login)

```
1. DatabaseService.init()
2. Seeders (admin users uniquement)
3. Dependency Injection
4. AuthController.login()
   └─> SyncController.startSyncAfterLogin()
       └─> Polling commandes (30s)
       └─> Push commandes vers backend
       └─> Pull commandes API (mobile/web)
```

### Import Manuel (Via "Importer les Données")

```
1. Utilisateur ouvre Import Data screen
2. Configure URL + Token
3. Clique "Importer"
4. ImportController.importAllData()
   ├─> Import Restaurants
   ├─> Import Users/Staff
   ├─> Import Categories
   ├─> Import Products
   └─> Import Tables
5. Données sauvegardées localement (Isar)
6. Affichage dans l'application
```

### Modification Backend

```
1. Admin modifie produit/category/user dans backend
2. Backend met à jour timestamp 'updated_at'
3. Utilisateur ouvre Import Data screen
4. Clique "Réimporter les données"
5. ImportController compare 'updated_at'
6. Met à jour uniquement les éléments modifiés
```

---

## 🎯 Avantages

| Avantage | Description |
|----------|-------------|
| **Performance** | Pas de chargement inutile au démarrage |
| **Contrôle** | L'utilisateur décide quand importer |
| **Réseau** | Réduit la consommation data |
| **Stabilité** | Moins de dépendances au réseau au démarrage |
| **Offline** | Fonctionne 100% offline après import |

---

## ⚠️ Points d'Attention

1. **Premier démarrage** : L'utilisateur DOIT importer les données avant de pouvoir travailler
2. **Écran vide** : Les écrans Products/Categories afficheront "Aucune donnée" jusqu'à l'import
3. **Message d'erreur** : Bien guider l'utilisateur vers "Importer les Données"

---

## 📝 Fichiers à Modifier

- [ ] `lib/controllers/product_controller.dart`
- [ ] `lib/controllers/category_controller.dart`
- [ ] `lib/controllers/restaurant_controller.dart`
- [ ] `lib/controllers/table_controller.dart`
- [ ] `lib/views/import_data_screen.dart` (vérifier qu'il appelle bien les méthodes d'import)
- [ ] `lib/controllers/import_controller.dart` (vérifier qu'il expose toutes les méthodes d'import)
