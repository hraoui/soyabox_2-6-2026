import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/sync_controller.dart';
import '../models/daily_sync_models.dart';
import '../theme/app_colors.dart';
import '../utils/app_logger.dart';

// ============================================================
// DAILY SYNC BUTTON WIDGET
// ============================================================

/// Bouton de synchronisation daily des commandes
///
/// Affiche un bouton avec indicateur de progression et notifications
class DailySyncButton extends StatefulWidget {
  final bool showLabel;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const DailySyncButton({
    super.key,
    this.showLabel = true,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  State<DailySyncButton> createState() => _DailySyncButtonState();
}

class _DailySyncButtonState extends State<DailySyncButton> {
  bool _isSyncing = false;

  @override
  Widget build(BuildContext context) {
    final syncController = Get.find<SyncController>();

    return Obx(() {
      final canSync = syncController.isOnline && !_isSyncing;

      return ElevatedButton.icon(
        onPressed: canSync ? _performDailySync : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: widget.backgroundColor ?? AppColors.teal,
          foregroundColor: widget.foregroundColor ?? Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        icon: _isSyncing
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    widget.foregroundColor ?? Colors.white,
                  ),
                ),
              )
            : const Icon(Icons.cloud_upload_outlined, size: 20),
        label: widget.showLabel
            ? Text(
                _isSyncing ? 'Sync...' : 'Daily Sync',
                style: const TextStyle(fontWeight: FontWeight.w600),
              )
            : const SizedBox.shrink(),
      );
    });
  }

  Future<void> _performDailySync() async {
    if (_isSyncing) return;

    setState(() => _isSyncing = true);

    try {
      final syncController = Get.find<SyncController>();

      final response = await syncController.triggerDailyBatchSync(
        showNotifications: true,
      );

      if (!mounted) return;

      if (response != null && response.success) {
        appLogger.i('✅ [DailySync] Sync completed successfully');

        // Show detailed success dialog
        if (response.data != null) {
          _showSyncResultDialog(response);
        }
      } else {
        appLogger.e('❌ [DailySync] Sync failed: ${response?.message}');
      }
    } catch (e, stackTrace) {
      if (!mounted) return;

      appLogger.e(
        '🔥 [DailySync] Unexpected error',
        error: e,
        stackTrace: stackTrace,
      );

      if (mounted) {
        Get.snackbar(
          'Erreur 🔥',
          e.toString(),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.9),
          colorText: Colors.white,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  void _showSyncResultDialog(DailySyncResponse response) {
    if (response.data == null) return;

    final stats = response.data!;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              stats.failed > 0 ? Icons.warning : Icons.check_circle,
              color: stats.failed > 0 ? Colors.orange : Colors.green,
              size: 28,
            ),
            const SizedBox(width: 12),
            const Text('Résultat de Synchronisation'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${stats.inserted} commandes insérées',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${stats.skipped} commandes ignorées',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 8),
              Text(
                '${stats.failed} commandes échouées',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: stats.failed > 0 ? FontWeight.w600 : null,
                  color: stats.failed > 0 ? Colors.red : Colors.grey.shade700,
                ),
              ),
              const Divider(height: 24),
              Text(
                'Total: ${stats.total} commandes',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (stats.errors != null && stats.errors!.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Erreurs:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 8),
                ...stats.errors!
                    .take(5)
                    .map(
                      (error) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '• ${error.message}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                if (stats.errors!.length > 5)
                  Text(
                    '... et ${stats.errors!.length - 5} autres erreurs',
                    style: const TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// DAILY SYNC STATUS CARD
// ============================================================

/// Carte affichant les statistiques de synchronisation
class DailySyncStatusCard extends StatelessWidget {
  final DailySyncStats? stats;
  final VoidCallback? onRefresh;

  const DailySyncStatusCard({super.key, this.stats, this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (stats == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Column(
              children: [
                const Icon(Icons.cloud_outlined, size: 48, color: Colors.grey),
                const SizedBox(height: 8),
                Text(
                  'Aucune synchronisation effectuée',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Statistiques de Synchronisation',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (onRefresh != null)
                  IconButton(
                    onPressed: onRefresh,
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Rafraîchir',
                  ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildStatItem(
                  'Total',
                  stats!.total.toString(),
                  Icons.list,
                  Colors.blue,
                ),
                const SizedBox(width: 16),
                _buildStatItem(
                  'Insérées',
                  stats!.inserted.toString(),
                  Icons.check_circle,
                  Colors.green,
                ),
                const SizedBox(width: 16),
                _buildStatItem(
                  'Ignorées',
                  stats!.skipped.toString(),
                  Icons.skip_next,
                  Colors.orange,
                ),
                const SizedBox(width: 16),
                _buildStatItem(
                  'Échouées',
                  stats!.failed.toString(),
                  Icons.error,
                  stats!.failed > 0 ? Colors.red : Colors.grey,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// DAILY REPORT WIDGET
// ============================================================

/// Widget affichant le rapport daily
class DailyReportWidget extends StatefulWidget {
  final int? restaurantId;
  final DateTime? date;

  const DailyReportWidget({super.key, this.restaurantId, this.date});

  @override
  State<DailyReportWidget> createState() => _DailyReportWidgetState();
}

class _DailyReportWidgetState extends State<DailyReportWidget> {
  bool _isLoading = false;
  DailyReportData? _reportData;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchReport();
  }

  Future<void> _fetchReport() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final syncController = Get.find<SyncController>();

      final response = await syncController.fetchDailyReport(date: widget.date);

      if (!mounted) return;

      if (response != null && response.success && response.data != null) {
        setState(() {
          _reportData = response.data;
        });
      } else {
        setState(() {
          _error = response?.message ?? 'Erreur inconnue';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Chargement du rapport...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 8),
            Text('Erreur: $_error'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _fetchReport,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_reportData == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text('Aucun rapport disponible'),
          ],
        ),
      );
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Rapport Journalier',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    Text(
                      _reportData!.date,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _fetchReport,
                      icon: const Icon(Icons.refresh, size: 20),
                      tooltip: 'Rafraîchir',
                    ),
                  ],
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildInfoCard(
                    'Total Commandes',
                    _reportData!.totalOrders.toString(),
                    Icons.receipt,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInfoCard(
                    'Revenu Total',
                    '${_reportData!.totalRevenue.toStringAsFixed(2)} FCFA',
                    Icons.attach_money,
                    Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
