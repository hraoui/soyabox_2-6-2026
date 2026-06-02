import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/user_controller.dart';
import '../theme/sushi_design.dart';
import '../widgets/app_back_button.dart';
import '../widgets/sushi_cta_button.dart';

class EditAdminScreen extends StatefulWidget {
  const EditAdminScreen({super.key});

  @override
  State<EditAdminScreen> createState() => _EditAdminScreenState();
}

class _EditAdminScreenState extends State<EditAdminScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _pinController = TextEditingController();

  int? _restaurantId;
  bool _isActive = true;
  bool _initialized = false;
  bool _changePassword = false;

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
    final admin = Get.arguments;

    if (!_initialized && admin != null) {
      _nameController.text = admin.name ?? '';
      _phoneController.text = admin.phone ?? '';
      _emailController.text = admin.email ?? '';
      _pinController.text = admin.pinCode ?? '';
      _restaurantId = admin.restaurantId;
      _isActive = admin.isActive ?? true;
      _initialized = true;
    }

    return Scaffold(
      backgroundColor: SushiColors.bg,
      appBar: AppBar(
        backgroundColor: SushiColors.white,
        foregroundColor: SushiColors.ink,
        elevation: 0,
        title: const Text('Modifier Admin', style: SushiTypo.h2),
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
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.admin_panel_settings,
                          color: const Color(0xFF1A9988),
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Text('Modifier Admin', style: SushiTypo.h1),
                      ],
                    ),
                    const SizedBox(height: SushiSpace.sm),
                    Text(
                      admin.name ?? 'Administrateur',
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
                    Row(
                      children: [
                        Checkbox(
                          value: _changePassword,
                          onChanged: (v) =>
                              setState(() => _changePassword = v ?? false),
                        ),
                        const Text('Changer le mot de passe'),
                      ],
                    ),
                    if (_changePassword) ...[
                      _field(
                        label: 'Nouveau mot de passe',
                        controller: _passwordController,
                        obscureText: true,
                        validator: (v) {
                          if (_changePassword && (v == null || v.isEmpty)) {
                            return 'Mot de passe requis';
                          }
                          if (v != null && v.isNotEmpty && v.length < 6) {
                            return 'Min. 6 caractères';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: SushiSpace.md),
                    ],
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
                      label: 'ID Restaurant',
                      controller: TextEditingController(
                        text: _restaurantId?.toString() ?? '',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (v) {
                        _restaurantId = v?.isNotEmpty == true
                            ? int.tryParse(v!)
                            : null;
                      },
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
                            userId: admin.id,
                            name: _nameController.text,
                            phone: _phoneController.text,
                            email: _emailController.text,
                            role: 'admin',
                            pinCode: _pinController.text.isEmpty
                                ? null
                                : _pinController.text,
                            badgeCode: null,
                            isActive: _isActive,
                            restaurantId: _restaurantId,
                          );
                          if (ok) {
                            Get.back(result: true);
                            Get.snackbar(
                              'Succès',
                              'Admin mis à jour',
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: Colors.green,
                              colorText: Colors.white,
                            );
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
