import 'package:get/get.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';
import '../services/database_service.dart';
import '../utils/app_logger.dart';
import 'product_controller.dart';

class CategoryController extends GetxController {
  static CategoryController get instance => Get.find();

  final RxList<Category> _categories = <Category>[].obs;
  final Rx<Category?> _selectedCategory = Rx<Category?>(null);
  final RxBool _isLoaded = false.obs;
  List<Category> get categories => _categories.toList();
  Rx<Category?> get selectedCategory => _selectedCategory;
  RxBool get isLoaded => _isLoaded;

  @override
  void onInit() {
    super.onInit();
    // DatabaseService is already initialized in main.dart
    // ❌ DO NOT auto-fetch categories - wait for manual import via Import Data screen
    // ✅ Categories are manual import only
    print(
      '📂 [CATEGORY] CategoryController initialized (waiting for manual import)',
    );
  }

  /// Load categories from local DB only
  /// Call this manually from Import Data screen after importing
  Future<void> fetchAllCategories() async {
    try {
      appLogger.i('📂 Loading categories from local DB...');
      final categories = await DatabaseService.getAllCategories();
      appLogger.i('📂 Loaded ${categories.length} categories from local DB');
      // Sort categories: local categories (IDs >= 9000) first,
      // then backend categories ordered by sortOrder then name.
      categories.sort((a, b) {
        final aLocal = a.id >= 9000 ? 0 : 1;
        final bLocal = b.id >= 9000 ? 0 : 1;
        if (aLocal != bLocal) return aLocal.compareTo(bLocal);

        // Both local or both backend: preserve backend sortOrder then name
        final cmp = a.sortOrder.compareTo(b.sortOrder);
        return cmp != 0 ? cmp : a.name.compareTo(b.name);
      });
      _categories.assignAll(categories);

      if (categories.isEmpty) {
        appLogger.w(
          '⚠️ No categories found in local DB. Use "Importer les données" to sync from API.',
        );
        _selectedCategory.value = null;
      } else {
        final selectedId = _selectedCategory.value?.id;
        final selectedExists =
            selectedId != null &&
            categories.any((category) => category.id == selectedId);
        if (!selectedExists) {
          _selectedCategory.value = categories.first;
          appLogger.i('📂 Selected first category: ${categories.first.name}');
        }
      }

      _isLoaded.value = true;
      update();
    } catch (e) {
      appLogger.e('❌ Error fetching categories from local DB: $e');
      _isLoaded.value = true;
      update();
      rethrow;
    }
  }

  // Create a new category
  Future<bool> createCategory({required String name, String? image}) async {
    try {
      // Assign a local ID starting from 9000 to avoid collision with imported categories
      final nextId = await _getNextLocalCategoryId();

      // Create new category
      final newCategory = Category(
        id: nextId,
        name: name,
        image: image,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save category to database
      final categoryId = await DatabaseService.createCategory(newCategory);

      if (categoryId != 0) {
        _categories.add(newCategory);
        update();
        return true;
      }

      return false;
    } catch (e) {
      appLogger.i('Error creating category: $e');
      rethrow;
    }
  }

  // Update category
  Future<bool> updateCategory({
    required int categoryId,
    String? name,
    String? image,
    bool? isDeleted,
  }) async {
    try {
      // Get the category from database
      final category = await DatabaseService.getCategoryById(categoryId);
      if (category == null) {
        throw Exception('Catégorie introuvable');
      }

      // Update fields if provided
      if (name != null) category.name = name;
      if (image != null) category.image = image;
      if (isDeleted != null) category.isDeleted = isDeleted;

      category.updatedAt = DateTime.now();

      // Update category in database
      final result = await DatabaseService.updateCategory(category);

      if (result != 0) {
        // Update the category in the observable list
        final index = _categories.indexWhere((c) => c.id == categoryId);
        if (index != -1) {
          _categories[index] = category;
        } else {
          // If not in the list, add it
          _categories.add(category);
        }
        update();
        return true;
      }

      return false;
    } catch (e) {
      appLogger.i('Error updating category: $e');
      rethrow;
    }
  }

  // Get active categories only
  List<Category> getActiveCategories() {
    return _categories.where((category) => !category.isDeleted).toList();
  }

  // Get deleted categories only
  List<Category> getDeletedCategories() {
    return _categories.where((category) => category.isDeleted).toList();
  }

  /// Clear in-memory category cache after a local reset
  void clearLocalCategories() {
    _categories.clear();
    _selectedCategory.value = null;
    update();
  }

  // Soft delete category
  Future<bool> deleteCategory(int categoryId) async {
    try {
      final category = await DatabaseService.getCategoryById(categoryId);
      if (category == null) {
        throw Exception('Catégorie introuvable');
      }

      // Set isDeleted to true instead of actually deleting
      category.isDeleted = true;
      category.updatedAt = DateTime.now();

      final result = await DatabaseService.updateCategory(category);

      if (result != 0) {
        // Update the category in the observable list
        final index = _categories.indexWhere((c) => c.id == categoryId);
        if (index != -1) {
          _categories[index] = category;
        }
        update();
        return true;
      }

      return false;
    } catch (e) {
      appLogger.i('Error deleting category: $e');
      rethrow;
    }
  }

  // Permanently delete category
  Future<bool> permanentlyDeleteCategory(int categoryId) async {
    // Note: ISAR doesn't have a direct way to permanently delete with schema
    // We'll rely on soft deletion for now
    return await deleteCategory(categoryId);
  }

  // Select a category
  void selectCategory(Category category) {
    _selectedCategory.value = category;
    appLogger.i('📂 Category selected: ${category.name} (ID=${category.id})');
    appLogger.i('📂 Loading products for this category...');
    final productsForCategory = products;
    appLogger.i(
      '📂 Found ${productsForCategory.length} products for category ${category.name}',
    );
    update();
  }

  // Get products for the selected category
  List<Product> get products {
    if (_selectedCategory.value == null) {
      appLogger.i('📂 No category selected, returning empty list');
      return [];
    }
    final result = Get.find<ProductController>().getProductsByCategory(
      _selectedCategory.value!.id,
    );
    appLogger.i(
      '📂 Products getter: ${result.length} products for category ID=${_selectedCategory.value!.id}',
    );
    return result;
  }

  /// Get the next available local category ID (starting from 9000)
  /// to avoid collision with imported categories from backend
  Future<int> _getNextLocalCategoryId() async {
    try {
      final allCategories = await DatabaseService.getAllCategories();
      // Find the highest local ID (>= 9000)
      int maxLocalId = 8999; // Start from 9000
      for (final category in allCategories) {
        if (category.id >= 9000 && category.id > maxLocalId) {
          maxLocalId = category.id;
        }
      }
      final nextId = maxLocalId + 1;
      appLogger.i('🆔 Next local category ID: $nextId');
      return nextId;
    } catch (e) {
      appLogger.e(
        '⚠️ Error getting next local category ID, defaulting to 9000: $e',
      );
      return 9000;
    }
  }
}
