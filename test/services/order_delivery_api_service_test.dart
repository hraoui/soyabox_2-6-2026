import 'package:caisse_1/api/api_client.dart';
import 'package:caisse_1/services/order_delivery_api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class _FakeApiClient extends ApiClient {
  _FakeApiClient({this.postResponse, this.getResponse})
    : super(appBaseUrl: 'http://localhost:8000', token: 'test-token');

  Response<dynamic>? postResponse;
  Response<dynamic>? getResponse;
  String? lastPostUri;
  dynamic lastPostBody;
  String? lastGetUri;

  @override
  Future<Response> postData(String uri, dynamic body) async {
    lastPostUri = uri;
    lastPostBody = body;
    return postResponse ?? Response(statusCode: 500, body: const {});
  }

  @override
  Future<Response> getData(String uri, {Map<String, String>? headers}) async {
    lastGetUri = uri;
    return getResponse ?? Response(statusCode: 500, body: const {});
  }
}

Map<String, dynamic> _backendOrderPayload({
  required int orderId,
  String deliveryStatus = 'assigned',
}) {
  return {
    'id': orderId,
    'livreur_id': 9,
    'delivery_status': deliveryStatus,
    'livreur_assigned_at': '2026-03-17T10:00:00.000Z',
    'livreur_picked_at': '2026-03-17T10:10:00.000Z',
    'livreur_delivered_at': '2026-03-17T10:20:00.000Z',
    'livreur': {'id': 9, 'name': 'Amine', 'phone': '0600000000'},
    'created_at': '2026-03-17T10:00:00.000Z',
    'updated_at': '2026-03-17T10:20:00.000Z',
  };
}

void main() {
  group('OrderDeliveryApiService', () {
    test('assignLivreur parses payload from order key', () async {
      final client = _FakeApiClient(
        postResponse: Response(
          statusCode: 200,
          body: {
            'success': true,
            'order': _backendOrderPayload(
              orderId: 42,
              deliveryStatus: 'assigned',
            ),
          },
        ),
      );
      final service = OrderDeliveryApiService(
        apiClient: client,
        restaurantId: 7,
      );

      final result = await service.assignLivreur(orderId: 42, livreurId: 9);

      expect(
        client.lastPostUri,
        '/api/restaurants/7/delivery/orders/42/assign',
      );
      expect(client.lastPostBody, {'livreur_id': 9});
      expect(result, isNotNull);
      expect(result!.orderId, 42);
      expect(result.livreurName, 'Amine');
      expect(result.status, 'assigned');
    });

    test('markPickup parses payload from nested data key', () async {
      final client = _FakeApiClient(
        postResponse: Response(
          statusCode: 200,
          body: {
            'success': true,
            'data': _backendOrderPayload(
              orderId: 55,
              deliveryStatus: 'picked_up',
            ),
          },
        ),
      );
      final service = OrderDeliveryApiService(
        apiClient: client,
        restaurantId: 3,
      );

      final result = await service.markPickup(55);

      expect(
        client.lastPostUri,
        '/api/restaurants/3/delivery/orders/55/pickup',
      );
      expect(result, isNotNull);
      expect(result!.status, 'picked_up');
    });

    test(
      'getDeliveryDetails parses backend order payload from /api/orders/{id}',
      () async {
        final client = _FakeApiClient(
          getResponse: Response(
            statusCode: 200,
            body: {
              'success': true,
              'order': _backendOrderPayload(
                orderId: 88,
                deliveryStatus: 'delivered',
              ),
            },
          ),
        );
        final service = OrderDeliveryApiService(
          apiClient: client,
          restaurantId: 5,
        );

        final result = await service.getDeliveryDetails(88);

        expect(client.lastGetUri, '/api/orders/88');
        expect(result, isNotNull);
        expect(result!.orderId, 88);
        expect(result.livreurId, 9);
        expect(result.livreurName, 'Amine');
        expect(result.status, 'delivered');
      },
    );
  });
}
