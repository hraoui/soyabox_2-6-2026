# Package d'Importation de Données POS - Guide d'Intégration

Ce document explique comment réutiliser la logique d'importation des produits, catégories, tables, restaurants, utilisateurs et livreurs dans d'autres projets Flutter.

## 📦 Architecture du Package

### Structure des Fichiers

```
lib/
├── services/
│   ├── api_import_service.dart      # Service principal d'import API
│   ├── database_service.dart        # Abstraction base de données Isar
│   └── image_cache_service.dart     # Cache d'images
├── controllers/
│   └── import_controller.dart       # Contrôleur GetX pour l'UI
├── models/
│   ├── category_model.dart          # Modèle Catégorie
│   ├── product_model.dart           # Modèle Produit
│   ├── restaurant.dart              # Modèle Restaurant
│   ├── user.dart                    # Modèle Utilisateur
│   ├── delivery.dart                # Modèle Livreur
│   └── pos_table.dart               # Modèle Table
└── utils/
    ├── badge_code_utils.dart        # Normalisation badges
    └── image_resolver_shared.dart   # Normalisation images
```

## 🚀 Installation Rapide

### Étape 1: Copier les Fichiers Core

Copiez ces fichiers essentiels dans votre projet :

```bash
# Services
cp SOYABOX_POS-main/lib/services/api_import_service.dart YOUR_PROJECT/lib/services/
cp SOYABOX_POS-main/lib/services/database_service.dart YOUR_PROJECT/lib/services/
cp SOYABOX_POS-main/lib/services/image_cache_service.dart YOUR_PROJECT/lib/services/

# Controllers
cp SOYABOX_POS-main/lib/controllers/import_controller.dart YOUR_PROJECT/lib/controllers/

# Utils
cp SOYABOX_POS-main/lib/utils/badge_code_utils.dart YOUR_PROJECT/lib/utils/
cp SOYABOX_POS-main/lib/utils/image_resolver_shared.dart YOUR_PROJECT/lib/utils/
```

### Étape 2: Ajouter les Dépendances

Dans `pubspec.yaml` :

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  get: ^4.6.6
  
  # HTTP Client
  http: ^1.1.0
  
  # Database
  isar: ^3.1.0+1
  isar_flutter_libs: ^3.1.0+1
  
  # JSON Serialization
  json_annotation: ^4.8.1
  
dev_dependencies:
  build_runner: ^2.4.7
  json_serializable: ^6.7.1
  isar_generator: ^3.1.0+1
```

### Étape 3: Configurer les Models

Assurez-vous que vos models ont cette structure minimale :

#### Category Model (`lib/models/category_model.dart`)

```dart
import 'package:isar/isar.dart';

part 'category_model.g.dart';

@Collection()
class Category {
  Id id = Isar.autoIncrement;
  
  @Index(unique: true)
  late String name;
  
  String? image;
  
  late DateTime createdAt;
  late DateTime updatedAt;
  
  Category({
    required this.name,
    this.image,
    required this.createdAt,
    required this.updatedAt,
  });
}
```

#### Product Model (`lib/models/product_model.dart`)

```dart
import 'package:isar/isar.dart';

part 'product_model.g.dart';

@Collection()
class Product {
  Id id = Isar.autoIncrement;
  
  int? remoteId; // ID du backend
  
  @Index(unique: false)
  late String name;
  
  String? description;
  late double price;
  String? image;
  
  @Index()
  late int categoryId;
  
  bool offer = false;
  bool isAvailable = true;
  int sortOrder = 0;
  
  late DateTime createdAt;
  late DateTime updatedAt;
  
  Product({
    this.remoteId,
    required this.name,
    this.description,
    required this.price,
    this.image,
    required this.categoryId,
    this.offer = false,
    this.isAvailable = true,
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
  });
}
```

#### Restaurant Model (`lib/models/restaurant.dart`)

```dart
import 'package:isar/isar.dart';

part 'restaurant.g.dart';

@Collection()
class Restaurant {
  Id id = Isar.autoIncrement;
  
  int? remoteId;
  
  @Index(unique: true)
  late String name;
  
  String? address;
  String? phone;
  bool isActive = true;
  
  late DateTime createdAt;
  late DateTime updatedAt;
  
  Restaurant({
    this.remoteId,
    required this.name,
    this.address,
    this.phone,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });
}
```

#### User Model (`lib/models/user.dart`)

```dart
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:isar/isar.dart';

part 'user.g.dart';

@Collection()
class User {
  Id id = Isar.autoIncrement;
  
  int? remoteId;
  
  @Index(unique: true)
  late String email;
  
  late String name;
  String? phone;
  late String password;
  String? pinCode;
  String? badgeCode;
  String role = 'staff';
  int? restaurantId;
  bool isActive = true;
  
  late DateTime createdAt;
  late DateTime updatedAt;
  
  User({
    this.remoteId,
    required this.email,
    required this.name,
    this.phone,
    required this.password,
    this.pinCode,
    this.badgeCode,
    this.role = 'staff',
    this.restaurantId,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });
  
  static String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
```

#### Delivery Model (`lib/models/delivery.dart`)

```dart
import 'package:isar/isar.dart';

part 'delivery.g.dart';

@Collection()
class Delivery {
  Id id = Isar.autoIncrement;
  
  int? remoteId;
  
  @Index(unique: true)
  late String email;
  
  late String name;
  String? phone;
  int? restaurantId;
  bool isActive = true;
  
  late DateTime createdAt;
  late DateTime updatedAt;
  
  Delivery({
    this.remoteId,
    required this.email,
    required this.name,
    this.phone,
    this.restaurantId,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });
}
```

#### PosTable Model (`lib/models/pos_table.dart`)

```dart
import 'package:isar/isar.dart';

part 'pos_table.g.dart';

@Collection()
class PosTable {
  Id id = Isar.autoIncrement;
  
  int? remoteId;
  
  @Index(unique: false)
  late String number;
  
  @Index()
  int? restaurantId;
  
  String status = 'available';
  
  int gridColumnStart = 1;
  int gridColumnEnd = 2;
  int gridRowStart = 1;
  int gridRowEnd = 2;
  
  late DateTime createdAt;
  late DateTime updatedAt;
  
  PosTable({
    this.remoteId,
    required this.number,
    this.restaurantId,
    this.status = 'available',
    this.gridColumnStart = 1,
    this.gridColumnEnd = 2,
    this.gridRowStart = 1,
    this.gridRowEnd = 2,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();
}
```

### Étape 4: Générer le Code Isar

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Étape 5: Initialiser dans main.dart

```dart
import 'package:get/get.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import 'services/database_service.dart';
import 'controllers/import_controller.dart';
import 'api/api_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialiser Isar
  final dir = await getApplicationDocumentsDirectory();
  final isar = await Isar.open(
    [
      CategorySchema,
      ProductSchema,
      RestaurantSchema,
      UserSchema,
      DeliverySchema,
      PosTableSchema,
    ],
    directory: dir.path,
  );
  
  // Enregistrer DatabaseService
  Get.put(DatabaseService(isar));
  
  // Enregistrer ApiClient (pour le token)
  Get.put(ApiClient(baseUrl: 'https://votre-api.com'));
  
  // Enregistrer ImportController
  Get.put(ImportController());
  
  runApp(MyApp());
}
```

## 🔧 Configuration

### Configurer l'URL de Base

Dans `lib/data/app_constants.dart` :

```dart
class AppConstant {
  static const String baseUrl = 'https://soyabox.ma';
  // ou pour développement local:
  // static const String baseUrl = 'http://localhost:8000';
}
```

### Configurer l'Authentification

Le service utilise un token Bearer. Configurez-le dans votre `ApiClient` :

```dart
class ApiClient extends GetxService {
  final String baseUrl;
  String _token = '';
  
  ApiClient({required this.baseUrl});
  
  String get token => _token;
  
  void setToken(String token) {
    _token = token;
    // Mettre à jour tous les services
    if (Get.isRegistered<ImportController>()) {
      Get.find<ImportController>().updateApiToken(token);
    }
  }
}
```

## 📖 Utilisation

### Import Complet (Recommandé)

```dart
final importCtrl = Get.find<ImportController>();

try {
  final success = await importCtrl.importAllData();
  
  if (success) {
    Get.snackbar('Succès', 'Toutes les données ont été importées');
  } else {
    Get.snackbar('Erreur', 'Échec de l\'import');
  }
} catch (e) {
  Get.snackbar('Erreur', 'Exception: $e');
}
```

### Import Sélectif

```dart
// Importer uniquement les catégories
await importCtrl.importCategories();

// Importer uniquement les produits
await importCtrl.importProducts();

// Importer les tables d'un restaurant spécifique
await importCtrl.importTables(restaurantId: 1);

// Importer les utilisateurs d'un restaurant
await importCtrl.importUsers(restaurantId: 1);
```

### Avec Progression UI

```dart
Obx(() {
  final ctrl = Get.find<ImportController>();
  
  if (ctrl.isImporting) {
    return Column(
      children: [
        LinearProgressIndicator(value: ctrl.importProgress),
        Text(ctrl.importStatus),
      ],
    );
  }
  
  return ElevatedButton(
    onPressed: () => ctrl.importAllData(),
    child: Text('Importer les Données'),
  );
})
```

## 🎯 Personnalisation

### Adapter les Endpoints API

Si votre backend utilise des routes différentes, modifiez `api_import_service.dart` :

```dart
// Dans ApiImportService

// Par défaut: GET /api/categories
Future<bool> importCategories() async {
  final response = await http.get(
    Uri.parse('$baseUrl/v1/categories'), // ← Modifier ici
    headers: _headers,
  );
  // ...
}

// Par défaut: GET /api/products
Future<bool> importProducts() async {
  final response = await http.get(
    Uri.parse('$baseUrl/api/items'), // ← Modifier ici
    headers: _headers,
  );
  // ...
}
```

### Filtrage par Restaurant

Pour les applications multi-tenant, filtrez par restaurant :

```dart
final authCtrl = Get.find<AuthController>();
final restaurantId = authCtrl.currentUser?.restaurantId;

// Importer uniquement les données du restaurant connecté
await importCtrl.importRestaurants(filterByRestaurantId: restaurantId);
await importCtrl.importTables(restaurantId: restaurantId);
await importCtrl.importUsers(restaurantId: restaurantId);
await importCtrl.importDeliveries(restaurantId: restaurantId);
```

### Gestion des Images Personnalisée

Si vous ne voulez pas de cache d'images, désactivez-le :

```dart
// Dans api_import_service.dart, commenter ces lignes:
// await ImageCacheService.instance.cacheImage(
//   normalizedCategoryImage,
//   baseUrl: baseUrl,
// );
```

## 🐛 Debugging

### Activer les Logs Détaillés

Le service loggue automatiquement chaque étape. Pour voir les logs :

```dart
// Dans votre terminal
flutter run --verbose

// Ou utiliser un logger personnalisé
import 'package:flutter/foundation.dart';

class AppLogger {
  static void i(String message) {
    if (kDebugMode) {
      print('📥 [IMPORT] $message');
    }
  }
}
```

### Vérifier la Connectivité

```dart
final importCtrl = Get.find<ImportController>();
final isConnected = await importCtrl.testConnection();

if (!isConnected) {
  Get.snackbar('Erreur', 'Impossible de se connecter à l\'API');
  return;
}
```

### Diagnostiquer les Échecs

Les erreurs courantes et solutions :

| Erreur | Cause | Solution |
|--------|-------|----------|
| `401 Unauthorized` | Token invalide | Vérifier `updateApiToken()` |
| `404 Not Found` | Endpoint incorrect | Modifier `baseUrl` ou routes |
| `500 Internal Error` | Backend error | Vérifier logs backend |
| `Timeout` | Réseau lent | Augmenter timeout HTTP |
| `Duplicate entry` | Conflit unique index | Vérifier `_asInt()` et mapping IDs |

## 🔄 Séquence d'Import Optimale

L'ordre est important pour maintenir les relations :

```dart
Future<void> importInCorrectOrder() async {
  final ctrl = Get.find<ImportController>();
  
  // 1. Restaurants (source de vérité pour restaurant_id)
  await ctrl.importRestaurants();
  
  // 2. Tables (dépend de restaurants)
  await ctrl.importTables();
  
  // 3. Catégories (indépendant)
  await ctrl.importCategories();
  
  // 4. Produits (dépend de catégories)
  await ctrl.importProducts();
  
  // 5. Utilisateurs (dépend de restaurants)
  await ctrl.importUsers();
  
  // 6. Livreurs (dépend de restaurants)
  await ctrl.importDeliveries();
}
```

## 📊 Formats de Réponse Supportés

Le service gère automatiquement plusieurs formats JSON :

```json
// Format standard
{
  "data": [...]
}

// Format paginé Laravel
{
  "current_page": 1,
  "data": [...],
  "total": 100
}

// Format personnalisé
{
  "success": true,
  "items": [...]
}

// Format imbriqué
{
  "livreurs": {
    "data": [...]
  }
}
```

La méthode `_extractList()` normalise tous ces formats automatiquement.

## 🔐 Sécurité

### Token Management

```dart
// Stocker le token de manière sécurisée
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final storage = FlutterSecureStorage();

// Sauvegarder
await storage.write(key: 'api_token', value: token);

// Récupérer
final token = await storage.read(key: 'api_token');
importCtrl.updateApiToken(token ?? '');
```

### HTTPS Obligatoire en Production

```dart
// NE JAMAIS utiliser HTTP en production
const String baseUrl = kReleaseMode 
    ? 'https://api.production.com'
    : 'http://localhost:8000';
```

## 📝 Exemple Complet

Voici un exemple complet d'écran d'import :

```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/import_controller.dart';

class DataImportScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<ImportController>();
    
    return Scaffold(
      appBar: AppBar(title: Text('Import de Données')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Obx(() {
          if (ctrl.isImporting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(ctrl.importStatus),
                  SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: ctrl.importProgress,
                  ),
                  Text('${(ctrl.importProgress * 100).toInt()}%'),
                ],
              ),
            );
          }
          
          return ListView(
            children: [
              ListTile(
                leading: Icon(Icons.category),
                title: Text('Catégories'),
                trailing: Icon(Icons.download),
                onTap: () => ctrl.importCategories(),
              ),
              ListTile(
                leading: Icon(Icons.inventory),
                title: Text('Produits'),
                trailing: Icon(Icons.download),
                onTap: () => ctrl.importProducts(),
              ),
              ListTile(
                leading: Icon(Icons.restaurant),
                title: Text('Restaurants'),
                trailing: Icon(Icons.download),
                onTap: () => ctrl.importRestaurants(),
              ),
              ListTile(
                leading: Icon(Icons.table_bar),
                title: Text('Tables'),
                trailing: Icon(Icons.download),
                onTap: () => ctrl.importTables(),
              ),
              Divider(),
              ElevatedButton.icon(
                icon: Icon(Icons.cloud_download),
                label: Text('Tout Importer'),
                onPressed: () => ctrl.importAllData(),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
```

## 🎓 Bonnes Pratiques

1. **Toujours tester la connexion avant import**
2. **Importer dans l'ordre de dépendance**
3. **Gérer les erreurs avec try-catch**
4. **Afficher la progression à l'utilisateur**
5. **Logger chaque étape pour debugging**
6. **Valider les données après import**
7. **Permettre l'annulation d'imports longs**
8. **Mettre en cache les images pour performance**
9. **Utiliser le filtrage par restaurant pour multi-tenant**
10. **Tester avec petit dataset avant production**

## 🆘 Support

Pour plus d'informations, consultez :
- Documentation Isar: https://isar.dev
- Documentation GetX: https://github.com/jonataslaw/getx
- Documentation HTTP: https://pub.dev/packages/http

---

**Note**: Ce package est conçu pour être autonome et facilement intégrable. Adaptez les models et endpoints selon votre backend spécifique.
