import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/delivery_controller.dart';
import '../models/delivery.dart';
import '../theme/sushi_design.dart';
import '../widgets/app_back_button.dart';
import '../widgets/sushi_cta_button.dart';

class EditDeliveryScreen extends StatefulWidget {
  const EditDeliveryScreen({super.key});

  @override
  State<EditDeliveryScreen> createState() => _EditDeliveryScreenState();
}

class _EditDeliveryScreenState extends State<EditDeliveryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isActive = true;
  bool _initialized = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deliveryController = Get.find<DeliveryController>();
    final delivery = Get.arguments as Delivery;

    if (!_initialized) {
      _nameController.text = delivery.name;
      _phoneController.text = delivery.phone;
      _emailController.text = delivery.email;
      _isActive = delivery.isActive;
      _initialized = true;
    }

    return Scaffold(
      backgroundColor: SushiColors.bg,
      appBar: AppBar(
        backgroundColor: SushiColors.white,
        foregroundColor: SushiColors.ink,
        elevation: 0,
        title: const Text('Modifier livreur', style: SushiTypo.h2),
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
                      'Mettez à jour les informations du livreur.',
                      style: SushiTypo.bodyMd,
                    ),
                    const SizedBox(height: SushiSpace.lg),
                    _field(
                      label: 'Nom complet',
                      controller: _nameController,
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
                    _field(
                      label: 'Nouveau mot de passe (optionnel)',
                      controller: _passwordController,
                      obscureText: true,
                      validator: (v) {
                        if (v != null && v.isNotEmpty && v.length < 6) {
                          return 'Min. 6 caractères';
                        }
                        return null;
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
                          final ok = await deliveryController.updateDelivery(
                            deliveryId: delivery.id,
                            name: _nameController.text,
                            phone: _phoneController.text,
                            email: _emailController.text,
                            isActive: _isActive,
                            password: _passwordController.text.isEmpty
                                ? null
                                : _passwordController.text,
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
