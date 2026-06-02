import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../data/app_constants.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../controllers/category_controller.dart';
import '../controllers/product_controller.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';
import '../utils/image_resolver.dart';
import '../utils/image_resolver_shared.dart';
import '../services/image_cache_service.dart';
import '../services/app_settings_service.dart';
import '../data/glass_theme.dart';
import '../theme/app_theme.dart';
import '../theme/app_colors.dart';
import '../widgets/admin_shell.dart';

class ProductCatalogScreen extends StatelessWidget {
  const ProductCatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Make sure required controllers are available (safeguard if bindings weren't run)
    if (!Get.isRegistered<CategoryController>()) {
      Get.put(CategoryController());
    }
    if (!Get.isRegistered<ProductController>()) {
      Get.put(ProductController());
    }

    return DefaultTabController(
      length: 2,
      child: AdminShell(
        title: 'Catalogue',
        activeRoute: '/catalog',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.blancPur,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.grisLeger),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const TabBar(
                indicatorColor: AppColors.terraCotta,
                labelColor: AppColors.charbon,
                unselectedLabelColor: AppColors.grisModerne,
                indicator: UnderlineTabIndicator(
                  borderSide: BorderSide(color: AppColors.terraCotta, width: 3),
                ),
                tabs: [
                  Tab(text: 'Catégories'),
                  Tab(text: 'Produits'),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Expanded(
              child: TabBarView(
                children: [CategoryListView(), ProductListView()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

AlertDialog _glassAlert({
  required String title,
  required Widget content,
  required List<Widget> actions,
  double maxWidth = 560,
}) {
  return AlertDialog(
    backgroundColor: GlassColors.glassWhite.withAlpha(228),
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
    titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
    contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
    actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
    title: Text(title, style: AppTypography.headline2.copyWith(fontSize: 18)),
    content: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: content,
    ),
    actions: [
      const SizedBox(width: 8),
      ...actions.map(
        (a) => Padding(padding: const EdgeInsets.only(left: 8), child: a),
      ),
    ],
  );
}

InputDecoration _glassFieldDecoration(String label) {
  return InputDecoration(
    labelText: label,
    filled: true,
    fillColor: GlassColors.glassWhite.withAlpha(210),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: GlassColors.sushi.withAlpha(120)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: GlassColors.sushi.withAlpha(120)),
    ),
    focusedBorder: const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: GlassColors.redAccent, width: 2),
    ),
  );
}

Widget _glassField({
  required TextEditingController controller,
  required String label,
  bool readOnly = false,
  TextInputType keyboardType = TextInputType.text,
}) {
  return TextField(
    controller: controller,
    readOnly: readOnly,
    keyboardType: keyboardType,
    decoration: _glassFieldDecoration(label),
  );
}

class CategoryListView extends StatefulWidget {
  const CategoryListView({super.key});

  @override
  State<CategoryListView> createState() => _CategoryListViewState();
}

class _CategoryListViewState extends State<CategoryListView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return GetBuilder<CategoryController>(
      builder: (categoryController) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () =>
                      _showCreateCategoryDialog(context, categoryController),
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter catégorie'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.terraCotta,
                    foregroundColor: AppColors.blancPur,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: categoryController.categories.isEmpty
                  ? const Center(
                      child: Text(
                        'Aucune catégorie.\nImportez depuis le backend.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                  : GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 5,
                            childAspectRatio: 1.0,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                      itemCount: categoryController.categories.length,
                      itemBuilder: (context, index) {
                        final category = categoryController.categories[index];
                        if (category.isDeleted) {
                          return const SizedBox.shrink();
                        }

                        return Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            CategoryProductsScreen(
                                              categoryId: category.id,
                                              categoryName: category.name,
                                            ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(12),
                                      ),
                                      color: AppColors.cloudDancer,
                                    ),
                                    child: _buildCategoryAvatar(
                                      category.name,
                                      category.image,
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                  vertical: AppSpacing.xs,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: InkWell(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  CategoryProductsScreen(
                                                    categoryId: category.id,
                                                    categoryName: category.name,
                                                  ),
                                            ),
                                          );
                                        },
                                        child: Text(
                                          category.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTypography.bodyLarge
                                              .copyWith(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 12,
                                              ),
                                        ),
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      onSelected: (value) async {
                                        if (value == 'edit') {
                                          _showEditCategoryDialog(
                                            context,
                                            categoryController,
                                            category,
                                          );
                                        } else if (value == 'delete') {
                                          await categoryController
                                              .deleteCategory(category.id);
                                        }
                                      },
                                      itemBuilder: (context) => const [
                                        PopupMenuItem(
                                          value: 'edit',
                                          child: Text('Modifier'),
                                        ),
                                        PopupMenuItem(
                                          value: 'delete',
                                          child: Text('Supprimer'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategoryAvatar(String name, String? imagePath) {
    final url = _networkUrl(imagePath);
    if (url == null) {
      final imageProvider = resolveImageProvider(imagePath);
      if (imageProvider != null) {
        return Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
          ),
        );
      }
      return Container(
        alignment: Alignment.center,
        child: Text(
          name[0].toUpperCase(),
          style: AppTypography.headline1.copyWith(color: AppColors.terraCotta),
        ),
      );
    }
    final cachedPath = ImageCacheService.instance.cachedFilePathForUrlSync(url);
    if (cachedPath != null) {
      return Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: FileImage(File(cachedPath)),
            fit: BoxFit.cover,
          ),
        ),
      );
    }
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      child: CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        placeholder: (context, _) =>
            const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        errorWidget: (context, _, _) => Container(
          alignment: Alignment.center,
          color: AppColors.cloudDancer,
          child: Text(
            name[0].toUpperCase(),
            style: AppTypography.headline1.copyWith(
              color: AppColors.terraCotta,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showCreateCategoryDialog(
    BuildContext context,
    CategoryController controller,
  ) async {
    final nameController = TextEditingController();
    final imageController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) {
        return _glassAlert(
          title: 'Nouvelle catégorie',
          maxWidth: 520,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _glassField(controller: nameController, label: 'Nom'),
              const SizedBox(height: AppSpacing.md),
              _glassField(
                controller: imageController,
                label: 'Image',
                readOnly: true,
              ),
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () async {
                    final result = await FilePicker.pickFiles(
                      type: FileType.image,
                    );
                    final path = result?.files.single.path;
                    if (path != null) {
                      imageController.text = path;
                    }
                  },
                  icon: const Icon(Icons.image),
                  label: const Text('Choisir une image'),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                await controller.createCategory(
                  name: name,
                  image: imageController.text.trim().isEmpty
                      ? null
                      : imageController.text.trim(),
                );
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Créer'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showEditCategoryDialog(
    BuildContext context,
    CategoryController controller,
    Category category,
  ) async {
    final nameController = TextEditingController(text: category.name);
    final imageController = TextEditingController(text: category.image ?? '');
    await showDialog(
      context: context,
      builder: (context) {
        return _glassAlert(
          title: 'Modifier catégorie',
          maxWidth: 520,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _glassField(controller: nameController, label: 'Nom'),
              const SizedBox(height: AppSpacing.md),
              _glassField(
                controller: imageController,
                label: 'Image',
                readOnly: true,
              ),
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () async {
                    final result = await FilePicker.pickFiles(
                      type: FileType.image,
                    );
                    final path = result?.files.single.path;
                    if (path != null) {
                      imageController.text = path;
                    }
                  },
                  icon: const Icon(Icons.image),
                  label: const Text('Choisir une image'),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                await controller.updateCategory(
                  categoryId: category.id,
                  name: name,
                  image: imageController.text.trim().isEmpty
                      ? null
                      : imageController.text.trim(),
                );
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    );
  }
}

class ProductListView extends StatefulWidget {
  const ProductListView({super.key});

  @override
  State<ProductListView> createState() => _ProductListViewState();
}

class _ProductListViewState extends State<ProductListView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return GetBuilder<ProductController>(
      builder: (productController) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () =>
                      _showCreateProductDialog(context, productController),
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter produit'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.terraCotta,
                    foregroundColor: AppColors.blancPur,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: productController.products.isEmpty
                  ? const Center(
                      child: Text(
                        'Aucun produit.\nImportez depuis le backend.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                  : GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 5,
                            childAspectRatio: 1.0,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                      itemCount: productController.products.length,
                      itemBuilder: (context, index) {
                        final product = productController.products[index];
                        return Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: Stack(
                                  alignment: Alignment.bottomRight,
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            const BorderRadius.vertical(
                                              top: Radius.circular(12),
                                            ),
                                        color: AppColors.cloudDancer,
                                      ),
                                      child: _buildProductAvatar(
                                        product.name,
                                        product.image,
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 8,
                                      right: 8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppSpacing.sm,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.terraCotta,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          AppSettingsService.instance
                                              .formatAmount(product.price),
                                          style: const TextStyle(
                                            color: Color.fromARGB(
                                              255,
                                              255,
                                              255,
                                              255,
                                            ),
                                            fontWeight: FontWeight.w600,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                  vertical: AppSpacing.xs,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        product.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTypography.bodyLarge.copyWith(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      onSelected: (value) async {
                                        if (value == 'edit') {
                                          _showEditProductDialog(
                                            context,
                                            productController,
                                            product,
                                          );
                                        } else if (value == 'delete') {
                                          await productController.deleteProduct(
                                            product.id,
                                          );
                                        }
                                      },
                                      itemBuilder: (context) => const [
                                        PopupMenuItem(
                                          value: 'edit',
                                          child: Text('Modifier'),
                                        ),
                                        PopupMenuItem(
                                          value: 'delete',
                                          child: Text('Supprimer'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProductAvatar(String name, String? imagePath) {
    final url = _networkUrl(imagePath);
    if (url == null) {
      final imageProvider = resolveImageProvider(imagePath);
      if (imageProvider != null) {
        return Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
          ),
        );
      }
      return Container(
        alignment: Alignment.center,
        child: Text(
          name[0].toUpperCase(),
          style: AppTypography.headline1.copyWith(color: AppColors.terraCotta),
        ),
      );
    }
    final cachedPath = ImageCacheService.instance.cachedFilePathForUrlSync(url);
    if (cachedPath != null) {
      return Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: FileImage(File(cachedPath)),
            fit: BoxFit.cover,
          ),
        ),
      );
    }
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      child: CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        placeholder: (context, _) =>
            const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        errorWidget: (context, _, _) => Container(
          alignment: Alignment.center,
          color: AppColors.cloudDancer,
          child: Text(
            name[0].toUpperCase(),
            style: AppTypography.headline1.copyWith(
              color: AppColors.terraCotta,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showCreateProductDialog(
    BuildContext context,
    ProductController controller,
  ) async {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final imageController = TextEditingController();
    final descController = TextEditingController();
    final categoryController = Get.find<CategoryController>();
    final categories = categoryController.getActiveCategories();
    int? selectedCategoryId = categories.isNotEmpty
        ? categories.first.id
        : null;

    await showDialog(
      context: context,
      builder: (context) {
        return _glassAlert(
          title: 'Nouveau produit',
          maxWidth: 640,
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _glassField(controller: nameController, label: 'Nom'),
                const SizedBox(height: AppSpacing.md),
                _glassField(controller: descController, label: 'Description'),
                const SizedBox(height: AppSpacing.md),
                _glassField(
                  controller: priceController,
                  label: 'Prix',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: AppSpacing.md),
                _glassField(
                  controller: imageController,
                  label: 'Image',
                  readOnly: true,
                ),
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () async {
                      final result = await FilePicker.pickFiles(
                        type: FileType.image,
                      );
                      final path = result?.files.single.path;
                      if (path != null) {
                        imageController.text = path;
                      }
                    },
                    icon: const Icon(Icons.image),
                    label: const Text('Choisir une image'),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<int>(
                  initialValue: selectedCategoryId,
                  decoration: _glassFieldDecoration('Catégorie'),
                  items: [
                    for (final c in categories)
                      DropdownMenuItem(value: c.id, child: Text(c.name)),
                  ],
                  onChanged: (value) {
                    selectedCategoryId = value;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final price = double.tryParse(priceController.text.trim());
                if (name.isEmpty ||
                    price == null ||
                    selectedCategoryId == null) {
                  return;
                }
                await controller.createProduct(
                  name: name,
                  description: descController.text.trim().isEmpty
                      ? null
                      : descController.text.trim(),
                  price: price,
                  image: imageController.text.trim().isEmpty
                      ? null
                      : imageController.text.trim(),
                  categoryId: selectedCategoryId!,
                );
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Créer'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showEditProductDialog(
    BuildContext context,
    ProductController controller,
    Product product,
  ) async {
    final nameController = TextEditingController(text: product.name);
    final priceController = TextEditingController(
      text: product.price.toString(),
    );
    final imageController = TextEditingController(text: product.image ?? '');
    final descController = TextEditingController(
      text: product.description ?? '',
    );
    final categoryController = Get.find<CategoryController>();
    final categories = categoryController.getActiveCategories();
    int? selectedCategoryId = product.categoryId;

    await showDialog(
      context: context,
      builder: (context) {
        return _glassAlert(
          title: 'Modifier produit',
          maxWidth: 640,
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _glassField(controller: nameController, label: 'Nom'),
                const SizedBox(height: AppSpacing.md),
                _glassField(controller: descController, label: 'Description'),
                const SizedBox(height: AppSpacing.md),
                _glassField(
                  controller: priceController,
                  label: 'Prix',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: AppSpacing.md),
                _glassField(
                  controller: imageController,
                  label: 'Image',
                  readOnly: true,
                ),
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () async {
                      final result = await FilePicker.pickFiles(
                        type: FileType.image,
                      );
                      final path = result?.files.single.path;
                      if (path != null) {
                        imageController.text = path;
                      }
                    },
                    icon: const Icon(Icons.image),
                    label: const Text('Choisir une image'),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<int>(
                  initialValue: selectedCategoryId,
                  decoration: _glassFieldDecoration('Catégorie'),
                  items: [
                    for (final c in categories)
                      DropdownMenuItem(value: c.id, child: Text(c.name)),
                  ],
                  onChanged: (value) {
                    selectedCategoryId = value;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final price = double.tryParse(priceController.text.trim());
                if (name.isEmpty ||
                    price == null ||
                    selectedCategoryId == null) {
                  return;
                }
                await controller.updateProduct(
                  productId: product.id,
                  name: name,
                  description: descController.text.trim().isEmpty
                      ? null
                      : descController.text.trim(),
                  price: price,
                  image: imageController.text.trim().isEmpty
                      ? null
                      : imageController.text.trim(),
                  categoryId: selectedCategoryId!,
                );
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    );
  }
}

String? _networkUrl(String? path) {
  final normalized = normalizeImagePath(path);
  if (normalized == null) return null;
  if (normalized.startsWith('http://') || normalized.startsWith('https://')) {
    return normalized;
  }
  return '${AppConstant.baseUrl}/$normalized';
}

/// Page affichant les produits d'une catégorie spécifique
class CategoryProductsScreen extends StatelessWidget {
  final int categoryId;
  final String categoryName;

  const CategoryProductsScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      title: categoryName,
      activeRoute: '/catalog',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Retour',
              ),
              Text('Produits', style: AppTypography.headline2),
              const SizedBox(width: AppSpacing.md),
              ElevatedButton.icon(
                onPressed: () => _showCreateProductDialog(
                  context,
                  Get.find<ProductController>(),
                  categoryId,
                ),
                icon: const Icon(Icons.add),
                label: const Text('Ajouter produit'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.terraCotta,
                  foregroundColor: AppColors.blancPur,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: GetBuilder<ProductController>(
              builder: (productController) {
                final products = productController.getProductsByCategory(
                  categoryId,
                );

                if (products.isEmpty) {
                  return const Center(
                    child: Text(
                      'Aucun produit dans cette catégorie.\nAjoutez un produit pour commencer.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    childAspectRatio: 1.0,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(12),
                                    ),
                                    color: AppColors.cloudDancer,
                                  ),
                                  child: _buildProductAvatar(
                                    product.name,
                                    product.image,
                                  ),
                                ),
                                Positioned(
                                  bottom: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.sm,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.terraCotta,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      AppSettingsService.instance.formatAmount(
                                        product.price,
                                      ),
                                      style: const TextStyle(
                                        color: AppColors.blancPur,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xs,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Text(
                                    product.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.bodyLarge.copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  onSelected: (value) async {
                                    if (value == 'edit') {
                                      _showEditProductDialog(
                                        context,
                                        productController,
                                        product,
                                        categoryId,
                                      );
                                    } else if (value == 'delete') {
                                      await productController.deleteProduct(
                                        product.id,
                                      );
                                    }
                                  },
                                  itemBuilder: (context) => const [
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Text('Modifier'),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Supprimer'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductAvatar(String name, String? imagePath) {
    final url = _networkUrl(imagePath);
    if (url == null) {
      final imageProvider = resolveImageProvider(imagePath);
      if (imageProvider != null) {
        return Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
          ),
        );
      }
      return Container(
        alignment: Alignment.center,
        child: Text(
          name[0].toUpperCase(),
          style: AppTypography.headline1.copyWith(color: AppColors.terraCotta),
        ),
      );
    }
    final cachedPath = ImageCacheService.instance.cachedFilePathForUrlSync(url);
    if (cachedPath != null) {
      return Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: FileImage(File(cachedPath)),
            fit: BoxFit.cover,
          ),
        ),
      );
    }
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      child: CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        placeholder: (context, _) =>
            const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        errorWidget: (context, error, stackTrace) => Container(
          alignment: Alignment.center,
          color: AppColors.cloudDancer,
          child: Text(
            name[0].toUpperCase(),
            style: AppTypography.headline1.copyWith(
              color: AppColors.terraCotta,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showCreateProductDialog(
    BuildContext context,
    ProductController controller,
    int categoryId,
  ) async {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final imageController = TextEditingController();
    final descController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return _glassAlert(
          title: 'Nouveau produit',
          maxWidth: 640,
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _glassField(controller: nameController, label: 'Nom'),
                const SizedBox(height: AppSpacing.md),
                _glassField(controller: descController, label: 'Description'),
                const SizedBox(height: AppSpacing.md),
                _glassField(
                  controller: priceController,
                  label: 'Prix',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: AppSpacing.md),
                _glassField(
                  controller: imageController,
                  label: 'Image',
                  readOnly: true,
                ),
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () async {
                      final result = await FilePicker.pickFiles(
                        type: FileType.image,
                      );
                      final path = result?.files.single.path;
                      if (path != null) {
                        imageController.text = path;
                      }
                    },
                    icon: const Icon(Icons.image),
                    label: const Text('Choisir une image'),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final price = double.tryParse(priceController.text.trim());
                if (name.isEmpty || price == null) {
                  return;
                }
                await controller.createProduct(
                  name: name,
                  description: descController.text.trim().isEmpty
                      ? null
                      : descController.text.trim(),
                  price: price,
                  image: imageController.text.trim().isEmpty
                      ? null
                      : imageController.text.trim(),
                  categoryId: categoryId,
                );
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Créer'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showEditProductDialog(
    BuildContext context,
    ProductController controller,
    Product product,
    int categoryId,
  ) async {
    final nameController = TextEditingController(text: product.name);
    final priceController = TextEditingController(
      text: product.price.toString(),
    );
    final imageController = TextEditingController(text: product.image ?? '');
    final descController = TextEditingController(
      text: product.description ?? '',
    );

    await showDialog(
      context: context,
      builder: (context) {
        return _glassAlert(
          title: 'Modifier produit',
          maxWidth: 640,
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _glassField(controller: nameController, label: 'Nom'),
                const SizedBox(height: AppSpacing.md),
                _glassField(controller: descController, label: 'Description'),
                const SizedBox(height: AppSpacing.md),
                _glassField(
                  controller: priceController,
                  label: 'Prix',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: AppSpacing.md),
                _glassField(
                  controller: imageController,
                  label: 'Image',
                  readOnly: true,
                ),
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () async {
                      final result = await FilePicker.pickFiles(
                        type: FileType.image,
                      );
                      final path = result?.files.single.path;
                      if (path != null) {
                        imageController.text = path;
                      }
                    },
                    icon: const Icon(Icons.image),
                    label: const Text('Choisir une image'),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final price = double.tryParse(priceController.text.trim());
                if (name.isEmpty || price == null) {
                  return;
                }
                await controller.updateProduct(
                  productId: product.id,
                  name: name,
                  description: descController.text.trim().isEmpty
                      ? null
                      : descController.text.trim(),
                  price: price,
                  image: imageController.text.trim().isEmpty
                      ? null
                      : imageController.text.trim(),
                  categoryId: categoryId,
                );
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    );
  }
}
