import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/database_service.dart';
import '../../models/pos_order.dart';
import '../../models/restaurant.dart';
import '../../controllers/restaurant_controller.dart';
import '../../utils/order_display_labels.dart';

/// Diagnostic screen to view API/Web orders stored locally
class CheckLocalApiOrdersScreen extends StatelessWidget {
  const CheckLocalApiOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Local API/Web Orders'),
        backgroundColor: Colors.blue,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _loadOrderData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 64),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                ],
              ),
            );
          }

          final data = snapshot.data!;
          final allOrders = data['allOrders'] as List<PosOrder>;
          final apiOrders = data['apiOrders'] as List<PosOrder>;
          final webOrders = data['webOrders'] as List<PosOrder>;
          final kioskOrders = data['kioskOrders'] as List<PosOrder>;
          final posOrders = data['posOrders'] as List<PosOrder>;
          final restaurants = data['restaurants'] as List<Restaurant>;
          final resolvedRestaurantId = data['resolvedRestaurantId'] as int?;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🍽️ Restaurant Info Section
                Text(
                  '🍽️ Restaurant Configuration',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                _buildRestaurantInfoCard(
                  context,
                  restaurants,
                  resolvedRestaurantId,
                ),
                const SizedBox(height: 24),

                // Summary cards
                Text(
                  '📊 Orders Summary',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildSummaryCard(
                      'Total Orders',
                      allOrders.length,
                      Colors.grey,
                    ),
                    _buildSummaryCard('📡 API', apiOrders.length, Colors.blue),
                    _buildSummaryCard('🌐 Web', webOrders.length, Colors.green),
                    _buildSummaryCard(
                      '🖥️ Kiosk',
                      kioskOrders.length,
                      Colors.orange,
                    ),
                    _buildSummaryCard(
                      '💻 POS',
                      posOrders.length,
                      Colors.purple,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // API/Web/Kiosk orders detail
                if (apiOrders.isNotEmpty ||
                    webOrders.isNotEmpty ||
                    kioskOrders.isNotEmpty) ...[
                  Text(
                    '✅ Orders from Backend (${apiOrders.length + webOrders.length + kioskOrders.length})',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  ..._buildOrderCards(context, [
                    ...apiOrders,
                    ...webOrders,
                    ...kioskOrders,
                  ]),
                  const SizedBox(height: 24),
                ] else
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 48,
                          color: Colors.orange,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No API/Web/Kiosk orders found locally',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'This means either:\n'
                          '• No orders received from backend yet\n'
                          '• Backend→Local sync is not working\n'
                          '• Check sync logs for errors',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 24),

                // Recent orders
                Text(
                  '🔄 Recent Orders (Last 10)',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                ...allOrders
                    .take(10)
                    .map(
                      (order) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Icon(
                            order.channel == 'api'
                                ? Icons.api
                                : order.channel == 'web'
                                ? Icons.web
                                : order.channel == 'kiosk'
                                ? Icons.computer
                                : Icons.point_of_sale,
                            color: order.isFromApi ? Colors.blue : Colors.green,
                          ),
                          title: Text(
                            '#${order.id} [${OrderDisplayLabels.channelLabel(order.channel)}]',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${order.status} • ${order.totalPrice.toStringAsFixed(2)} MAD\n'
                            '${order.createdAt.toLocal()}',
                          ),
                          trailing: Chip(
                            label: Text(
                              order.paymentStatus,
                              style: const TextStyle(fontSize: 12),
                            ),
                            backgroundColor: order.paymentStatus == 'paid'
                                ? Colors.green.shade100
                                : Colors.orange.shade100,
                          ),
                        ),
                      ),
                    ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(String label, int count, Color color) {
    return Card(
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestaurantInfoCard(
    BuildContext context,
    List<Restaurant> restaurants,
    int? resolvedId,
  ) {
    if (restaurants.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.red,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              '⚠️ No restaurant imported locally!',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.red.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'API order sync requires a restaurant ID.\n'
              'Import a restaurant from the backend or create one locally.',
              style: TextStyle(color: Colors.red.shade600),
            ),
          ],
        ),
      );
    }

    final resolvedRestaurant = restaurants.firstWhere(
      (r) => r.id == resolvedId,
      orElse: () => restaurants.first,
    );

    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 24),
                const SizedBox(width: 8),
                Text(
                  '✅ Restaurant Resolved for Sync',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            _buildInfoRow('ID', resolvedRestaurant.id.toString()),
            _buildInfoRow('Name', resolvedRestaurant.name),
            _buildInfoRow('Phone', resolvedRestaurant.phone),
            _buildInfoRow('Address', resolvedRestaurant.address),
            _buildInfoRow(
              'Active',
              resolvedRestaurant.isActive ? '✅ Yes' : '❌ No',
            ),
            const SizedBox(height: 8),
            Text(
              '📦 Total restaurants in DB: ${restaurants.length}',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildOrderCards(BuildContext context, List<PosOrder> orders) {
    return orders
        .map(
          (order) => Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ExpansionTile(
              leading: Icon(
                order.channel == 'api'
                    ? Icons.api
                    : order.channel == 'web'
                    ? Icons.web
                    : Icons.computer,
                color: Colors.blue,
              ),
              title: Text(
                '#${order.id} - ${order.channel.toUpperCase()}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '${order.status} • ${order.totalPrice.toStringAsFixed(2)} MAD',
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow(
                        'Channel',
                        OrderDisplayLabels.channelLabel(order.channel),
                      ),
                      _buildInfoRow('Status', order.status),
                      _buildInfoRow('Payment', order.paymentStatus),
                      _buildInfoRow(
                        'Payment Method',
                        order.paymentMethod ?? 'N/A',
                      ),
                      _buildInfoRow(
                        'Total',
                        '${order.totalPrice.toStringAsFixed(2)} MAD',
                      ),
                      _buildInfoRow(
                        'Original Total',
                        '${order.originalTotal.toStringAsFixed(2)} MAD',
                      ),
                      _buildInfoRow(
                        'Discount',
                        order.hasDiscount
                            ? '${order.discountAmount.toStringAsFixed(2)} MAD'
                            : 'None',
                      ),
                      _buildInfoRow('Fulfillment', order.fulfillmentType),
                      _buildInfoRow(
                        'Customer Name',
                        order.customerName ?? 'N/A',
                      ),
                      _buildInfoRow(
                        'Customer Phone',
                        order.customerPhone ?? 'N/A',
                      ),
                      _buildInfoRow('Table', order.tableNumber ?? 'N/A'),
                      _buildInfoRow(
                        'Source Local ID',
                        order.sourceLocalId?.toString() ?? 'N/A',
                      ),
                      _buildInfoRow('isFromApi', order.isFromApi.toString()),
                      _buildInfoRow(
                        'User ID',
                        order.userId?.toString() ?? 'N/A',
                      ),
                      _buildInfoRow(
                        'Created',
                        order.createdAt.toLocal().toString(),
                      ),
                      _buildInfoRow(
                        'Updated',
                        order.updatedAt.toLocal().toString(),
                      ),
                      if (order.note != null && order.note!.isNotEmpty)
                        _buildInfoRow('Note', order.note!),
                    ],
                  ),
                ),
              ],
            ),
          ),
        )
        .toList();
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>> _loadOrderData() async {
    final allOrders = await DatabaseService.getPosOrders();

    final apiOrders = allOrders
        .where((o) => o.channel.trim().toLowerCase() == 'api')
        .toList();

    final webOrders = allOrders
        .where((o) => o.channel.trim().toLowerCase() == 'web')
        .toList();

    final kioskOrders = allOrders
        .where((o) => o.channel.trim().toLowerCase() == 'kiosk')
        .toList();

    final posOrders = allOrders
        .where((o) => o.channel.trim().toLowerCase() == 'pos')
        .toList();

    // ✅ Load restaurants from local DB
    final restaurants = await DatabaseService.getAllRestaurants();

    // ✅ Get resolved restaurant ID from RestaurantController
    int? resolvedRestaurantId;
    if (Get.isRegistered<RestaurantController>()) {
      resolvedRestaurantId = Get.find<RestaurantController>()
          .getImportedRestaurantId();
    }

    return {
      'allOrders': allOrders,
      'apiOrders': apiOrders,
      'webOrders': webOrders,
      'kioskOrders': kioskOrders,
      'posOrders': posOrders,
      'restaurants': restaurants,
      'resolvedRestaurantId': resolvedRestaurantId,
    };
  }
}
