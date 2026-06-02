# Résumé complet des fonctionnalités de gestion de caisse

## 1. Introduction

Ce document résume toutes les fonctionnalités de gestion de caisse développées dans le cadre de notre discussion. Il couvre la fermeture de caisse, l'ouverture de caisse, la gestion des rôles et les fonctionnalités associées.

## 2. Architecture de la solution

### 2.1 Modèle d'utilisateur

Fichier : [lib/models/user.dart](file:///Users/macbookpro/Developer/caisse_officielle_desktop/lib/models/user.dart)

Ajout de l'énumération UserRole :
```dart
enum UserRole { 
  admin, 
  superadmin, 
  server, 
  delivery, 
  cashier  // Nouveau rôle
}

// Ajout du champ role dans la classe User
String? role; // Ajouter ce champ pour stocker le rôle
```

### 2.2 Contrôleur d'authentification

Fichier : [lib/controllers/auth_controller.dart](file:///Users/macbookpro/Developer/caisse_officielle_desktop/lib/controllers/auth_controller.dart)

Variables et méthodes pour la gestion des rôles :
```dart
// Variable de rôle
UserRole _currentRole = UserRole.server; // Valeur par défaut
UserRole get currentRole => _currentRole;

// Méthodes de vérification des permissions
bool get canViewOrders => 
  _currentRole == UserRole.admin || 
  _currentRole == UserRole.superadmin || 
  _currentRole == UserRole.cashier;

bool get canViewFinancialStatus => 
  _currentRole == UserRole.admin || 
  _currentRole == UserRole.superadmin || 
  _currentRole == UserRole.cashier;

bool get canCloseCashRegister => 
  _currentRole == UserRole.admin || 
  _currentRole == UserRole.superadmin || 
  _currentRole == UserRole.cashier;

bool get canOpenCashRegister => 
  _currentRole == UserRole.admin || 
  _currentRole == UserRole.superadmin || 
  _currentRole == UserRole.cashier;

bool get canPrintDailyReport => 
  _currentRole == UserRole.admin || 
  _currentRole == UserRole.superadmin || 
  _currentRole == UserRole.cashier;

// Méthode pour définir le rôle de l'utilisateur
void setCurrentUserRole(String role) {
  switch(role) {
    case 'admin':
      _currentRole = UserRole.admin;
      break;
    case 'superadmin':
      _currentRole = UserRole.superadmin;
      break;
    case 'server':
      _currentRole = UserRole.server;
      break;
    case 'delivery':
      _currentRole = UserRole.delivery;
      break;
    case 'cashier':
      _currentRole = UserRole.cashier;
      break;
    default:
      _currentRole = UserRole.server; // Valeur par défaut
  }
}
```

## 3. Modèle d'état de caisse

Fichier : `lib/models/cash_register_state.dart`
```dart
import 'package:isar/isar.dart';

part 'cash_register_state.g.dart';

@collection
class CashRegisterState {
  Id id = Isar.autoIncrement;
  
  @Index(unique: true)
  late String date; // Format YYYY-MM-DD
  
  bool isOpen = true;
  DateTime? openedAt;
  DateTime? closedAt;
  int? openedByStaffId;
  String? openedByStaffName;
  int? closedByStaffId;
  String? closedByStaffName;
  String? closingReport; // JSON string with daily summary data
  bool isLockedByAdmin = false; // Pour indiquer si bloqué par admin
}
```

## 4. Contrôleur de gestion de caisse

Fichier : `lib/controllers/cash_register_controller.dart`
```dart
import 'package:get/get.dart';
import 'package:isar/isar.dart';
import '../models/cash_register_state.dart';
import '../services/database_service.dart';
import '../models/daily_report.dart';
import '../services/daily_report_service.dart';

class CashRegisterController extends GetxController {
  final _isar = DatabaseService.isar;
  
  var _currentState = <CashRegisterState>[].obs;
  CashRegisterState? get currentState => _currentState.isEmpty ? null : _currentState.first;
  
  bool get isCashRegisterOpen => currentState?.isOpen ?? true;
  bool get isCashRegisterLocked => currentState?.isLockedByAdmin ?? false;
  
  @override
  void onReady() {
    super.onReady();
    loadCurrentState();
  }
  
  Future<void> loadCurrentState() async {
    final today = DateTime.now();
    final dateStr = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
    
    final state = await _isar.cashRegisterStates
        .filter()
        .dateEqualTo(dateStr)
        .findFirst();
    
    if (state != null) {
      _currentState.assignAll([state]);
    } else {
      // Créer un nouvel état pour aujourd'hui
      final newState = CashRegisterState()
        ..date = dateStr
        ..isOpen = true
        ..openedAt = DateTime.now();
      
      await _isar.writeTxn(() => _isar.cashRegisterStates.put(newState));
      _currentState.assignAll([newState]);
    }
  }
  
  Future<bool> closeCashRegister({
    required int staffId,
    required String staffName,
  }) async {
    if (!isCashRegisterOpen) return false;
    
    try {
      // Générer le rapport quotidien
      final report = await DailyReportService.generateTodayReport();
      
      await _isar.writeTxn(() async {
        final state = CashRegisterState()
          ..date = currentState!.date
          ..isOpen = false
          ..closedAt = DateTime.now()
          ..closedByStaffId = staffId
          ..closedByStaffName = staffName
          ..openedAt = currentState!.openedAt
          ..openedByStaffId = currentState!.openedByStaffId
          ..openedByStaffName = currentState!.openedByStaffName
          ..closingReport = report.toJson().toString();
        
        await _isar.cashRegisterStates.put(state);
      });
      
      _currentState.assignAll([await _loadCurrentState()]);
      return true;
    } catch (e) {
      print("Erreur lors de la fermeture de caisse: $e");
      return false;
    }
  }
  
  Future<bool> openCashRegister({
    required int staffId,
    required String staffName,
    bool isAdminOverride = false,
  }) async {
    // Vérifier si l'utilisateur est admin ou si c'est un override admin
    if (isCashRegisterLocked && !isAdminOverride) {
      return false; // Ne peut pas ouvrir si verrouillé par admin
    }
    
    try {
      await _isar.writeTxn(() async {
        final state = CashRegisterState()
          ..date = currentState!.date
          ..isOpen = true
          ..isLockedByAdmin = false // Déverrouiller si c'était le cas
          ..openedAt = DateTime.now()
          ..openedByStaffId = staffId
          ..openedByStaffName = staffName;
        
        await _isar.cashRegisterStates.put(state);
      });
      
      _currentState.assignAll([await _loadCurrentState()]);
      return true;
    } catch (e) {
      print("Erreur lors de l'ouverture de caisse: $e");
      return false;
    }
  }
  
  Future<CashRegisterState?> _loadCurrentState() async {
    final today = DateTime.now();
    final dateStr = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
    
    return await _isar.cashRegisterStates
        .filter()
        .dateEqualTo(dateStr)
        .findFirst();
  }
}
```

## 5. Page du tableau de bord caissier

Fichier : `lib/views/cashier_dashboard_screen.dart`
```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/cash_register_controller.dart';
import '../views/admin_orders_screen.dart';
import '../views/admin_accounting_screen.dart';
import '../views/cash_register_status_screen.dart';
import '../widgets/daily_sync_button.dart';
import '../models/daily_report.dart';
import '../services/daily_report_service.dart';

class CashierDashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final cashRegisterController = Get.put(CashRegisterController());
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Tableau de Bord Caissier'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              authController.logout();
              Get.offAllNamed('/login');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Section des commandes
            if (authController.canViewOrders) ...[
              _buildFeatureCard(
                title: 'Voir les commandes',
                subtitle: 'Afficher toutes les commandes du jour',
                icon: Icons.list_alt,
                color: Colors.blue,
                onTap: () => Get.toNamed('/admin-orders'),
              ),
              SizedBox(height: 16),
            ],
            
            // Section état financier
            if (authController.canViewFinancialStatus) ...[
              _buildFeatureCard(
                title: 'État financier',
                subtitle: 'Voir les stats des serveurs et livreurs',
                icon: Icons.monetization_on,
                color: Colors.green,
                onTap: () => Get.toNamed('/admin-accounting'),
              ),
              SizedBox(height: 16),
            ],
            
            // Section gestion de caisse
            _buildFeatureCard(
              title: 'Gestion de caisse',
              subtitle: 'Ouvrir/Fermer la caisse',
              icon: Icons.account_balance_wallet,
              color: Colors.orange,
              onTap: () => Get.to(() => CashRegisterStatusScreen()),
            ),
            SizedBox(height: 16),
            
            // Section impression de rapport
            if (authController.canPrintDailyReport) ...[
              _buildFeatureCard(
                title: 'Imprimer rapport quotidien',
                subtitle: 'Générer et imprimer le rapport de la journée',
                icon: Icons.print,
                color: Colors.purple,
                onTap: () => _showDailyReportOptions(),
              ),
              SizedBox(height: 16),
            ],
            
            // Affichage de l'état actuel de la caisse
            Obx(() => Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      cashRegisterController.isCashRegisterOpen 
                        ? 'Caisse: Ouverte' 
                        : (cashRegisterController.isCashRegisterLocked ? 'Caisse: Bloquée' : 'Caisse: Fermée'),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: cashRegisterController.isCashRegisterOpen 
                          ? Colors.green 
                          : (cashRegisterController.isCashRegisterLocked ? Colors.red : Colors.orange),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Dernière action: ${cashRegisterController.currentState?.closedByStaffName != null ? "Fermée par ${cashRegisterController.currentState?.closedByStaffName}" : "Ouverte par ${cashRegisterController.currentState?.openedByStaffName}"}',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFeatureCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
  
  void _showDailyReportOptions() {
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Options de rapport',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.print, color: Colors.blue),
              title: Text('Imprimer le rapport'),
              onTap: () async {
                Get.back();
                await _generateAndPrintReport();
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _generateAndPrintReport() async {
    try {
      final report = await DailyReportService.generateTodayReport();
      Get.snackbar(
        'Rapport généré',
        'Le rapport quotidien a été généré avec succès',
        snackPosition: SnackPosition.BOTTOM,
      );
      
      Get.dialog(
        AlertDialog(
          title: Text('Rapport quotidien'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Date: ${DateTime.now().toString().split(' ')[0]}'),
                Text('Total Revenu: ${report.totalRevenue.toStringAsFixed(2)} DA'),
                Text('Total Commandes: ${report.totalOrders}'),
                Text('Espèces: ${report.cashTotal.toStringAsFixed(2)} DA'),
                Text('TPE: ${report.tpeTotal.toStringAsFixed(2)} DA'),
                Text('En compte: ${report.enCompteTotal.toStringAsFixed(2)} DA'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text('Fermer'),
            ),
            TextButton(
              onPressed: () {
                Get.back();
                Get.snackbar('Impression', 'Rapport envoyé à l\'imprimante');
              },
              child: Text('Imprimer'),
            ),
          ],
        ),
      );
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de générer le rapport: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
```

## 6. Mise à jour des dépendances

Fichier : [lib/helper/dependencies.dart](file:///Users/macbookpro/Developer/caisse_officielle_desktop/lib/helper/dependencies.dart)
```dart
// Ajouter cette ligne
Get.lazyPut<CashRegisterController>(() => CashRegisterController());
```

## 7. Mise à jour des routes

Ajouter cette route dans le fichier des routes :
```dart
GetPage(name: '/cashier-dashboard', page: () => CashierDashboardScreen()),
```

## 8. Gestion de la redirection

Dans la page de connexion, ajouter la redirection pour le rôle caissier :
```dart
if (response['user']['role'] == 'cashier') {
  Get.offAll(() => CashierDashboardScreen());
}
```

## 9. Page d'état de la caisse

Fichier : `lib/views/cash_register_status_screen.dart`
```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/cash_register_controller.dart';
import '../controllers/auth_controller.dart';

class CashRegisterStatusScreen extends StatelessWidget {
  final CashRegisterController controller = Get.put(CashRegisterController());
  final AuthController authController = Get.find();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('État de la caisse'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Obx(() => Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Icon(
                      controller.isCashRegisterOpen 
                        ? Icons.check_circle 
                        : Icons.highlight_off,
                      size: 80,
                      color: controller.isCashRegisterOpen 
                        ? Colors.green 
                        : Colors.red,
                    ),
                    SizedBox(height: 16),
                    Text(
                      controller.isCashRegisterOpen 
                        ? 'Caisse Ouverte' 
                        : (controller.isCashRegisterLocked ? 'Caisse Bloquée' : 'Caisse Fermée'),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Date: ${DateTime.now().toString().split(' ')[0]}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 32),
            
            // Bouton pour fermer la caisse (disponible si ouverte)
            if (controller.isCashRegisterOpen) ...[
              ElevatedButton.icon(
                onPressed: () => _confirmCloseCashRegister(),
                icon: Icon(Icons.lock_outline),
                label: Text('Fermer la caisse'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
              ),
              SizedBox(height: 16),
            ],
            
            // Bouton pour ouvrir la caisse (disponible si fermée)
            if (!controller.isCashRegisterOpen && !controller.isCashRegisterLocked) ...[
              ElevatedButton.icon(
                onPressed: () => _confirmOpenCashRegister(),
                icon: Icon(Icons.lock_open_outlined),
                label: Text('Ouvrir la caisse'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
              ),
              SizedBox(height: 16),
            ],
            
            // Bouton pour verrouiller la caisse (admin seulement)
            if (authController.currentRole == 'admin' || authController.currentRole == 'superadmin') ...[
              if (!controller.isCashRegisterLocked) ...[
                ElevatedButton.icon(
                  onPressed: () => _lockCashRegisterAsAdmin(),
                  icon: Icon(Icons.lock),
                  label: Text('Verrouiller la caisse'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  ),
                ),
                SizedBox(height: 16),
              ],
              
              // Bouton pour déverrouiller la caisse (admin seulement)
              if (controller.isCashRegisterLocked) ...[
                ElevatedButton.icon(
                  onPressed: () => _unlockCashRegisterAsAdmin(),
                  icon: Icon(Icons.lock_open),
                  label: Text('Déverrouiller la caisse'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  ),
                ),
                SizedBox(height: 16),
              ],
            ],
            
            // Afficher les détails du dernier état
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dernière action:', style: Theme.of(context).textTheme.titleMedium),
                    SizedBox(height: 8),
                    if (controller.currentState != null) ...[
                      Text('Ouvert par: ${controller.currentState?.openedByStaffName ?? "N/A"}'),
                      Text('Heure d\'ouverture: ${controller.currentState?.openedAt?.toString() ?? "N/A"}'),
                      Text('Fermé par: ${controller.currentState?.closedByStaffName ?? "N/A"}'),
                      Text('Heure de fermeture: ${controller.currentState?.closedAt?.toString() ?? "N/A"}'),
                      if (controller.currentState?.isLockedByAdmin == true)
                        Text('Verrouillé par admin: Oui', style: TextStyle(color: Colors.red)),
                    ],
                  ],
                ),
              ),
            ),
          ],
        )),
      ),
    );
  }
  
  void _confirmCloseCashRegister() {
    Get.defaultDialog(
      title: "Confirmer la fermeture",
      middleText: "Êtes-vous sûr de vouloir fermer la caisse ? Cette action générera le rapport de fin de journée.",
      confirm: ElevatedButton(
        onPressed: () async {
          final auth = Get.find<AuthController>();
          final success = await controller.closeCashRegister(
            staffId: auth.currentUser?.id ?? 0,
            staffName: auth.currentUser?.name ?? 'Inconnu',
          );
          
          if (success) {
            Get.snackbar("Succès", "La caisse a été fermée avec succès");
            Get.back(); // Fermer la boîte de dialogue
          } else {
            Get.snackbar("Erreur", "Impossible de fermer la caisse");
          }
        },
        child: Text("Confirmer"),
      ),
      cancel: TextButton(
        onPressed: () => Get.back(),
        child: Text("Annuler"),
      ),
    );
  }
  
  void _confirmOpenCashRegister() {
    Get.defaultDialog(
      title: "Confirmer l'ouverture",
      middleText: "Êtes-vous sûr de vouloir ouvrir la caisse ?",
      confirm: ElevatedButton(
        onPressed: () async {
          final auth = Get.find<AuthController>();
          final success = await controller.openCashRegister(
            staffId: auth.currentUser?.id ?? 0,
            staffName: auth.currentUser?.name ?? 'Inconnu',
          );
          
          if (success) {
            Get.snackbar("Succès", "La caisse a été ouverte avec succès");
            Get.back(); // Fermer la boîte de dialogue
          } else {
            Get.snackbar("Erreur", "Impossible d'ouvrir la caisse");
          }
        },
        child: Text("Confirmer"),
      ),
      cancel: TextButton(
        onPressed: () => Get.back(),
        child: Text("Annuler"),
      ),
    );
  }
}
```

## 10. Permissions du rôle caissier

- Voir les commandes
- Voir l'état financier des serveurs et livreurs
- Fermer la caisse
- Activer la caisse
- Imprimer le rapport final de la journée

## 11. Contraintes de sécurité

- Le caissier ne peut pas accéder aux fonctions d'administration avancées
- Seul un administrateur peut verrouiller/déverrouiller la caisse de manière permanente
- Toutes les actions de gestion de caisse sont enregistrées avec le nom de l'utilisateur et l'horodatage

## 12. Intégration avec les écrans existants

- Lorsque la caisse est fermée, les écrans POS existants doivent afficher un message approprié
- Ajouter un bouton d'accès rapide à l'état de la caisse dans l'écran POS
- S'assurer que les écrans de gestion de commandes respectent l'état de la caisse

## 13. Génération de rapports

- Lors de la fermeture de la caisse, un rapport financier est automatiquement généré
- Le rapport contient les totaux des ventes, la répartition par mode de paiement et les détails des commandes
- Le rapport est sauvegardé localement et peut être envoyé au serveur backend

## 14. Journalisation des actions

- Toutes les actions liées à la gestion de la caisse sont enregistrées dans la base de données
- Les informations enregistrées incluent : utilisateur, date/heure, action effectuée
- Ces journaux peuvent être consultés par l'administrateur pour des besoins d'audit

Ce document sert de référence complète pour la mise en œuvre de la fonctionnalité de gestion de caisse avec le rôle caissier.