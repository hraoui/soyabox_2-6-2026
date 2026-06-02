# POS Data Importer Package

A reusable Flutter package for importing POS (Point of Sale) data from a backend API. This package provides services and controllers to synchronize products, categories, tables, restaurants, users, and deliveries between your backend and local Isar database.

## Features

- ✅ Import categories with image caching
- ✅ Import products with category mapping
- ✅ Import restaurants with filtering support
- ✅ Import tables with grid layout positions
- ✅ Import users with password hashing
- ✅ Import delivery personnel
- ✅ Progress tracking and status updates
- ✅ Automatic ID mapping (remote ↔ local)
- ✅ Upsert logic (create or update)
- ✅ Multi-tenant support (filter by restaurant_id)
- ✅ GetX state management integration
- ✅ Comprehensive error handling and logging

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  pos_data_importer:
    git:
      url: https://github.com/your-org/pos_data_importer.git
      ref: main
```

Or use a local path:

```yaml
dependencies:
  pos_data_importer:
    path: ../pos_data_importer
```

Then run:

```bash
flutter pub get
```

## Quick Start

### 1. Initialize in main.dart

```dart
import 'package:get/get.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pos_data_importer/pos_data_importer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Isar
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
  
  // Register services
  Get.put(DatabaseService(isar));
  Get.put(ApiClient(baseUrl: 'https://your-api.com'));
  Get.put(ImportController());
  
  runApp(MyApp());
}
```

### 2. Use in Your App

```dart
import 'package:get/get.dart';
import 'package:pos_data_importer/pos_data_importer.dart';

class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final importCtrl = Get.find<ImportController>();
    
    return ElevatedButton(
      onPressed: () async {
        try {
          await importCtrl.importAllData();
          Get.snackbar('Success', 'All data imported!');
        } catch (e) {
          Get.snackbar('Error', 'Import failed: $e');
        }
      },
      child: Text('Import Data'),
    );
  }
}
```

### 3. Show Progress

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
  
  return SizedBox.shrink();
})
```

## API Configuration

### Set Base URL

```dart
// Option 1: In ApiClient
Get.put(ApiClient(baseUrl: 'https://api.yourdomain.com'));

// Option 2: Update dynamically
final importCtrl = Get.find<ImportController>();
importCtrl.updateBaseUrl('https://new-api.com');
```

### Set Authentication Token

```dart
// After login
final apiClient = Get.find<ApiClient>();
apiClient.setToken(userToken);

// Or directly
importCtrl.updateApiToken(userToken);
```

## Import Methods

### Import All Data

```dart
await importCtrl.importAllData();
```

This imports in the correct order:
1. Restaurants
2. Tables
3. Categories
4. Products
5. Users
6. Deliveries

### Import Specific Entities

```dart
// Import only categories
await importCtrl.importCategories();

// Import only products
await importCtrl.importProducts();

// Import tables for specific restaurant
await importCtrl.importTables(restaurantId: 1);

// Import users for specific restaurant
await importCtrl.importUsers(restaurantId: 1);

// Import deliveries for specific restaurant
await importCtrl.importDeliveries(restaurantId: 1);
```

### Test Connection

```dart
final isConnected = await importCtrl.testConnection();
if (!isConnected) {
  print('Cannot connect to API');
}
```

## Required Models

The package expects these models with Isar annotations:

### Category

```dart
@Collection()
class Category {
  Id id = Isar.autoIncrement;
  
  @Index(unique: true)
  late String name;
  
  String? image;
  late DateTime createdAt;
  late DateTime updatedAt;
}
```

### Product

```dart
@Collection()
class Product {
  Id id = Isar.autoIncrement;
  int? remoteId;
  
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
}
```

### Restaurant

```dart
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
}
```

### User

```dart
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
  
  static String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
```

### Delivery

```dart
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
}
```

### PosTable

```dart
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
}
```

## Expected API Endpoints

Your backend should provide these endpoints:

```
GET /api/categories
GET /api/products
GET /api/restaurants?restaurant_id=X
GET /api/tables?restaurant_id=X
GET /api/users?restaurant_id=X
GET /api/deliveries?restaurant_id=X
POST /api/tables
PUT /api/tables/:id
DELETE /api/tables/:id
```

### Response Format

The package supports multiple response formats:

```json
// Standard format
{
  "data": [...]
}

// Laravel pagination
{
  "current_page": 1,
  "data": [...],
  "total": 100
}

// Custom format
{
  "success": true,
  "items": [...]
}

// Nested format
{
  "livreurs": {
    "data": [...]
  }
}
```

## Advanced Usage

### Custom Image Handling

If you don't want image caching, you can disable it by modifying the service or providing a custom implementation.

### Multi-Tenant Support

Filter imports by restaurant:

```dart
final restaurantId = currentUser.restaurantId;

await importCtrl.importRestaurants(filterByRestaurantId: restaurantId);
await importCtrl.importTables(restaurantId: restaurantId);
await importCtrl.importUsers(restaurantId: restaurantId);
await importCtrl.importDeliveries(restaurantId: restaurantId);
```

### Error Handling

```dart
try {
  await importCtrl.importProducts();
} catch (e) {
  // Handle specific errors
  if (e.toString().contains('401')) {
    print('Authentication error');
  } else if (e.toString().contains('404')) {
    print('Endpoint not found');
  } else {
    print('Unknown error: $e');
  }
}
```

## Architecture

```
lib/
├── services/
│   ├── api_import_service.dart      # Main import service
│   ├── database_service.dart        # Isar database abstraction
│   └── image_cache_service.dart     # Image caching
├── controllers/
│   └── import_controller.dart       # GetX controller
├── models/                          # Data models (provided by host app)
└── utils/
    ├── badge_code_utils.dart        # Badge normalization
    └── image_resolver_shared.dart   # Image URL normalization
```

## Dependencies

- **get**: ^4.6.6 - State management
- **http**: ^1.1.0 - HTTP client
- **isar**: ^3.1.0+1 - Local database
- **crypto**: ^3.0.3 - Password hashing
- **path_provider**: ^2.1.1 - File paths

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues and questions:
- GitHub Issues: https://github.com/your-org/pos_data_importer/issues
- Documentation: See IMPORT_PACKAGE_GUIDE.md in the parent repository

---

Made with ❤️ for POS applications
