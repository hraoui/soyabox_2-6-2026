# 🚀 Système de Rapport Journalier de la Caisse

## 📋 Vue d'Ensemble

Créer un **système isolé** qui permet d'envoyer un rapport journalier complet de la caisse vers le backend, **sans modifier aucun code existant**.

### 🎯 Objectifs

1. ✅ **Isolation totale** - Aucun fichier existant modifié
2. ✅ **Rapport journalier** - Toutes les statistiques du jour
3. ✅ **Bouton "Envoyer Rapport"** - Dans l'interface admin
4. ✅ **Backend séparé** - Espace dédié pour archiver les rapports
5. ✅ **Consultation** - Admin backend peut voir le statut de la caisse

---

## 🏗️ Architecture Proposée

### 🔵 Système Actuel (NE PAS TOUCHER)

```
┌─────────────────────────────────────────────────────────┐
│  SYSTÈME DE SYNC ACTUEL (existant)                      │
│                                                          │
│  - SyncQueueService (PUSH)                              │
│  - ApiOrderPullService (PULL)                           │
│  - SyncController (orchestrateur)                       │
│  - Endpoints: /api/sync/public/*                        │
│                                                          │
│  ⚠️ NE PAS MODIFIER CE SYSTÈME                          │
└─────────────────────────────────────────────────────────┘
```

### 🟢 Nouveau Système de Rapport (ISOLÉ)

```
┌─────────────────────────────────────────────────────────┐
│  NOUVEAU SYSTÈME DE RAPPORT (isolé)                     │
│                                                          │
│  Fichiers Flutter (NOUVEAUX):                           │
│  ├─ lib/services/daily_report_service.dart              │
│  ├─ lib/models/daily_report.dart                        │
│  └─ lib/views/send_report_button.dart                   │
│                                                          │
│  Backend Laravel (NOUVEAU):                             │
│  ├─ routes/api.php (nouvelles routes)                   │
│  ├─ app/Http/Controllers/DailyReportController.php      │
│  ├─ app/Models/CashRegisterReport.php                   │
│  ├─ database/migrations/create_cash_register_reports      │
│  └─ resources/views/admin/reports/*                     │
│                                                          │
│  Endpoint: POST /api/cash-reports/daily-report          │
│  Endpoint: GET  /api/cash-reports                       │
│                                                          │
│  ✅ Totalement isolé du système de sync existant        │
└─────────────────────────────────────────────────────────┘
```

---

## 📱 Partie Flutter (Application Caisse)

### Fichier 1: `lib/models/daily_report.dart`

```dart
import 'package:isar/isar.dart';

part 'daily_report.g.dart';

/// Modèle pour le rapport journalier de la caisse
@Collection()
class DailyReport {
  Id id = Isar.autoIncrement;
  
  // Date du rapport
  late String reportDate; // Format: YYYY-MM-DD
  
  // Informations de la caisse
  late int restaurantId;
  String? restaurantName;
  late int staffId; // Serveur qui a généré le rapport
  String? staffName;
  
  // Statistiques globales
  double totalRevenue = 0.0;
  int totalOrders = 0;
  int tableOrders = 0;
  int remoteOrders = 0;
  
  // Répartition par méthode de paiement
  double cashTotal = 0.0;
  double tpeTotal = 0.0;
  double enCompteTotal = 0.0;
  double otherTotal = 0.0;
  
  // Répartition par type de commande
  int onsiteCount = 0;
  int pickupCount = 0;
  int deliveryCount = 0;
  double onsiteRevenue = 0.0;
  double pickupRevenue = 0.0;
  double deliveryRevenue = 0.0;
  
  // Répartition par canal
  double posRevenue = 0.0;
  double apiRevenue = 0.0;
  
  // Statistiques par serveur (JSON)
  String? staffBreakdown; // JSON array de {staff_id, name, orders, revenue, cash, tpe, en_compte}
  
  // Statut de synchronisation
  int syncQueueSize = 0;
  bool syncSuccess = false;
  String? lastSyncAt;
  
  // Horodatage
  late DateTime createdAt;
  late DateTime sentAt; // Quand envoyé au backend
  
  // Statut d'envoi
  @Index()
  String reportStatus = 'pending'; // pending, sent, failed
  
  DailyReport({
    this.id = Isar.autoIncrement,
    required this.reportDate,
    required this.restaurantId,
    this.restaurantName,
    required this.staffId,
    this.staffName,
    this.totalRevenue = 0.0,
    this.totalOrders = 0,
    this.tableOrders = 0,
    this.remoteOrders = 0,
    this.cashTotal = 0.0,
    this.tpeTotal = 0.0,
    this.enCompteTotal = 0.0,
    this.otherTotal = 0.0,
    this.onsiteCount = 0,
    this.pickupCount = 0,
    this.deliveryCount = 0,
    this.onsiteRevenue = 0.0,
    this.pickupRevenue = 0.0,
    this.deliveryRevenue = 0.0,
    this.posRevenue = 0.0,
    this.apiRevenue = 0.0,
    this.staffBreakdown,
    this.syncQueueSize = 0,
    this.syncSuccess = false,
    this.lastSyncAt,
    required this.createdAt,
    required this.sentAt,
    this.reportStatus = 'pending',
  });
  
  /// Convertir en JSON pour l'envoi au backend
  Map<String, dynamic> toJson() {
    return {
      'report_date': reportDate,
      'restaurant_id': restaurantId,
      'restaurant_name': restaurantName,
      'staff_id': staffId,
      'staff_name': staffName,
      'total_revenue': totalRevenue,
      'total_orders': totalOrders,
      'table_orders': tableOrders,
      'remote_orders': remoteOrders,
      'cash_total': cashTotal,
      'tpe_total': tpeTotal,
      'en_compte_total': enCompteTotal,
      'other_total': otherTotal,
      'onsite_count': onsiteCount,
      'pickup_count': pickupCount,
      'delivery_count': deliveryCount,
      'onsite_revenue': onsiteRevenue,
      'pickup_revenue': pickupRevenue,
      'delivery_revenue': deliveryRevenue,
      'pos_revenue': posRevenue,
      'api_revenue': apiRevenue,
      'staff_breakdown': staffBreakdown,
      'sync_queue_size': syncQueueSize,
      'sync_success': syncSuccess,
      'last_sync_at': lastSyncAt,
      'created_at': createdAt.toIso8601String(),
      'sent_at': sentAt.toIso8601String(),
    };
  }
  
  /// Créer un rapport depuis les données actuelles de la caisse
  static Future<DailyReport> generate({
    required String reportDate,
    required int restaurantId,
    required int staffId,
    required String staffName,
  }) async {
    final now = DateTime.now();
    final report = DailyReport(
      reportDate: reportDate,
      restaurantId: restaurantId,
      staffName: staffName,
      createdAt: now,
      sentAt: now,
    );
    
    // TODO: Calculer les statistiques depuis DatabaseService
    // Ce code lit les données existantes SANS les modifier
    
    return report;
  }
}
```

### Fichier 2: `lib/services/daily_report_service.dart`

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/daily_report.dart';
import '../data/app_constants.dart';
import '../services/database_service.dart';
import '../services/auth_session_service.dart';
import '../utils/app_logger.dart';

/// Service pour générer et envoyer les rapports journaliers
/// ✅ Totalement isolé du système de sync existant
class DailyReportService {
  static const String _reportEndpoint = '/api/cash-reports/daily-report';
  
  /// Générer le rapport du jour
  static Future<DailyReport> generateTodayReport() async {
    final today = DateTime.now();
    final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    
    // Obtenir les infos du staff actif (depuis AuthSessionService ou PosController)
    final staffId = _getCurrentStaffId();
    final staffName = _getCurrentStaffName();
    final restaurantId = _getCurrentRestaurantId();
    
    // Générer le rapport
    return await DailyReport.generate(
      reportDate: dateStr,
      restaurantId: restaurantId,
      staffId: staffId,
      staffName: staffName,
    );
  }
  
  /// Envoyer le rapport au backend
  static Future<bool> sendReport(DailyReport report) async {
    try {
      final baseUrl = AppConstants.baseUrl;
      final url = '$baseUrl$_reportEndpoint';
      
      // Obtenir le token d'authentification
      final token = AuthSessionService.instance.tokenOrFallback;
      
      // Préparer les headers
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token.isNotEmpty) 'Authorization': 'Bearer $token',
      };
      
      // Envoyer le rapport
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(report.toJson()),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        appLogger.i('✅ Rapport envoyé avec succès: ${report.reportDate}');
        
        // Mettre à jour le statut du rapport
        report.reportStatus = 'sent';
        report.syncSuccess = true;
        report.sentAt = DateTime.now();
        
        // Sauvegarder localement (nouvelle collection Isar, n'affecte PAS l'existant)
        await _saveReport(report);
        
        return true;
      } else {
        appLogger.e('❌ Échec envoi rapport: ${response.statusCode} - ${response.body}');
        report.reportStatus = 'failed';
        report.syncSuccess = false;
        await _saveReport(report);
        return false;
      }
    } catch (e) {
      appLogger.e('❌ Erreur envoi rapport: $e');
      report.reportStatus = 'failed';
      report.syncSuccess = false;
      await _saveReport(report);
      return false;
    }
  }
  
  /// Sauvegarder le rapport localement (nouvelle collection Isar)
  static Future<void> _saveReport(DailyReport report) async {
    // Utiliser une nouvelle collection Isar 'dailyReports'
    // N'affecte PAS les collections existantes
    final isar = await Isar.open([DailyReportSchema]);
    await isar.writeTxn(() async {
      await isar.dailyReports.put(report);
    });
  }
  
  /// Historique des rapports envoyés
  static Future<List<DailyReport>> getReportHistory() async {
    final isar = await Isar.open([DailyReportSchema]);
    return await isar.dailyReports
        .filter()
        .reportStatusEqualTo('sent')
        .sortByCreatedAtDesc()
        .findAll();
  }
  
  // Helpers (à adapter selon votre architecture)
  static int _getCurrentStaffId() {
    // Obtenir depuis PosController.activeStaffId ou AuthSessionService
    return 0;
  }
  
  static String _getCurrentStaffName() {
    // Obtenir depuis PosController.activeStaff
    return 'Inconnu';
  }
  
  static int _getCurrentRestaurantId() {
    // Obtenir depuis PosController ou AppSettingsService
    return 0;
  }
}
```

### Fichier 3: `lib/widgets/send_report_button.dart`

```dart
import 'package:flutter/material.dart';
import '../services/daily_report_service.dart';
import '../theme/sushi_design.dart';

/// Bouton "Envoyer Rapport" à ajouter dans le menu admin
/// ✅ Nouveau widget, ne modifie AUCUN widget existant
class SendReportButton extends StatefulWidget {
  const SendReportButton({super.key});
  
  @override
  State<SendReportButton> createState() => _SendReportButtonState();
}

class _SendReportButtonState extends State<SendReportButton> {
  bool _isSending = false;
  String? _lastResult;
  
  Future<void> _sendReport() async {
    setState(() {
      _isSending = true;
      _lastResult = null;
    });
    
    try {
      // Générer le rapport
      final report = await DailyReportService.generateTodayReport();
      
      // Envoyer au backend
      final success = await DailyReportService.sendReport(report);
      
      setState(() {
        _isSending = false;
        _lastResult = success ? '✅ Rapport envoyé avec succès' : '❌ Échec de l\'envoi';
      });
      
      // Afficher le résultat
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_lastResult!),
            backgroundColor: success ? SushiColors.green : SushiColors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSending = false;
        _lastResult = '❌ Erreur: $e';
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: _isSending ? null : _sendReport,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(
                Icons.cloud_upload_outlined,
                size: 48,
                color: _isSending ? SushiColors.orange : SushiColors.teal,
              ),
              const SizedBox(height: 12),
              Text(
                'Envoyer Rapport',
                style: SushiTypo.h3,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Envoyer le rapport journalier au backend',
                style: SushiTypo.bodySm,
                textAlign: TextAlign.center,
              ),
              if (_isSending) ...[
                const SizedBox(height: 12),
                const CircularProgressIndicator(),
              ],
              if (_lastResult != null) ...[
                const SizedBox(height: 12),
                Text(
                  _lastResult!,
                  style: TextStyle(
                    color: _lastResult!.contains('✅') 
                        ? SushiColors.green 
                        : SushiColors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
```

### Où Ajouter le Bouton (NOUVEAU fichier ou écran)

**Option 1: Créer un nouvel écran dédié**

```dart
// lib/views/cash_reports_screen.dart
import 'package:flutter/material.dart';
import '../widgets/send_report_button.dart';
import '../services/daily_report_service.dart';

class CashReportsScreen extends StatefulWidget {
  const CashReportsScreen({super.key});
  
  @override
  State<CashReportsScreen> createState() => _CashReportsScreenState();
}

class _CashReportsScreenState extends State<CashReportsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rapports de Caisse'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SendReportButton(),
          const SizedBox(height: 24),
          const Text(
            'Historique des Rapports',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          // Future: Afficher l'historique depuis DailyReportService.getReportHistory()
        ],
      ),
    );
  }
}
```

**Option 2: Ajouter dans le menu admin existant (sans le modifier)**

Créer un nouveau fichier de menu séparé qui étend les fonctionnalités:

```dart
// lib/views/admin_reports_menu_screen.dart
// Nouvel écran accessible depuis le dashboard admin
```

---

## 🌐 Partie Backend (Laravel)

### 1. Migration

```php
// database/migrations/2026_04_06_000000_create_cash_register_reports_table.php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('cash_register_reports', function (Blueprint $table) {
            $table->id();
            
            // Date du rapport
            $table->date('report_date');
            
            // Informations de la caisse
            $table->unsignedBigInteger('restaurant_id');
            $table->string('restaurant_name')->nullable();
            $table->unsignedBigInteger('staff_id');
            $table->string('staff_name')->nullable();
            
            // Statistiques globales
            $table->decimal('total_revenue', 15, 2)->default(0);
            $table->integer('total_orders')->default(0);
            $table->integer('table_orders')->default(0);
            $table->integer('remote_orders')->default(0);
            
            // Répartition par méthode de paiement
            $table->decimal('cash_total', 15, 2)->default(0);
            $table->decimal('tpe_total', 15, 2)->default(0);
            $table->decimal('en_compte_total', 15, 2)->default(0);
            $table->decimal('other_total', 15, 2)->default(0);
            
            // Répartition par type de commande
            $table->integer('onsite_count')->default(0);
            $table->integer('pickup_count')->default(0);
            $table->integer('delivery_count')->default(0);
            $table->decimal('onsite_revenue', 15, 2)->default(0);
            $table->decimal('pickup_revenue', 15, 2)->default(0);
            $table->decimal('delivery_revenue', 15, 2)->default(0);
            
            // Répartition par canal
            $table->decimal('pos_revenue', 15, 2)->default(0);
            $table->decimal('api_revenue', 15, 2)->default(0);
            
            // Statistiques par serveur (JSON)
            $table->json('staff_breakdown')->nullable();
            
            // Statut de synchronisation
            $table->integer('sync_queue_size')->default(0);
            $table->boolean('sync_success')->default(false);
            $table->timestamp('last_sync_at')->nullable();
            
            // Horodatage
            $table->timestamps();
            
            // Index pour les requêtes rapides
            $table->index(['report_date', 'restaurant_id']);
            $table->index('staff_id');
        });
    }
    
    public function down(): void
    {
        Schema::dropIfExists('cash_register_reports');
    }
};
```

### 2. Modèle

```php
// app/Models/CashRegisterReport.php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class CashRegisterReport extends Model
{
    use HasFactory;
    
    protected $table = 'cash_register_reports';
    
    protected $fillable = [
        'report_date',
        'restaurant_id',
        'restaurant_name',
        'staff_id',
        'staff_name',
        'total_revenue',
        'total_orders',
        'table_orders',
        'remote_orders',
        'cash_total',
        'tpe_total',
        'en_compte_total',
        'other_total',
        'onsite_count',
        'pickup_count',
        'delivery_count',
        'onsite_revenue',
        'pickup_revenue',
        'delivery_revenue',
        'pos_revenue',
        'api_revenue',
        'staff_breakdown',
        'sync_queue_size',
        'sync_success',
        'last_sync_at',
    ];
    
    protected $casts = [
        'report_date' => 'date',
        'staff_breakdown' => 'array',
        'sync_success' => 'boolean',
        'last_sync_at' => 'datetime',
    ];
    
    // Relations
    public function restaurant()
    {
        return $this->belongsTo(Restaurant::class);
    }
    
    public function staff()
    {
        return $this->belongsTo(User::class, 'staff_id');
    }
}
```

### 3. Contrôleur

```php
// app/Http/Controllers/DailyReportController.php

namespace App\Http\Controllers;

use App\Models\CashRegisterReport;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class DailyReportController extends Controller
{
    /**
     * Recevoir un rapport journalier de la caisse
     * POST /api/cash-reports/daily-report
     */
    public function storeDailyReport(Request $request)
    {
        try {
            // Validation des données
            $validated = $request->validate([
                'report_date' => 'required|date',
                'restaurant_id' => 'required|integer',
                'restaurant_name' => 'nullable|string',
                'staff_id' => 'required|integer',
                'staff_name' => 'nullable|string',
                'total_revenue' => 'required|numeric|min:0',
                'total_orders' => 'required|integer|min:0',
                'table_orders' => 'required|integer|min:0',
                'remote_orders' => 'required|integer|min:0',
                'cash_total' => 'required|numeric|min:0',
                'tpe_total' => 'required|numeric|min:0',
                'en_compte_total' => 'required|numeric|min:0',
                'other_total' => 'required|numeric|min:0',
                'onsite_count' => 'required|integer|min:0',
                'pickup_count' => 'required|integer|min:0',
                'delivery_count' => 'required|integer|min:0',
                'onsite_revenue' => 'required|numeric|min:0',
                'pickup_revenue' => 'required|numeric|min:0',
                'delivery_revenue' => 'required|numeric|min:0',
                'pos_revenue' => 'required|numeric|min:0',
                'api_revenue' => 'required|numeric|min:0',
                'staff_breakdown' => 'nullable|string',
                'sync_queue_size' => 'required|integer|min:0',
                'sync_success' => 'required|boolean',
                'last_sync_at' => 'nullable|date',
                'created_at' => 'required|date',
                'sent_at' => 'required|date',
            ]);
            
            // Vérifier si un rapport existe déjà pour cette date et restaurant
            $existingReport = CashRegisterReport::where('report_date', $validated['report_date'])
                ->where('restaurant_id', $validated['restaurant_id'])
                ->first();
            
            if ($existingReport) {
                // Mettre à jour le rapport existant
                $existingReport->update($validated);
                $report = $existingReport;
                
                Log::info('📊 Rapport de caisse mis à jour', [
                    'date' => $report->report_date,
                    'restaurant_id' => $report->restaurant_id,
                ]);
            } else {
                // Créer un nouveau rapport
                $report = CashRegisterReport::create($validated);
                
                Log::info('✅ Nouveau rapport de caisse reçu', [
                    'date' => $report->report_date,
                    'restaurant_id' => $report->restaurant_id,
                    'staff_id' => $report->staff_id,
                ]);
            }
            
            return response()->json([
                'success' => true,
                'message' => 'Rapport enregistré avec succès',
                'data' => $report,
            ], 201);
            
        } catch (\Exception $e) {
            Log::error('❌ Erreur réception rapport de caisse', [
                'error' => $e->getMessage(),
                'payload' => $request->all(),
            ]);
            
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de l\'enregistrement du rapport',
                'error' => $e->getMessage(),
            ], 500);
        }
    }
    
    /**
     * Lister tous les rapports
     * GET /api/cash-reports
     */
    public function index(Request $request)
    {
        $query = CashRegisterReport::with(['restaurant', 'staff']);
        
        // Filtres optionnels
        if ($request->has('restaurant_id')) {
            $query->where('restaurant_id', $request->restaurant_id);
        }
        
        if ($request->has('date_from')) {
            $query->whereDate('report_date', '>=', $request->date_from);
        }
        
        if ($request->has('date_to')) {
            $query->whereDate('report_date', '<=', $request->date_to);
        }
        
        if ($request->has('staff_id')) {
            $query->where('staff_id', $request->staff_id);
        }
        
        $reports = $query->orderByDesc('report_date')->paginate(20);
        
        return response()->json($reports);
    }
    
    /**
     * Voir un rapport détaillé
     * GET /api/cash-reports/{id}
     */
    public function show($id)
    {
        $report = CashRegisterReport::with(['restaurant', 'staff'])->findOrFail($id);
        
        return response()->json([
            'success' => true,
            'data' => $report,
        ]);
    }
    
    /**
     * Dashboard des rapports (statistiques agrégées)
     * GET /api/cash-reports/dashboard
     */
    public function dashboard(Request $request)
    {
        $dateFrom = $request->input('date_from', now()->startOfMonth());
        $dateTo = $request->input('date_to', now()->endOfMonth());
        $restaurantId = $request->input('restaurant_id');
        
        $query = CashRegisterReport::whereBetween('report_date', [$dateFrom, $dateTo]);
        
        if ($restaurantId) {
            $query->where('restaurant_id', $restaurantId);
        }
        
        $stats = $query->selectRaw('
            COUNT(*) as total_reports,
            SUM(total_revenue) as total_revenue,
            SUM(total_orders) as total_orders,
            SUM(cash_total) as total_cash,
            SUM(tpe_total) as total_tpe,
            SUM(en_compte_total) as total_en_compte,
            AVG(sync_queue_size) as avg_queue_size,
            SUM(CASE WHEN sync_success = 1 THEN 1 ELSE 0 END) as successful_syncs
        ')->first();
        
        // Rapports par jour
        $dailyReports = CashRegisterReport::whereBetween('report_date', [$dateFrom, $dateTo])
            ->when($restaurantId, fn($q) => $q->where('restaurant_id', $restaurantId))
            ->orderByDesc('report_date')
            ->get();
        
        return response()->json([
            'success' => true,
            'data' => [
                'period' => [
                    'from' => $dateFrom,
                    'to' => $dateTo,
                ],
                'stats' => $stats,
                'daily_reports' => $dailyReports,
            ],
        ]);
    }
}
```

### 4. Routes API

```php
// routes/api.php

use App\Http\Controllers\DailyReportController;

// ... vos routes existantes (NE PAS TOUCHER) ...

// ============================================
// NOUVELLES ROUTES: Rapports de Caisse
// ============================================
// Ces routes sont ISOLÉES du système de sync existant

Route::prefix('cash-reports')->group(function () {
    // Recevoir un rapport journalier (depuis la caisse)
    Route::post('/daily-report', [DailyReportController::class, 'storeDailyReport']);
    
    // Lister les rapports (pour l'admin backend)
    Route::get('/', [DailyReportController::class, 'index']);
    
    // Voir un rapport détaillé
    Route::get('/{id}', [DailyReportController::class, 'show']);
    
    // Dashboard des rapports (statistiques agrégées)
    Route::get('/dashboard', [DailyReportController::class, 'dashboard']);
});
```

### 5. Vue Admin Backend (Exemple Blade)

```blade
{{-- resources/views/admin/reports/index.blade.php --}}

@extends('layouts.admin')

@section('content')
<div class="container mx-auto px-4 py-8">
    <h1 class="text-3xl font-bold mb-6">📊 Rapports de Caisse</h1>
    
    <!-- Filtres -->
    <div class="bg-white rounded-lg shadow p-6 mb-6">
        <form method="GET" action="{{ route('admin.reports.index') }}" class="grid grid-cols-1 md:grid-cols-4 gap-4">
            <div>
                <label class="block text-sm font-medium mb-2">Date début</label>
                <input type="date" name="date_from" value="{{ request('date_from') }}" class="w-full border rounded px-3 py-2">
            </div>
            <div>
                <label class="block text-sm font-medium mb-2">Date fin</label>
                <input type="date" name="date_to" value="{{ request('date_to') }}" class="w-full border rounded px-3 py-2">
            </div>
            <div>
                <label class="block text-sm font-medium mb-2">Restaurant</label>
                <select name="restaurant_id" class="w-full border rounded px-3 py-2">
                    <option value="">Tous</option>
                    @foreach($restaurants as $restaurant)
                        <option value="{{ $restaurant->id }}" {{ request('restaurant_id') == $restaurant->id ? 'selected' : '' }}>
                            {{ $restaurant->name }}
                        </option>
                    @endforeach
                </select>
            </div>
            <div class="flex items-end">
                <button type="submit" class="bg-blue-500 text-white px-4 py-2 rounded hover:bg-blue-600">
                    Filtrer
                </button>
            </div>
        </form>
    </div>
    
    <!-- Statistiques -->
    <div class="grid grid-cols-1 md:grid-cols-4 gap-6 mb-6">
        <div class="bg-white rounded-lg shadow p-6">
            <h3 class="text-sm text-gray-600 mb-2">Total Rapports</h3>
            <p class="text-3xl font-bold">{{ $stats->total_reports ?? 0 }}</p>
        </div>
        <div class="bg-white rounded-lg shadow p-6">
            <h3 class="text-sm text-gray-600 mb-2">CA Total</h3>
            <p class="text-3xl font-bold text-green-600">{{ number_format($stats->total_revenue ?? 0, 2) }} DA</p>
        </div>
        <div class="bg-white rounded-lg shadow p-6">
            <h3 class="text-sm text-gray-600 mb-2">Total Commandes</h3>
            <p class="text-3xl font-bold">{{ $stats->total_orders ?? 0 }}</p>
        </div>
        <div class="bg-white rounded-lg shadow p-6">
            <h3 class="text-sm text-gray-600 mb-2">Sync Réussies</h3>
            <p class="text-3xl font-bold text-blue-600">{{ $stats->successful_syncs ?? 0 }}</p>
        </div>
    </div>
    
    <!-- Tableau des rapports -->
    <div class="bg-white rounded-lg shadow overflow-hidden">
        <table class="min-w-full">
            <thead class="bg-gray-50">
                <tr>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Date</th>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Restaurant</th>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Serveur</th>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">CA</th>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Commandes</th>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Espèces</th>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">TPE</th>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Actions</th>
                </tr>
            </thead>
            <tbody class="divide-y divide-gray-200">
                @foreach($reports as $report)
                <tr>
                    <td class="px-6 py-4 whitespace-nowrap">{{ $report->report_date->format('d/m/Y') }}</td>
                    <td class="px-6 py-4 whitespace-nowrap">{{ $report->restaurant_name }}</td>
                    <td class="px-6 py-4 whitespace-nowrap">{{ $report->staff_name }}</td>
                    <td class="px-6 py-4 whitespace-nowrap font-semibold text-green-600">
                        {{ number_format($report->total_revenue, 2) }} DA
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap">{{ $report->total_orders }}</td>
                    <td class="px-6 py-4 whitespace-nowrap">{{ number_format($report->cash_total, 2) }} DA</td>
                    <td class="px-6 py-4 whitespace-nowrap">{{ number_format($report->tpe_total, 2) }} DA</td>
                    <td class="px-6 py-4 whitespace-nowrap">
                        <a href="{{ route('admin.reports.show', $report->id) }}" class="text-blue-600 hover:text-blue-800">
                            Voir détails
                        </a>
                    </td>
                </tr>
                @endforeach
            </tbody>
        </table>
    </div>
    
    <!-- Pagination -->
    <div class="mt-6">
        {{ $reports->links() }}
    </div>
</div>
@endsection
```

---

## 📊 Structure du Rapport JSON Envoyé

```json
{
  "report_date": "2026-04-06",
  "restaurant_id": 1,
  "restaurant_name": "Soyabox Mohammedia",
  "staff_id": 5,
  "staff_name": "Ahmed Serveur",
  "total_revenue": 15750.50,
  "total_orders": 45,
  "table_orders": 28,
  "remote_orders": 17,
  "cash_total": 8500.00,
  "tpe_total": 5250.50,
  "en_compte_total": 2000.00,
  "other_total": 0.00,
  "onsite_count": 28,
  "pickup_count": 10,
  "delivery_count": 7,
  "onsite_revenue": 10500.00,
  "pickup_revenue": 3250.50,
  "delivery_revenue": 2000.00,
  "pos_revenue": 12500.00,
  "api_revenue": 3250.50,
  "staff_breakdown": "[{\"staff_id\":5,\"name\":\"Ahmed\",\"orders\":25,\"revenue\":8500},{\"staff_id\":8,\"name\":\"Karim\",\"orders\":20,\"revenue\":7250.50}]",
  "sync_queue_size": 3,
  "sync_success": true,
  "last_sync_at": "2026-04-06T16:30:00.000Z",
  "created_at": "2026-04-06T18:00:00.000Z",
  "sent_at": "2026-04-06T18:00:05.000Z"
}
```

---

## 🔒 Isolation Garantie

### ✅ Ce qui est NOUVEAU (ne touche PAS l'existant)

| Élément | Fichier | Impact sur l'existant |
|---------|---------|----------------------|
| `DailyReport` model | `lib/models/daily_report.dart` | ❌ Aucun |
| `DailyReportService` | `lib/services/daily_report_service.dart` | ❌ Aucun |
| `SendReportButton` | `lib/widgets/send_report_button.dart` | ❌ Aucun |
| `CashReportsScreen` | `lib/views/cash_reports_screen.dart` | ❌ Aucun |
| Collection Isar `dailyReports` | Nouvelle collection | ❌ Aucune |
| Endpoint `/api/cash-reports/*` | Laravel routes | ❌ Aucun |
| Table `cash_register_reports` | Laravel migration | ❌ Aucune |

### ❌ Ce qui n'est PAS modifié

- ❌ `sync_queue_service.dart` (existant)
- ❌ `api_order_pull_service.dart` (existant)
- ❌ `sync_controller.dart` (existant)
- ❌ `database_service.dart` (existant)
- ❌ `pos_controller.dart` (existant)
- ❌ Toutes les collections Isar existantes
- ❌ Tous les endpoints de sync existants
- ❌ Toutes les vues existantes

---

## 🚀 Étapes d'Implémentation

### Côté Flutter (Application Caisse)

1. **Créer les nouveaux fichiers** (ne modifie rien):
   ```bash
   touch lib/models/daily_report.dart
   touch lib/services/daily_report_service.dart
   touch lib/widgets/send_report_button.dart
   touch lib/views/cash_reports_screen.dart
   ```

2. **Copier le code** depuis cette documentation

3. **Générer Isar**:
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. **Ajouter la route** dans `main.dart` (nouvelle route, ne modifie pas les existantes):
   ```dart
   GetPage(name: '/cash-reports', page: () => CashReportsScreen()),
   ```

5. **Ajouter un bouton** dans le menu admin (nouveau, sans modifier l'existant)

### Côté Laravel (Backend)

1. **Créer la migration**:
   ```bash
   php artisan make:migration create_cash_register_reports_table
   ```

2. **Créer le modèle**:
   ```bash
   php artisan make:model CashRegisterReport
   ```

3. **Créer le contrôleur**:
   ```bash
   php artisan make:controller DailyReportController
   ```

4. **Copier le code** depuis cette documentation

5. **Ajouter les routes** dans `routes/api.php` (à la fin, sans toucher aux existantes)

6. **Exécuter la migration**:
   ```bash
   php artisan migrate
   ```

7. **Créer la vue admin** (optionnel):
   ```bash
   mkdir -p resources/views/admin/reports
   ```

---

## 📈 Flux de Fonctionnement

```
┌─────────────────────────────────────────────────────────┐
│  CAISSE (Flutter)                                       │
│                                                          │
│  1. Admin clique "Envoyer Rapport"                      │
│  2. DailyReportService.generateTodayReport()            │
│     - Lit les statistiques (SANS modifier)              │
│     - Calcule les totaux                                │
│  3. DailyReportService.sendReport(report)               │
│     - POST /api/cash-reports/daily-report              │
│     - Sauvegarde locale (nouvelle collection)           │
│  4. Affiche résultat (succès/échec)                    │
└────────────────────┬────────────────────────────────────┘
                     │
                     │ POST /api/cash-reports/daily-report
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│  BACKEND (Laravel)                                      │
│                                                          │
│  1. DailyReportController.storeDailyReport()           │
│  2. Valide les données                                  │
│  3. Vérifie si rapport existe déjà                      │
│     - Si oui: UPDATE                                    │
│     - Si non: INSERT                                    │
│  4. Retourne succès                                     │
│                                                          │
│  5. Admin backend peut consulter:                       │
│     - GET /api/cash-reports (liste)                    │
│     - GET /api/cash-reports/{id} (détail)              │
│     - GET /api/cash-reports/dashboard (stats)          │
└─────────────────────────────────────────────────────────┘
```

---

## 🎯 Avantages de Cette Solution

1. ✅ **Zéro risque** - Aucun fichier existant modifié
2. ✅ **Isolation totale** - Nouveau système parallèle
3. ✅ **Réversible** - Supprimer les nouveaux fichiers si besoin
4. ✅ **Évolutif** - Peut ajouter plus de stats plus tard
5. ✅ **Indépendant** - Fonctionne même si sync existant échoue
6. ✅ **Consultable** - Admin backend voit tout l'historique
7. ✅ **Archivable** - Rapports stockés indéfiniment

---

## 📝 Notes Importantes

- Le rapport est **généré à la demande** quand l'admin clique sur le bouton
- Les données sont **lues uniquement** (pas de modification des commandes)
- Le rapport est **sauvegardé localement** avant envoi (traçabilité)
- En cas d'échec d'envoi, le rapport reste en statut `pending`
- Le système de sync existant **continue de fonctionner** normalement
- Les rapports peuvent être envoyés **plusieurs fois par jour** (le dernier écrase le précédent)

---

## 🔧 Personnalisation Possible

Vous pouvez ajouter au rapport:

- 📊 Statistiques par produit le plus vendu
- ⏰ Heures de pointe
- 👥 Nombre de clients uniques
- 🎁 Discounts et promotions
- 📱 Statistiques par canal (web/api/pos)
- 🚚 Statistiques livraison
- ⚡ Temps moyen de préparation

Tout cela **sans toucher au système existant**.
