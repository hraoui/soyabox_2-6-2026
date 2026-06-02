import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/user_controller.dart';
import '../controllers/auth_controller.dart';
import '../controllers/restaurant_controller.dart';
import '../theme/sushi_design.dart';
import '../widgets/app_back_button.dart';
import '../widgets/creation_success_dialog.dart';
import '../widgets/sushi_cta_button.dart';

class CreateUserScreen extends StatefulWidget {
  const CreateUserScreen({super.key});

  @override
  State<CreateUserScreen> createState() => _CreateUserScreenState();
}

class _CreateUserScreenState extends State<CreateUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _pinController = TextEditingController();
  final _badgeController = TextEditingController();

  String _role = 'staff';
  final bool _isActive = true;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _pinController.dispose();
    _badgeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userController = Get.find<UserController>();
    Get.find<RestaurantController>(); // ensure loaded

    return Scaffold(
      backgroundColor: SushiColors.bg,
      appBar: AppBar(
        backgroundColor: SushiColors.white,
        foregroundColor: SushiColors.ink,
        elevation: 0,
        title: const Text('Créer un utilisateur', style: SushiTypo.h2),
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
                    Text('Nouvel utilisateur', style: SushiTypo.h1),
                    const SizedBox(height: SushiSpace.sm),
                    Text(
                      'Ajoutez un serveur ou un livreur.',
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
                    DropdownButtonFormField<String>(
                      value: _role,
                      decoration: _decoration('Rôle'),
                      items: const [
                        DropdownMenuItem(
                          value: 'staff',
                          child: Text('Serveur'),
                        ),
                        DropdownMenuItem(
                          value: 'livreur',
                          child: Text('Livreur'),
                        ),
                        DropdownMenuItem(
                          value: 'cashier',
                          child: Text('Caissier'),
                        ),
                      ],
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => _role = v);
                      },
                    ),
                    const SizedBox(height: SushiSpace.md),
                    _field(
                      label: 'Code PIN (4-6 chiffres)',
                      controller: _pinController,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'PIN requis';
                        }
                        if (v.length < 4 || v.length > 6) {
                          return '4 à 6 chiffres';
                        }
                        if (!RegExp(r'^[0-9]+$').hasMatch(v)) {
                          return 'Chiffres uniquement';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: SushiSpace.md),
                    _field(
                      label: 'Code badge / carte (optionnel)',
                      controller: _badgeController,
                      keyboardType: TextInputType.text,
                    ),
                    const SizedBox(height: SushiSpace.lg),
                    SushiCTAButton(
                      child: const Text('Créer'),
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
                            role: _role,
                            pinCode: _pinController.text,
                            badgeCode: _badgeController.text,
                            isActive: _isActive,
                            restaurantId: adminRestaurantId,
                          );

                          if (newUser != null) {
                            await Future.delayed(
                              const Duration(milliseconds: 300),
                            );

                            Get.dialog(
                              CreationSuccessDialog(
                                name: newUser.name,
                                role: _role == 'staff' ? 'Serveur' : 'Livreur',
                                phone: newUser.phone,
                                email: newUser.email,
                                pin: newUser.pinCode ?? _pinController.text,
                                isLivreur: _role == 'livreur',
                              ),
                            );

                            Get.offAllNamed('/users');
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
                          } else if (errorMessage.contains('badge')) {
                            displayMessage = 'Ce code badge est déjà utilisé.';
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
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: _decoration(label),
      validator: validator,
    );
  }
}
