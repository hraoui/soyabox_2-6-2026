import 'package:get/get.dart';
import '../models/product_model.dart';
import '../models/category_model.dart';
import '../models/product_price.dart';
import '../services/database_service.dart';
import '../api/api_client.dart';
import '../utils/app_logger.dart';

class ProductController extends GetxController {
  static ProductController get instance => Get.find();

  final RxList<Product> _products = <Product>[].obs;
  List<Product> get products => _products.toList();

  @override
  void onInit() {
    super.onInit();
    // DatabaseService is already initialized in main.dart
    // ❌ DO NOT auto-fetch products - wait for manual import via Import Data screen
    // ✅ Products/Categories/Restaurants are manual import only
    print(
      '🛍️ [PRODUCT] ProductController initialized (waiting for manual import)',
    );
  }

  /// Load products from local DB only
  /// Call this manually from Import Data screen after importing
  Future<void> fetchAllProducts() async {
    try {
      appLogger.i('📦 Loading products from local DB...');
      final products = await DatabaseService.getAllProducts();
      appLogger.i('📦 Loaded ${products.length} products from local DB');
      _products.assignAll(products);
      update();
    } catch (e) {
      appLogger.e('❌ Error fetching products: $e');
      update();
      rethrow;
    }
  }

  /// Fetch products from backend API with multiple price types
  /// and sync them to local Isar database
  Future<bool> fetchProductsFromApi() async {
    try {
      appLogger.i('🌐 Fetching products from API...');
      final client = Get.find<ApiClient>();
      final response = await client.getData('/api/products');

      if (response.statusCode != 200) {
        appLogger.e(
          '❌ Failed to fetch products from API: ${response.statusCode}',
        );
        return false;
      }

      final responseData = response.body;
      if (responseData is! Map || responseData['success'] != true) {
        appLogger.e('❌ Invalid API response format');
        return false;
      }

      final data = responseData['data'] as List;
      if (data.isEmpty) {
        appLogger.w('⚠️ No products returned from API');
        return true;
      }

      appLogger.i('✅ API returned ${data.length} products');

      int productsCreated = 0;
      int pricesCreated = 0;
      int glovoPricesCount = 0;

      appLogger.i('\n📦 === DÉBUT SYNCHRO PRODUITS ===');
      appLogger.i('📊 Total produits API: ${data.length}');

      // First, load local categories to map API category IDs to local IDs
      final localCategories = await DatabaseService.getAllCategories();
      appLogger.i('📂 Local categories: ${localCategories.length}');
      final apiCategoryIds = localCategories.map((c) => c.id).toList();
      appLogger.i('📂 Local category IDs: $apiCategoryIds');

      for (final productData in data) {
        final productId = productData['id'] as int;
        final productName = productData['name'] as String;
        // Handle both String and num for price (Laravel returns String)
        final basePrice = _parsePrice(productData['price']);

        // Get category ID from API
        final apiCategoryId = productData['category']?['id'] as int?;
        final apiCategoryName = productData['category']?['name'] as String?;

        // Find matching local category by API ID or name
        int localCategoryId = 0;
        if (apiCategoryId != null) {
          final matchingCategory = localCategories.firstWhere(
            (c) => c.id == apiCategoryId,
            orElse: () => Category(
              id: 0,
              name: apiCategoryName ?? 'Unknown',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );
          if (matchingCategory.id != 0) {
            localCategoryId = matchingCategory.id;
            appLogger.i(
              '🏷️ Product "$productName" -> Category "${matchingCategory.name}" (ID=${matchingCategory.id})',
            );
          } else {
            appLogger.w(
              '⚠️ Category not found for API ID=$apiCategoryId, name=$apiCategoryName',
            );
          }
        }

        // Parse product
        final product = Product(
          id: productId,
          name: productName,
          description: productData['description'] as String?,
          price: basePrice,
          image: productData['image'] as String?,
          categoryId: localCategoryId,
          isAvailable: productData['is_available'] as bool? ?? true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Save product to database
        await DatabaseService.createProduct(product);
        productsCreated++;

        // Parse and save prices
        final pricesData = productData['prices'] as List?;
        double? glovoPrice;

        appLogger.i('\n📝 Traitement prix pour $productName (ID: $productId):');

        if (pricesData != null && pricesData.isNotEmpty) {
          // Delete existing prices for this product first
          final deletedCount =
              await DatabaseService.deleteProductPricesByProduct(productId);
          appLogger.i('   └─ Anciens prix supprimés: $deletedCount');

          for (final priceData in pricesData) {
            final priceType = priceData['type'] as String;
            // Handle both String and num for price (Laravel returns String)
            final priceValue = _parsePrice(priceData['price']);

            appLogger.i(
              '   └─ Prix: $priceType = ${priceValue.toStringAsFixed(2)} dh',
            );

            final productPrice = ProductPrice(
              productId: productId,
              type: priceType.toLowerCase(), // Force lowercase for consistency
              price: priceValue,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
            await DatabaseService.createProductPrice(productPrice);
            pricesCreated++;

            if (priceType.toLowerCase() == 'glovo') {
              glovoPrice = priceValue;
              glovoPricesCount++;
            }
          }
        } else {
          appLogger.i('   └─ Aucun prix dans API');
        }

        // Debug print for each product
        if (glovoPrice != null) {
          appLogger.i('✅ $productName (ID: $productId)');
          appLogger.i('   └─ Prix base: ${basePrice.toStringAsFixed(2)} dh');
          appLogger.i(
            '   └─ Supplément Glovo: ${glovoPrice.toStringAsFixed(2)} dh',
          );
          appLogger.i(
            '   └─ Prix total (base + supplement): ${(basePrice + glovoPrice).toStringAsFixed(2)} dh',
          );
        } else {
          appLogger.i('⚠️ $productName (ID: $productId) - PAS DE PRIX GLOVO');
          appLogger.i('   └─ Prix base: ${basePrice.toStringAsFixed(2)} dh');
        }
      }

      appLogger.i('\n✅ FIN SYNCHRO');
      appLogger.i('📊 Produits: $productsCreated');
      appLogger.i('🏷️  Prix totaux: $pricesCreated');
      appLogger.i('🛵  Prix Glovo: $glovoPricesCount');
      appLogger.i('=================================\n');

      // Refresh local products list
      await fetchAllProducts();
      appLogger.i(
        '✅ Products sync completed, ${_products.length} products loaded',
      );

      return true;
    } catch (e) {
      appLogger.e('❌ Error fetching products from API: $e');
      return false;
    }
  }

  /// Force reload products from API
  Future<void> forceReloadFromApi() async {
    appLogger.i('🔄 Force reloading products from API...');
    final success = await fetchProductsFromApi();
    if (!success) {
      appLogger.w('⚠️ Force reload from API failed, using local DB');
      await fetchAllProducts();
    }
  }

  /// Get product with its prices from local database
  Future<Map<String, dynamic>?> getProductWithPrices(int productId) async {
    try {
      final product = await DatabaseService.getProductById(productId);
      if (product == null) return null;

      final prices = await DatabaseService.getProductPricesByProduct(productId);

      return {
        'product': product,
        'prices': prices,
        'glovoPrice': prices
            .firstWhere(
              (p) => p.type.toLowerCase() == 'glovo',
              orElse: () => ProductPrice(
                productId: productId,
                type: 'glovo',
                price: product.price,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            )
            .price,
      };
    } catch (e) {
      appLogger.i('Error getting product with prices: $e');
      return null;
    }
  }

  // Create a new product
  Future<bool> createProduct({
    required String name,
    String? description,
    required double price,
    String? image,
    required int categoryId,
    bool offer = false,
    bool isAvailable = true,
    int sortOrder = 0,
  }) async {
    try {
      // Assign a local ID starting from 900 to avoid collision with imported products
      final nextId = await _getNextLocalProductId();

      // Create new product
      final newProduct = Product(
        id: nextId,
        name: name,
        description: description,
        price: price,
        image: image,
        categoryId: categoryId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Set the boolean properties after creation since they have defaults
      newProduct.offer = offer;
      newProduct.isAvailable = isAvailable;
      newProduct.sortOrder = sortOrder;

      // Save product to database
      final productId = await DatabaseService.createProduct(newProduct);

      if (productId != 0) {
        _products.add(newProduct);
        update();
        return true;
      }

      return false;
    } catch (e) {
      appLogger.i('Error creating product: $e');
      rethrow;
    }
  }

  // Update product
  Future<bool> updateProduct({
    required int productId,
    String? name,
    String? description,
    double? price,
    String? image,
    int? categoryId,
    bool? offer,
    bool? isAvailable,
    int? sortOrder,
  }) async {
    try {
      // Get the product from database
      final product = await DatabaseService.getProductById(productId);
      if (product == null) {
        throw Exception('Produit introuvable');
      }

      // Update fields if provided
      if (name != null) product.name = name;
      if (description != null) product.description = description;
      if (price != null) product.price = price;
      if (image != null) product.image = image;
      if (categoryId != null) product.categoryId = categoryId;
      if (offer != null) product.offer = offer;
      if (isAvailable != null) product.isAvailable = isAvailable;
      if (sortOrder != null) product.sortOrder = sortOrder;

      product.updatedAt = DateTime.now();

      // Update product in database
      final result = await DatabaseService.updateProduct(product);

      if (result != 0) {
        // Update the product in the observable list
        final index = _products.indexWhere((p) => p.id == productId);
        if (index != -1) {
          _products[index] = product;
        } else {
          // If not in the list, add it
          _products.add(product);
        }
        update();
        return true;
      }

      return false;
    } catch (e) {
      appLogger.i('Error updating product: $e');
      rethrow;
    }
  }

  // Get products by category
  List<Product> getProductsByCategory(int categoryId) {
    final filtered = _products
        .where((product) => product.categoryId == categoryId)
        .toList();
    appLogger.i(
      '📦 getProductsByCategory($categoryId): ${filtered.length} products',
    );
    if (filtered.isNotEmpty) {
      appLogger.i(
        '📦 First product: ${filtered.first.name}, categoryId=${filtered.first.categoryId}',
      );
    }
    return filtered;
  }

  // Get available products only
  List<Product> getAvailableProducts() {
    return _products.where((product) => product.isAvailable).toList();
  }

  // Get products on offer
  List<Product> getProductsOnOffer() {
    return _products.where((product) => product.offer).toList();
  }

  // Delete product
  Future<bool> deleteProduct(int productId) async {
    try {
      final result = await DatabaseService.deleteProduct(productId);

      if (result) {
        // Remove from the observable list
        _products.removeWhere((product) => product.id == productId);
        update();
        return true;
      }

      return false;
    } catch (e) {
      appLogger.i('Error deleting product: $e');
      rethrow;
    }
  }

  /// Get the next available local product ID (starting from 900)
  /// to avoid collision with imported products from backend
  Future<int> _getNextLocalProductId() async {
    try {
      final allProducts = await DatabaseService.getAllProducts();
      // Find the highest local ID (>= 900)
      int maxLocalId = 899; // Start from 900
      for (final product in allProducts) {
        if (product.id >= 900 && product.id > maxLocalId) {
          maxLocalId = product.id;
        }
      }
      final nextId = maxLocalId + 1;
      appLogger.i('🆔 Next local product ID: $nextId');
      return nextId;
    } catch (e) {
      appLogger.e(
        '⚠️ Error getting next local product ID, defaulting to 900: $e',
      );
      return 900;
    }
  }

  /// Parse price from API (handles both String and num)
  /// Laravel returns prices as strings like "200.00"
  double _parsePrice(dynamic priceData) {
    if (priceData == null) return 0.0;
    if (priceData is num) return priceData.toDouble();
    if (priceData is String) {
      return double.tryParse(priceData) ?? 0.0;
    }
    return 0.0;
  }
}
