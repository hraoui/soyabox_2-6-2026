import 'package:caisse_1/api/api_client.dart';
import 'package:get/get.dart';

class CategoryRepo extends GetxService {
  final ApiClient apiClient;
  CategoryRepo({required this.apiClient});

  Future<Response> getCategoriesList() async {
    return await apiClient.getData("/api/categories");
  }

  Future<Response> getProductsForCategory(int categoryId) async {
    return await apiClient.getData("/api/categories/$categoryId/products");
  }

  Future<Response> getCategoryAssortiments() async {
    return await apiClient.getData("/api/category/assortiments/products");
  }

  Future<Response> getDailyOffer() async {
    return await apiClient.getData("/api/category/daily-offer/products");
  }
}
