// ignore_for_file: unused_import

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/pos_controller.dart';
import '../controllers/cash_register_controller.dart';
import '../controllers/restaurant_controller.dart';
import '../services/api_order_pull_service.dart';
import '../services/database_service.dart';
import '../services/notification_sound_service.dart';
import '../theme/app_colors.dart';
import '../utils/app_logger.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  Timer? _pendingOrdersTimer;
  int _currentPendingCount = 0;
  final Set<int> _notifiedOrderIds = {};
  static const Duration _checkInterval = Duration(seconds: 45);

  @override
  void initState() {
    super.initState();
    _startPendingOrdersListener();
  }

  Future<void> _checkPendingOrdersAndPlaySound() async {
    try {
      int? restaurantId;

      if (Get.isRegistered<RestaurantController>()) {
        restaurantId = Get.find<RestaurantController>().getImportedRestaurantId();
      }
      if ((restaurantId == null || restaurantId <= 0) && Get.isRegistered<PosController>()) {
        restaurantId = Get.find<PosController>().restaurantId;
      }
      if ((restaurantId == null || restaurantId <= 0) && Get.isRegistered<AuthController>()) {
        restaurantId = Get.find<AuthController>().currentUser?.restaurantId;
      }
      if (restaurantId == null || restaurantId <= 0) {
        await DatabaseService.init();
        final allRestaurants = await DatabaseService.getAllRestaurants();
        if (allRestaurants.isNotEmpty) {
          final active = allRestaurants.where((r) => r.isActive).toList();
          restaurantId = active.isNotEmpty ? active.first.id : allRestaurants.first.id;
        }
      }

      if (restaurantId == null || restaurantId <= 0) return;

      final apiOrders = await _getApiOrdersWithDetails(restaurantId);
      if (apiOrders.isEmpty) {
        appLogger.d('🔇 [SKIP SOUND] No API orders pending locally');
        return;
      }

      bool shouldPlaySound = false;
      for (final orderData in apiOrders) {
        final remoteOrderId = orderData['remoteOrderId'] as int;
        _notifiedOrderIds.add(remoteOrderId);
        shouldPlaySound = true;
        appLogger.d('🔔 [PLAY SOUND] Remote order $remoteOrderId is pending locally');
      }

      if (shouldPlaySound) {
        try {
          await NotificationSoundService.instance.playNewOrderAlarm();
          await Future.delayed(const Duration(milliseconds: 800));
          await NotificationSoundService.instance.playNewOrderAlarm();
          appLogger.d('✅ [SOUND PLAYED] Notification sound played successfully');

          final localPendingCount = apiOrders.length;
          if (mounted && localPendingCount > 0) {
            Get.snackbar(
              '🔔 Nouvelles commandes API/Web',
              '$localPendingCount commande(s) en attente de traitement',
              snackPosition: SnackPosition.TOP,
              backgroundColor: const Color(0xFF7C3AED),
              colorText: Colors.white,
              duration: const Duration(seconds: 5),
              icon: const Icon(Icons.notifications_active, color: Colors.white),
              margin: const EdgeInsets.all(16),
              borderRadius: 12,
            );
          }
        } catch (e, stackTrace) {
          appLogger.e('Failed to play notification', error: e, stackTrace: stackTrace);
        }
      }

      final pendingCount = await ApiOrderPullService.instance
          .countTrulyPendingApiOrders(restaurantId: restaurantId);
      if (mounted) setState(() => _currentPendingCount = pendingCount);
    } catch (e, stackTrace) {
      appLogger.e('Pending orders check failed', error: e, stackTrace: stackTrace);
    }
  }

  Future<List<Map<String, dynamic>>> _getApiOrdersWithDetails(int restaurantId) async {
    await DatabaseService.init();
    final allOrders = await DatabaseService.getPosOrders();
    final result = <Map<String, dynamic>>[];

    final apiOrders = allOrders.where((o) {
      final channel = o.channel.trim().toLowerCase();
      final isApiOrder = channel == 'api' || channel == 'web' || channel == 'kiosk';
      final isPendingLocally = o.status.trim().toLowerCase() == 'pending';
      return isApiOrder && isPendingLocally;
    }).toList();

    for (final order in apiOrders) {
      final remoteOrderId = (order.sourceLocalId ?? 0) > 0 ? order.sourceLocalId : order.id;
      if (_notifiedOrderIds.contains(remoteOrderId)) continue;
      result.add({'remoteOrderId': remoteOrderId, 'localOrder': order});
    }
    return result;
  }

  void _startPendingOrdersListener() {
    _pendingOrdersTimer?.cancel();
    _pendingOrdersTimer = Timer.periodic(_checkInterval, (_) async {
      await _checkPendingOrdersAndPlaySound();
    });
    unawaited(_checkPendingOrdersAndPlaySound());
  }

  void _showSuperAdminDialog() => Get.toNamed('/admin-pin-login');
  void _showCashierLoginDialog() => Get.toNamed('/cashier-pin-login');

  @override
  Widget build(BuildContext context) {
    Get.find<AuthController>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0A0A0A), Color(0xFF1A1A1A), Color(0xFF2D0A0A)],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _GlowPainter())),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  // ✅ Largeur max élargie pour que les cards respirent
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 40),
                      _buildUnifiedCard(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFFD32F2F).withOpacity(0.8),
                const Color(0xFFB71C1C).withOpacity(0.9),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD32F2F).withOpacity(0.5),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/branding/app_icon.png',
              width: 60,
              height: 60,
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'SOYABOX',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 3,
            shadows: [Shadow(color: Color(0xFFD32F2F), blurRadius: 10)],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Point de Vente',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.7),
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildUnifiedCard() {
    return Container(
      padding: const EdgeInsets.all(20), // ✅ plus d'espace intérieur
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // En-tête de la card
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFD32F2F).withOpacity(0.8),
                      const Color(0xFFB71C1C).withOpacity(0.9),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.lock_outline, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Connexion',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // ✅ Toujours en Row — 3 cartes visibles, sans scroll
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: _buildLoginOption(
                  title: 'POS - Serveur',
                  description: 'Accédez au point de vente avec votre code PIN ou badge',
                  icon: Icons.point_of_sale,
                  iconColor: const Color(0xFFFF5252),
                  buttonLabel: 'Ouvrir POS',
                  route: '/pos-lock',
                  margin: const EdgeInsets.only(right: 8),
                ),
              ),
              Flexible(
                child: _buildLoginOption(
                  title: 'Caissier',
                  description: 'Accédez au tableau de bord caissier avec votre code PIN',
                  icon: Icons.account_balance_wallet,
                  iconColor: const Color(0xFF4CAF50),
                  buttonLabel: 'Connexion Caissier',
                  route: '/cashier-pin-login',
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
              Flexible(
                child: _buildLoginOption(
                  title: 'Admin / Super Admin',
                  description: 'Accédez au tableau de bord avec votre code PIN ou badge',
                  icon: Icons.admin_panel_settings,
                  iconColor: const Color(0xFFFF9800),
                  buttonLabel: 'Connexion Admin',
                  route: '/admin-pin-login',
                  margin: const EdgeInsets.only(left: 8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoginOption({
    required String title,
    required String description,
    required IconData icon,
    required Color iconColor,
    required String buttonLabel,
    required String route,
    required EdgeInsetsGeometry margin,
  }) {
    return Container(
      margin: margin,
      padding: const EdgeInsets.all(28), // ✅ cards plus grandes
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [iconColor.withOpacity(0.8), iconColor.withAlpha(200)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            description,
            style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.75)),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Get.toNamed(route),
              icon: const Icon(Icons.lock_outline, size: 18),
              label: Text(buttonLabel),
              style: ElevatedButton.styleFrom(
                backgroundColor: iconColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pendingOrdersTimer?.cancel();
    super.dispose();
  }
}

class _GlowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p1 = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.5, -0.5),
        radius: 0.8,
        colors: [const Color(0xFFD32F2F).withOpacity(0.15), Colors.transparent],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), p1);

    final p2 = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.8, 0.8),
        radius: 0.6,
        colors: [const Color(0xFFFF1744).withOpacity(0.1), Colors.transparent],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), p2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}