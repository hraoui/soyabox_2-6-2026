import 'package:caisse_1/api/api_client.dart';
import 'package:get/get.dart';

class ProductRepo {
  final ApiClient apiClient;

  ProductRepo({required this.apiClient});

  Future<Response> getProductsList() async {
    return await apiClient.get('/api/products');
  }

  Future<Response> getMostselled() async {
    return await apiClient.get('/api/most-ordered-products');
  }
}
