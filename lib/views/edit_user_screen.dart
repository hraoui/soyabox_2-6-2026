import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/user_controller.dart';
import '../theme/sushi_design.dart';
import '../widgets/app_back_button.dart';
import '../widgets/sushi_cta_button.dart';

class EditUserScreen extends StatefulWidget {
  const EditUserScreen({super.key});

  @override
  State<EditUserScreen> createState() => _EditUserScreenState();
}

class _EditUserScreenState extends State<EditUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _pinController = TextEditingController();
  final _badgeController = TextEditingController();

  String _selectedRole = 'staff';
  bool _isActive = true;
  bool _initialized = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _pinController.dispose();
    _badgeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userController = Get.find<UserController>();
    final user = Get.arguments;

    if (!_initialized && user != null) {
      _nameController.text = user.name ?? '';
      _phoneController.text = user.phone ?? '';
      _emailController.text = user.email ?? '';
      _pinController.text = user.pinCode ?? '';
      _badgeController.text = user.badgeCode ?? '';
      _selectedRole = user.role ?? 'staff';
      _isActive = user.isActive ?? true;
      _initialized = true;
    }

    return Scaffold(
      backgroundColor: SushiColors.bg,
      appBar: AppBar(
        backgroundColor: SushiColors.white,
        foregroundColor: SushiColors.ink,
        elevation: 0,
        title: const Text('Modifier utilisateur', style: SushiTypo.h2),
        leading: const AppBackButton(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: SushiSpace.xl,
          vertical: SushiSpace.lg,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Container(
              decoration: SushiDeco.card(),
              padding: const EdgeInsets.all(SushiSpace.xl),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Profil', style: SushiTypo.h1),
                    const SizedBox(height: SushiSpace.sm),
                    Text(
                      'Mettez à jour les informations et le rôle. Le PIN est requis pour le personnel.',
                      style: SushiTypo.bodyMd,
                    ),
                    const SizedBox(height: SushiSpace.lg),
                    _field(
                      label: 'Nom complet',
                      controller: _nameController,
                      keyboardType: TextInputType.text,
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'Veuillez entrer un nom'
                          : null,
                    ),
                    const SizedBox(height: SushiSpace.md),
                    _field(
                      label: 'Numéro de téléphone',
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'Veuillez entrer un numéro'
                          : null,
                    ),
                    const SizedBox(height: SushiSpace.md),
                    _field(
                      label: 'Email',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Veuillez entrer un email';
                        }
                        if (!GetUtils.isEmail(v)) {
                          return 'Veuillez entrer un email valide';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: SushiSpace.md),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedRole,
                      decoration: _decoration('Rôle'),
                      items: const [
                        DropdownMenuItem(
                          value: 'staff',
                          child: Text('Serveur'),
                        ),
                        DropdownMenuItem(value: 'admin', child: Text('Admin')),
                        DropdownMenuItem(
                          value: 'livreur',
                          child: Text('Livreur'),
                        ),
                        DropdownMenuItem(
                          value: 'client',
                          child: Text('Client'),
                        ),
                        DropdownMenuItem(
                          value: 'superadmin',
                          child: Text('Super admin'),
                        ),
                         DropdownMenuItem(
                          value: 'cashier',
                          child: Text('caissier'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _selectedRole = value);
                      },
                    ),
                    const SizedBox(height: SushiSpace.md),
                    _field(
                      label: 'Code PIN (4-6 chiffres)',
                      controller: _pinController,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (_selectedRole == 'staff' &&
                            (v == null || v.isEmpty)) {
                          return 'Le code PIN est requis pour le personnel';
                        }
                        if (v != null && v.isNotEmpty) {
                          if (v.length < 4 || v.length > 6) {
                            return 'Le PIN doit comporter 4 à 6 chiffres';
                          }
                          // Vérifier que le PIN contient uniquement des chiffres
                          if (!RegExp(r'^[0-9]+$').hasMatch(v)) {
                            return 'Le PIN doit contenir uniquement des chiffres';
                          }
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
                    const SizedBox(height: SushiSpace.md),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Statut actif', style: SushiTypo.h4),
                        Switch(
                          value: _isActive,
                          thumbColor: const WidgetStatePropertyAll(
                            SushiColors.red,
                          ),
                          trackColor: const WidgetStatePropertyAll(
                            SushiColors.redPale,
                          ),
                          onChanged: (v) => setState(() => _isActive = v),
                        ),
                      ],
                    ),
                    const SizedBox(height: SushiSpace.xl),
                    SushiCTAButton(
                      child: const Text('Mettre à jour'),
                      onPressed: () async {
                        if (!_formKey.currentState!.validate()) return;
                        try {
                          final ok = await userController.updateUser(
                            userId: user.id,
                            name: _nameController.text,
                            phone: _phoneController.text,
                            email: _emailController.text,
                            role: _selectedRole,
                            pinCode: _pinController.text.isEmpty
                                ? null
                                : _pinController.text,
                            badgeCode: _badgeController.text,
                            isActive: _isActive,
                          );
                          if (ok) {
                            Get.back(result: true);
                          } else {
                            Get.snackbar(
                              'Erreur',
                              'Échec de la mise à jour.',
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: SushiColors.error,
                              colorText: SushiColors.white,
                            );
                          }
                        } catch (e) {
                          Get.snackbar(
                            'Erreur',
                            e.toString(),
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: SushiColors.error,
                            colorText: SushiColors.white,
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
