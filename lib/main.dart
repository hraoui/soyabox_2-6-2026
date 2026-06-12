// ignore_for_file: avoid_print

import 'package:caisse_1/controllers/category_controller.dart';
import 'package:caisse_1/controllers/delivery_controller.dart';
import 'package:caisse_1/controllers/pos_controller.dart';
import 'package:caisse_1/controllers/product_controller.dart';
import 'package:caisse_1/controllers/restaurant_controller.dart';
import 'package:caisse_1/controllers/settings_controller.dart';
import 'package:caisse_1/controllers/sync_controller.dart';
import 'package:caisse_1/views/admin_orders_screen.dart';
import 'package:caisse_1/views/table_management_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'helper/dependencies.dart' as dep;
import 'controllers/auth_controller.dart';
import 'seeders/database_seeder.dart';
import 'services/database_service.dart';
import 'services/image_cache_service.dart';
import 'services/fullscreen_service.dart';
import 'bindings/catalog_binding.dart';
import 'theme/app_colors.dart';
import 'views/login_screen.dart';
import 'views/registration_screen.dart';
import 'views/admin_management_screen.dart';
import 'views/create_admin_screen.dart';
import 'views/edit_admin_screen.dart';
import 'views/user_management_screen.dart';
import 'views/create_user_screen.dart';
import 'views/edit_user_screen.dart';
import 'views/user_detail_screen.dart';
import 'views/import_data_screen.dart';
import 'views/product_catalog_screen.dart';
import 'views/pos_screen.dart';
import 'views/pos_lock_screen.dart';
import 'views/pos_choice_screen.dart';
import 'views/pos_tables_screen.dart';
import 'views/pos_table_detail_screen.dart';
import 'views/pos_staff_menu_screen.dart';
import 'views/pos_staff_orders_screen.dart';
import 'views/pos_staff_paid_orders_screen.dart';
import 'views/pos_staff_payments_screen.dart';
import 'views/local_orders_screen.dart';
import 'views/admin_dashboard_screen.dart';
import 'views/global_orders_screen.dart'; // ✅ Nouvelle page Commandes Globales
import 'views/admin_pin_login_screen.dart';
import 'views/cashier_pin_login_screen.dart';
import 'views/financial_admin_dashboard.dart';
import 'views/staff_dashboard_screen.dart';
import 'views/restaurant_management_screen.dart';
import 'views/admin_accounting_screen.dart';
import 'views/admin_delivery_accounting_screen.dart';
import 'views/settings_screen.dart';
import 'views/splash_screen.dart';
import 'views/delivery_management_screen.dart';
import 'views/create_delivery_screen.dart';
import 'views/edit_delivery_screen.dart';
import 'views/delivery_detail_screen.dart';
import 'views/cashier_dashboard_screen.dart'; // Ajout du tableau de bord caissier
import 'views/cashier_orders_screen.dart';
import 'views/cashier_accounting_screen.dart';
import 'views/cashier_simple_orders_screen.dart';
import 'views/cashier_financial_dashboard.dart';
import 'views/cash_register_status_screen.dart';
import 'views/cash_register_closing_report_screen.dart';
import 'views/daily_reports_screen.dart';
import 'controllers/cash_register_controller.dart';
import 'widgets/app_back_button.dart';
import 'widgets/app_card_kit.dart';
import 'widgets/pos_ui.dart';
import 'widgets/touch_keyboard_host.dart';
import 'theme/pos_scoped_theme.dart';
import 'controllers/import_controller.dart';
import 'package:isar/isar.dart';
import 'models/user.dart';

/// Migration: Update PIN codes for existing admin users + clean fake accounts
Future<void> _migrateAdminPins(Isar isar) async {
  try {
    final allUsers = await isar.users.where().findAll();
    int updated = 0;
    int deleted = 0;

    for (final user in allUsers) {
      // 🗑️ Delete fake/test admin accounts with .local email or unhashed passwords
      if (user.email.endsWith('.local') ||
          (user.role == 'superadmin' &&
              user.email == 'superadmin1@soyabox.local')) {
        await isar.writeTxn(() async {
          await isar.users.delete(user.id);
        });
        deleted++;
        print('🗑️ [PIN MIGRATION] Deleted fake account: ${user.email}');
        continue;
      }

      bool needsUpdate = false;

    
      if (user.role == 'superadmin' &&
          user.email == 'superadmin@soyabox.com' &&
          user.pinCode != 'superadmin123') {
        user.pinCode = 'superadmin123';
        needsUpdate = true;
      }

    
      if (user.role == 'admin' &&
          user.email == 'admin.casablanca@soyabox.com' &&
          user.pinCode != 'casa123') {
        user.pinCode = 'casa123';
        needsUpdate = true;
      }

      // Admin Mohammedia - PIN: moha2026
      if (user.role == 'admin' &&
          user.email == 'admin.mohammedia@soyabox.com' &&
          user.pinCode != 'moha123') {
        user.pinCode = 'moha123';
        needsUpdate = true;
      }

      if (needsUpdate) {
        await isar.writeTxn(() async {
          await isar.users.put(user);
        });
        updated++;
      }
    }
    if (updated > 0 || deleted > 0) {
      print(
        '🔧 [PIN MIGRATION] Updated $updated user(s), deleted $deleted fake account(s)',
      );
    }
  } catch (e) {
    print('⚠️ [PIN MIGRATION] Error: $e');
  }
}

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  // Filtre temporaire: supprime le bruit d'assertions répétées liées
  // à HardwareKeyboard (KeyDownEvent déjà pressé) en mode debug.
  // Ceci n'affecte pas le comportement en release, et permet
  // de continuer le développement sans spam dans la console.
  FlutterError.onError = (FlutterErrorDetails details) {
    final msg = details.exceptionAsString();
    if (msg.contains(
        'A KeyDownEvent is dispatched, but the state shows that the physical key is already pressed')) {
      // Ignorer ce message récurrent (bug macOS/Flutter en debug)
      return;
    }
    FlutterError.presentError(details);
  };
  print('🚀 [MAIN] Starting app initialization...');

  const posOrientation = String.fromEnvironment(
    'POS_ORIENTATION',
    defaultValue: 'landscape',
  );
  final normalizedOrientation = posOrientation.trim().toLowerCase();
  await SystemChrome.setPreferredOrientations(
    normalizedOrientation == 'portrait'
        ? const [DeviceOrientation.portraitUp]
        : const [
            DeviceOrientation.landscapeLeft,
            DeviceOrientation.landscapeRight,
          ],
  );
  print('✅ [MAIN] Orientation set to $normalizedOrientation');

  // Initialize database service first
  print('📦 [MAIN] Initializing DatabaseService...');
  await DatabaseService.init();
  print('✅ [MAIN] DatabaseService initialized');

  print('🖼️ [MAIN] Initializing ImageCacheService...');
  await ImageCacheService.instance.init();
  print('✅ [MAIN] ImageCacheService initialized');

  final isSubWindow = args.isNotEmpty && args.first == 'multi_window';

  // Always run seeders on main window startup (debug/release/install).
  // Seeder is idempotent (firstOrCreate), so this is safe across restarts.
  if (!isSubWindow) {
    print('🌱 [MAIN] Running startup seeders...');
    await DatabaseSeeder.seed(DatabaseService.db);
    print('✅ [MAIN] Startup seeders completed');

    // ✅ Migrate PIN codes for existing admin users (regardless of seeder flag)
    print('🔧 [MAIN] Running PIN migration for existing admins...');
    await _migrateAdminPins(DatabaseService.db);
    print('✅ [MAIN] PIN migration completed');
  }

  print('🔧 [MAIN] Initializing dependency injection...');
  await dep.DependencyInjection.init();
  print('✅ [MAIN] Dependency injection completed');

  // Initialize fullscreen service (desktop only)
  print('🖥️ [MAIN] Initializing FullscreenService...');
  await FullscreenService.init();
  print('✅ [MAIN] FullscreenService initialized');

  String initialRoute = isSubWindow ? '/pos' : '/';

  print('🎬 [MAIN] Running app with initial route: $initialRoute');
  print('🎬 [MAIN] isSubWindow: $isSubWindow');

  final app = MyApp(initialRoute: initialRoute, isSubWindow: isSubWindow);
  print('🎬 [MAIN] MyApp instance created, running app...');
  runApp(app);
  print('✅ [MAIN] runApp() completed');
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, this.initialRoute = '/', this.isSubWindow = false});

  final String initialRoute;
  final bool isSubWindow;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    print(
      '📱 [MYAPP] initState called, initialRoute=${widget.initialRoute}, isSubWindow=${widget.isSubWindow}',
    );

    // Initialize controllers
    Get.put(AuthController());
    Get.put(SettingsController());
    Get.put(RestaurantController());
    Get.put(CategoryController());
    Get.put(ProductController());
    Get.put(PosController());
    Get.put(DeliveryController());
    Get.put(ImportController());
    Get.put(SyncController());

    // Initialize cash register controller once.
    _initializeCashRegister();

    print('✅ [INIT] All controllers initialized');
  }

  void _initializeCashRegister() {
    final cashRegisterController = CashRegisterController();
    // Put it in GetX so all screens reuse the same manual session state.
    Get.put(cashRegisterController);
  }

  @override
  void dispose() {
    // Close database when app is disposed
    DatabaseService.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('📱 [MYAPP] build() called');
    final appTheme = glassTheme();
    final posTheme = buildPosTheme(appTheme);
    print('📱 [MYAPP] Themes created, returning GetMaterialApp');

    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Système POS',
      scaffoldMessengerKey: globalScaffoldMessengerKey,

      // ✅ Configuration des localizations Material
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr', 'FR'), // Français
        Locale('en', 'US'), // Anglais (fallback)
      ],
      locale: const Locale('fr', 'FR'), // Locale par défaut

      builder: (context, child) {
        Widget content = child ?? const SizedBox.shrink();
        if (content is Scaffold && (content.appBar == null)) {
          content = SafeArea(top: true, bottom: false, child: content);
        } else if (content is! Scaffold) {
          content = SafeArea(top: true, bottom: false, child: content);
        }

        return TouchKeyboardHost(
          child: AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: Colors.transparent,
            ),
            child: content,
          ),
        );
      },
      home: widget.isSubWindow
          ? Theme(data: posTheme, child: const PosLockScreen())
          : null,
      theme: appTheme,
      initialRoute: widget.isSubWindow ? '/pos-lock' : '/splash',
      getPages: [
        GetPage(name: '/', page: () => LoginScreen()),
        GetPage(name: '/splash', page: () => const SplashScreen()),
        GetPage(name: '/login', page: () => LoginScreen()),
        GetPage(name: '/register', page: () => RegistrationScreen()),
        GetPage(name: '/home', page: () => const HomeScreen()),
        GetPage(
          name: '/admin-dashboard',
          page: () => const AdminDashboardScreen(),
        ),
        GetPage(
          name: '/admin-pin-login',
          page: () => const AdminPinLoginScreen(),
        ),
        GetPage(
          name: '/financial-dashboard',
          page: () => const FinancialAdminDashboard(),
        ),
        GetPage(
          name: '/cashier-financial-dashboard',
          page: () => const CashierFinancialDashboard(),
        ),
        GetPage(
          name: '/staff-dashboard',
          page: () => const StaffDashboardScreen(),
        ),
        GetPage(
          name: '/cashier-pin-login',
          page: () => const CashierPinLoginScreen(),
        ),
        GetPage(
          name: '/cashier-dashboard',
          page: () => CashierDashboardScreen(),
        ),
        GetPage(
          name: '/cash-register-status',
          page: () => CashRegisterStatusScreen(),
        ),
        GetPage(name: '/table-management', page: () => TableManagementScreen()),
        GetPage(
          name: '/pos',
          page: () => Theme(data: posTheme, child: const PosLockScreen()),
        ),
        GetPage(
          name: '/pos-lock',
          page: () => Theme(data: posTheme, child: const PosLockScreen()),
        ),
        GetPage(
          name: '/pos-menu',
          page: () => Theme(data: posTheme, child: const PosStaffMenuScreen()),
        ),
        GetPage(
          name: '/pos-choice',
          page: () => Theme(data: posTheme, child: const PosChoiceScreen()),
        ),
        GetPage(
          name: '/pos-tables',
          page: () => Theme(data: posTheme, child: const PosTablesScreen()),
        ),
        GetPage(
          name: '/pos-table-detail',
          page: () =>
              Theme(data: posTheme, child: const PosTableDetailScreen()),
        ),
        GetPage(
          name: '/pos-order',
          page: () => Theme(
            data: posTheme,
            child: const PosScreen(title: 'Tableau de bord POS'),
          ),
        ),
        GetPage(
          name: '/pos-orders',
          page: () =>
              Theme(data: posTheme, child: const PosStaffOrdersScreen()),
        ),
        GetPage(
          name: '/pos-paid-orders',
          page: () =>
              Theme(data: posTheme, child: const PosStaffPaidOrdersScreen()),
        ),
        GetPage(
          name: '/pos-payments',
          page: () =>
              Theme(data: posTheme, child: const PosStaffPaymentsScreen()),
        ),
        GetPage(name: '/users', page: () => const UserManagementScreen()),
        GetPage(
          name: '/admin-management',
          page: () => const AdminManagementScreen(),
        ),
        GetPage(name: '/create-admin', page: () => const CreateAdminScreen()),
        GetPage(name: '/edit-admin', page: () => const EditAdminScreen()),
        GetPage(
          name: '/restaurants',
          page: () => const RestaurantManagementScreen(),
        ),
        GetPage(
          name: '/admin-accounting',
          page: () => const AdminAccountingScreen(),
        ),
        GetPage(
          name: '/admin-delivery-accounting',
          page: () => const AdminDeliveryAccountingScreen(),
        ),
        GetPage(name: '/admin-orders', page: () => const AdminOrdersScreen()),
        GetPage(name: '/local-orders', page: () => const LocalOrdersScreen()),
        // ✅ Route Commandes Globales - Statistiques détaillées avec filtres
        GetPage(name: '/global-orders', page: () => const GlobalOrdersScreen()),
        // ✅ Route Tables désactivée - Gestion disponible uniquement dans POS
        // GetPage(name: '/tables', page: () => const TableManagementScreen()),
        GetPage(
          name: '/deliveries',
          page: () => const DeliveryManagementScreen(),
        ),
        GetPage(
          name: '/delivery-detail',
          page: () => const DeliveryDetailScreen(),
        ),
        GetPage(name: '/create-user', page: () => CreateUserScreen()),
        GetPage(name: '/edit-user', page: () => EditUserScreen()),
        GetPage(name: '/user-detail', page: () => const UserDetailScreen()),
        GetPage(
          name: '/create-delivery',
          page: () => const CreateDeliveryScreen(),
        ),
        GetPage(name: '/edit-delivery', page: () => const EditDeliveryScreen()),
        GetPage(
          name: '/import-data',
          page: () => const ImportDataScreen(),
          binding: BindingsBuilder(() {
            if (!Get.isRegistered<ImportController>()) {
              Get.lazyPut<ImportController>(() => ImportController());
            }
          }),
        ),
        GetPage(name: '/settings', page: () => const SettingsScreen()),
        GetPage(
          name: '/catalog',
          page: () => const ProductCatalogScreen(),
          binding: CatalogBinding(),
        ),
        GetPage(name: '/daily-reports', page: () => const DailyReportsScreen()),
        GetPage(name: '/cashier-orders', page: () => CashierOrdersScreen()),
        GetPage(
          name: '/cashier-accounting',
          page: () => CashierAccountingScreen(),
        ),
        GetPage(
          name: '/cashier-simple-orders',
          page: () => CashierSimpleOrdersScreen(),
        ),
        GetPage(
          name: '/cashier-dashboard',
          page: () => CashierDashboardScreen(),
        ),
        GetPage(
          name: '/cash-register-closing-report',
          page: () => const CashRegisterClosingReportScreen(),
        ),
      ],
    );
  }
}

// Home screen after login
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cloudDancer,
      appBar: AppBar(
        title: const Text('Tableau de Bord POS'),
        backgroundColor: AppColors.blancPur,
        foregroundColor: AppColors.charbon,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.terraCotta),
        leading: const AppBackButton(),
      ),
      drawer: _buildDrawer(context),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.blancPur,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(Icons.store, size: 80, color: AppColors.terraCotta),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Bienvenue au Système POS',
                style: AppTypography.headline1,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Sélectionnez une option dans le menu',
                style: AppTypography.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              Wrap(
                spacing: AppSpacing.lg,
                runSpacing: AppSpacing.lg,
                alignment: WrapAlignment.center,
                children: [
                  _buildActionCard(
                    icon: Icons.point_of_sale,
                    title: 'Ouvrir le POS',
                    description:
                        "Accédez à l'interface de caisse sécurisée pour encaisser immédiatement.",
                    buttonLabel: 'Accéder au POS',
                    badgeColor: AppColors.terraCotta,
                    onPressed: () => Get.toNamed('/pos'),
                  ),
                  _buildActionCard(
                    icon: Icons.login,
                    title: 'Connexion',
                    description:
                        "Revenir à l'écran de connexion pour changer d'utilisateur.",
                    buttonLabel: 'Aller au login',
                    badgeColor: AppColors.bleuGris,
                    onPressed: () => Get.toNamed('/login'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String description,
    required String buttonLabel,
    required VoidCallback onPressed,
    Color badgeColor = AppColors.terraCotta,
  }) {
    return SizedBox(
      width: 360,
      child: AppSurfaceCard(
        minHeight: 250,
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppCardIconBadge(
              icon: icon,
              accent: badgeColor,
              background: badgeColor.withValues(alpha: 0.12),
              size: 58,
              iconSize: 30,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(title, style: AppTypography.headline2.copyWith(fontSize: 22)),
            const SizedBox(height: AppSpacing.sm),
            Text(description, style: AppTypography.bodyLarge),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onPressed,
                child: Text(buttonLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.blancPur,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildDrawerHeader(),
          _buildDrawerItem(
            icon: Icons.login,
            title: 'Connexion',
            onTap: () {
              Navigator.pop(context);
              Get.toNamed('/login');
            },
          ),
          _buildDrawerItem(
            icon: Icons.person_add,
            title: 'S\'inscrire',
            onTap: () {
              Navigator.pop(context);
              Get.toNamed('/register');
            },
          ),
          _buildDrawerDivider(),
          _buildDrawerItem(
            icon: Icons.shopping_cart,
            title: 'Interface POS',
            onTap: () {
              Navigator.pop(context);
              Get.toNamed('/pos');
            },
          ),
          _buildDrawerItem(
            icon: Icons.people,
            title: 'Gestion des Utilisateurs',
            onTap: () {
              Navigator.pop(context);
              Get.to(() => const UserManagementScreen());
            },
          ),
          _buildDrawerItem(
            icon: Icons.inventory,
            title: 'Catalogue de Produits',
            onTap: () {
              Navigator.pop(context);
              Get.toNamed('/catalog');
            },
          ),
          _buildDrawerItem(
            icon: Icons.sync,
            title: 'Importer les Données',
            onTap: () {
              Navigator.pop(context);
              Get.to(() => const ImportDataScreen());
            },
          ),
          _buildDrawerDivider(),
          _buildDrawerItem(
            icon: Icons.logout,
            title: 'Déconnexion',
            onTap: () async {
              Navigator.pop(context);
              await Get.find<AuthController>().logout();
              Get.offAllNamed('/login');
            },
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        color: AppColors.cloudDancer,
        border: Border(
          bottom: BorderSide(color: AppColors.grisLeger, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.terraCotta.withValues(alpha: 0.1),
            ),
            child: const Icon(
              Icons.store,
              size: 40,
              color: AppColors.terraCotta,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Text('Système POS', style: AppTypography.headline2),
          const SizedBox(height: AppSpacing.xs),
          Text('Gestion des restaurants', style: AppTypography.bodySmall),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.transparent,
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isDestructive ? AppColors.taupeDore : AppColors.terraCotta,
          size: 22,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDestructive ? AppColors.taupeDore : AppColors.charbon,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        hoverColor: AppColors.cloudDancer.withValues(alpha: 0.5),
      ),
    );
  }

  Widget _buildDrawerDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Divider(color: AppColors.grisLeger, height: 1),
    );
  }
}

/// 🎨 Fonction de thème Glass (compatibilité)
ThemeData glassTheme() {
  return ThemeData(
    useMaterial3: true,
    primaryColor: AppColors.terraCotta,
    scaffoldBackgroundColor: AppColors.cloudDancer,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.terraCotta,
      brightness: Brightness.light,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.blancPur,
      foregroundColor: AppColors.charbon,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: AppColors.blancPur,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.terraCotta,
        foregroundColor: AppColors.blancPur,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.blancPur,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: AppColors.grisLeger),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: AppColors.grisLeger),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: AppColors.terraCotta, width: 2),
      ),
    ),
  );
}
