import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/user_controller.dart';
import '../controllers/auth_controller.dart';
import '../theme/sushi_design.dart';
import '../widgets/app_back_button.dart';
import '../widgets/creation_success_dialog.dart';
import '../widgets/sushi_cta_button.dart';

class CreateAdminScreen extends StatefulWidget {
  const CreateAdminScreen({super.key});

  @override
  State<CreateAdminScreen> createState() => _CreateAdminScreenState();
}

class _CreateAdminScreenState extends State<CreateAdminScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _pinController = TextEditingController();

  int? _restaurantId;
  final bool _isActive = true;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userController = Get.find<UserController>();

    return Scaffold(
      backgroundColor: SushiColors.bg,
      appBar: AppBar(
        backgroundColor: SushiColors.white,
        foregroundColor: SushiColors.ink,
        elevation: 0,
        title: const Text('Créer un Admin', style: SushiTypo.h2),
        leading: const AppBackButton(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(SushiSpace.lg),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Container(
              decoration: SushiDeco.card(),
              padding: const EdgeInsets.all(SushiSpace.xl),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.admin_panel_settings,
                          color: const Color(0xFF1A9988),
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Text('Nouvel Administrateur', style: SushiTypo.h1),
                      ],
                    ),
                    const SizedBox(height: SushiSpace.sm),
                    Text(
                      'Ajoutez un administrateur pour gérer un restaurant.',
                      style: SushiTypo.bodyMd,
                    ),
                    const SizedBox(height: SushiSpace.lg),
                    _field(
                      label: 'Nom complet',
                      controller: _nameController,
                      keyboardType: TextInputType.text,
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Nom requis' : null,
                    ),
                    const SizedBox(height: SushiSpace.md),
                    _field(
                      label: 'Téléphone',
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Téléphone requis' : null,
                    ),
                    const SizedBox(height: SushiSpace.md),
                    _field(
                      label: 'Email',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Email requis';
                        if (!GetUtils.isEmail(v)) return 'Email invalide';
                        return null;
                      },
                    ),
                    const SizedBox(height: SushiSpace.md),
                    _field(
                      label: 'Mot de passe',
                      controller: _passwordController,
                      obscureText: true,
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Mot de passe requis';
                        }
                        if (v.length < 6) {
                          return 'Min. 6 caractères';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: SushiSpace.md),
                    _field(
                      label: 'Code PIN (requis pour connexion admin)',
                      controller: _pinController,
                      keyboardType: TextInputType.text,
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'PIN requis';
                        }
                        if (v.length < 4) {
                          return 'Min. 4 caractères';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: SushiSpace.md),
                    _field(
                      label: 'ID Restaurant (optionnel)',
                      controller: TextEditingController(
                        text: _restaurantId?.toString() ?? '',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (v) {
                        _restaurantId =
                            v?.isNotEmpty == true ? int.tryParse(v!) : null;
                      },
                    ),
                    const SizedBox(height: SushiSpace.lg),
                    SushiCTAButton(
                      child: const Text('Créer l\'admin'),
                      onPressed: () async {
                        if (!_formKey.currentState!.validate()) return;
                        try {
                          final auth = Get.find<AuthController>();
                          final adminRestaurantId =
                              auth.currentUser?.restaurantId;

                          final newUser = await userController.createUser(
                            name: _nameController.text,
                            phone: _phoneController.text,
                            email: _emailController.text,
                            password: _passwordController.text,
                            role: 'admin',
                            pinCode: _pinController.text,
                            badgeCode: null,
                            isActive: _isActive,
                            restaurantId: _restaurantId ?? adminRestaurantId,
                          );

                          if (newUser != null) {
                            await Future.delayed(
                              const Duration(milliseconds: 300),
                            );

                            Get.dialog(
                              CreationSuccessDialog(
                                name: newUser.name,
                                role: 'Admin',
                                phone: newUser.phone,
                                email: newUser.email,
                                pin: newUser.pinCode ?? _pinController.text,
                                isLivreur: false,
                              ),
                            );

                            Get.offAllNamed('/admin-management');
                          }
                        } catch (e) {
                          final errorMessage = e.toString().toLowerCase();
                          String displayMessage = 'Erreur : ${e.toString()}';

                          if (errorMessage.contains('email')) {
                            displayMessage = 'Cet email est déjà utilisé.';
                          } else if (errorMessage.contains('phone')) {
                            displayMessage =
                                'Ce numéro de téléphone est déjà utilisé.';
                          } else if (errorMessage.contains('pin')) {
                            displayMessage = 'Ce code PIN est déjà utilisé.';
                          }

                          Get.snackbar(
                            '❌ Erreur',
                            displayMessage,
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.red,
                            colorText: Colors.white,
                            duration: const Duration(seconds: 5),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _decoration(String label) =>
      InputDecoration(labelText: label);

  Widget _field({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    bool obscureText = false,
    String? Function(String?)? validator,
    void Function(String?)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: _decoration(label),
      validator: validator,
      onChanged: onChanged,
    );
  }
}
