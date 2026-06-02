#!/usr/bin/env dart
// Check local Isar database for API/Web orders
// Run from project root: flutter run -d macos --target=lib/tools/check_local_api_orders.dart

import 'package:isar/isar.dart';
import '../utils/path_utils.dart';
import '../models/pos_order.dart';
import '../models/pos_order_item.dart';

Future<void> main() async {
  print('🔍 Checking local database for API/Web orders...\n');

  try {
    // Initialize Isar
    final dir = await getAppDocumentsDirectory();
    final isar = await Isar.open(
      [PosOrderSchema, PosOrderItemSchema],
      directory: dir.path,
    );

    // Get all orders
    final allOrders = await isar.posOrders.where().sortByCreatedAtDesc().findAll();
    print('📊 Total orders in local database: ${allOrders.length}\n');

    // Filter API/Web orders
    final apiOrders = allOrders.where((o) => 
      o.channel.trim().toLowerCase() == 'api'
    ).toList();
    
    final webOrders = allOrders.where((o) => 
      o.channel.trim().toLowerCase() == 'web'
    ).toList();
    
    final kioskOrders = allOrders.where((o) => 
      o.channel.trim().toLowerCase() == 'kiosk'
    ).toList();
    
    final posOrders = allOrders.where((o) => 
      o.channel.trim().toLowerCase() == 'pos'
    ).toList();

    print('📡 API channel orders: ${apiOrders.length}');
    print('🌐 Web channel orders: ${webOrders.length}');
    print('🖥️  Kiosk channel orders: ${kioskOrders.length}');
    print('💻 POS channel orders: ${posOrders.length}\n');

    if (apiOrders.isEmpty && webOrders.isEmpty && kioskOrders.isEmpty) {
      print('⚠️  No API/Web/Kiosk orders found in local database.');
      print('💡 This means:');
      print('   - Either no orders have been received from backend yet');
      print('   - Or sync from backend is not working properly');
      print('   - Check sync logs for errors');
    } else {
      // Display API/Web/Kiosk orders
      final incomingOrders = [...apiOrders, ...webOrders, ...kioskOrders];
      print('✅ Found ${incomingOrders.length} order(s) from backend:\n');
      
      for (int i = 0; i < incomingOrders.length; i++) {
        final order = incomingOrders[i];
        print('┌─ Order #${order.id}');
        print('│  Channel: ${order.channel}');
        print('│  Status: ${order.status}');
        print('│  Payment: ${order.paymentStatus}');
        print('│  Total: ${order.totalPrice.toStringAsFixed(2)} MAD');
        print('│  Fulfillment: ${order.fulfillmentType}');
        print('│  Customer: ${order.customerName ?? 'N/A'} (${order.customerPhone ?? 'N/A'})');
        print('│  Table: ${order.tableNumber ?? 'N/A'}');
        print('│  Source Local ID: ${order.sourceLocalId}');
        print('│  isFromApi: ${order.isFromApi}');
        print('│  Created: ${order.createdAt.toLocal()}');
        print('│  Updated: ${order.updatedAt.toLocal()}');
        if (order.note != null && order.note!.isNotEmpty) {
          print('│  Note: ${order.note}');
        }
        print('└─────────────────────────────────\n');
      }
    }

    // Check recent sync activity
    print('\n🔄 Checking last 10 orders (all channels):');
    final recentOrders = allOrders.take(10);
    for (final order in recentOrders) {
      final channelTag = '[${order.channel.toUpperCase()}]';
      print('  $channelTag #${order.id} - ${order.status} - ${order.totalPrice.toStringAsFixed(2)} MAD - ${order.createdAt.toLocal()}');
    }

    await isar.close();
  } catch (e, st) {
    print('❌ Error checking database: $e');
    print('Stack trace: $st');
  }
}
