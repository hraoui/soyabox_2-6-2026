import 'package:get/get.dart';
import '../api/api_client.dart';
import '../controllers/category_controller.dart';
import '../controllers/product_controller.dart';
import '../data/app_constants.dart';
import '../repos/category_repo.dart';
import '../repos/product_repo.dart';

class CatalogBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<ApiClient>()) {
      Get.put(ApiClient(appBaseUrl: AppConstant.baseUrl));
    }
    if (!Get.isRegistered<CategoryRepo>()) {
      Get.put(CategoryRepo(apiClient: Get.find()));
    }
    if (!Get.isRegistered<ProductRepo>()) {
      Get.put(ProductRepo(apiClient: Get.find()));
    }
    if (!Get.isRegistered<CategoryController>()) {
      Get.put(CategoryController());
    }
    if (!Get.isRegistered<ProductController>()) {
      Get.put(ProductController());
    }
  }
}
