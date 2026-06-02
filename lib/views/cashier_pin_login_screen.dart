import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';

class CashierPinLoginScreen extends StatefulWidget {
  const CashierPinLoginScreen({super.key});

  @override
  State<CashierPinLoginScreen> createState() => _CashierPinLoginScreenState();
}

class _CashierPinLoginScreenState extends State<CashierPinLoginScreen> {
  final TextEditingController _pinController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _handlePinLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final pin = _pinController.text.trim();
      final auth = Get.find<AuthController>();
      final success = await auth.loginCashierWithPin(pin);
      final role = auth.currentRole?.trim().toLowerCase();

      if (success && auth.currentUser != null && role == 'cashier') {
        if (mounted) {
          Get.offAllNamed('/cashier-dashboard');
        }
      } else {
        throw Exception(
          "Échec de l'authentification: rôle caissier non trouvé",
        );
      }
    } catch (e) {
      if (mounted) {
        Get.snackbar(
          'Erreur de connexion',
          e.toString(),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF4CAF50),
          colorText: Colors.white,
          borderRadius: 8,
          margin: const EdgeInsets.all(16),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo et titre
                      _buildHeader(),
                      const SizedBox(height: 32),

                      // Card principale
                      _buildPinCard(),
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
        // Logo circulaire avec effet glassmorphism
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF4CAF50).withOpacity(0.8),
                const Color(0xFF2E7D32).withOpacity(0.9),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4CAF50).withOpacity(0.5),
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
          'CAISSIER PIN',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 3,
            shadows: [Shadow(color: Color(0xFF4CAF50), blurRadius: 10)],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Accès au tableau de bord caissier',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.7),
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildPinCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Clavier et champ PIN en layout responsive
            LayoutBuilder(
              builder: (context, constraints) {
                final isWideScreen = constraints.maxWidth > 300;
                
                if (isWideScreen) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Champ PIN à gauche
                      Expanded(
                        flex: 1,
                        child: _buildPinInputField(),
                      ),
                      const SizedBox(width: 12),
                      // Clavier numérique à droite
                      Expanded(
                        flex: 1,
                        child: _buildNumericKeyboardCashier(),
                      ),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      _buildPinInputField(),
                      const SizedBox(height: 12),
                      _buildNumericKeyboardCashier(),
                    ],
                  );
                }
              },
            ),
            const SizedBox(height: 20),

            // Login Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _handlePinLogin,
                icon: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.login, size: 20),
                label: _isLoading
                    ? const Text('Connexion...')
                    : const Text(
                        'Se connecter',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  elevation: 8,
                  shadowColor: const Color(0xFF4CAF50).withOpacity(0.6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Back to normal login
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Get.offAllNamed('/login'),
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text(
                  'Retour Login',
                  style: TextStyle(fontSize: 14),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withOpacity(0.3)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Widget pour le champ d'entrée du PIN (Caissier)
  Widget _buildPinInputField() {
    return ValueListenableBuilder(
      valueListenable: _pinController,
      builder: (context, value, _) {
        return Column(
          children: [
            // Affichage des points du PIN
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.15)),
              ),
              child: Text(
                _pinController.text.isEmpty
                    ? 'Entrez PIN'
                    : '• ' * _pinController.text.length,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _pinController.text.isEmpty
                      ? Colors.white.withOpacity(0.5)
                      : Colors.white,
                  letterSpacing: 3,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            // Compteur de caractères
            if (_pinController.text.isNotEmpty)
              Text(
                '${_pinController.text.length} chiffres',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
          ],
        );
      },
    );
  }

  /// Widget pour le clavier numérique (Caissier - Vert)
  Widget _buildNumericKeyboardCashier() {
    return ValueListenableBuilder(
      valueListenable: _pinController,
      builder: (context, value, _) {
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4CAF50).withOpacity(0.2),
                blurRadius: 8,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            children: [
              // Rangée 1: 1 2 3
              Row(
                children: [
                  _buildNumericKeyCashier('1'),
                  const SizedBox(width: 6),
                  _buildNumericKeyCashier('2'),
                  const SizedBox(width: 6),
                  _buildNumericKeyCashier('3'),
                ],
              ),
              const SizedBox(height: 6),
              // Rangée 2: 4 5 6
              Row(
                children: [
                  _buildNumericKeyCashier('4'),
                  const SizedBox(width: 6),
                  _buildNumericKeyCashier('5'),
                  const SizedBox(width: 6),
                  _buildNumericKeyCashier('6'),
                ],
              ),
              const SizedBox(height: 6),
              // Rangée 3: 7 8 9
              Row(
                children: [
                  _buildNumericKeyCashier('7'),
                  const SizedBox(width: 6),
                  _buildNumericKeyCashier('8'),
                  const SizedBox(width: 6),
                  _buildNumericKeyCashier('9'),
                ],
              ),
              const SizedBox(height: 6),
              // Rangée 4: 0 et Backspace
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildNumericKeyCashier('0'),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (_pinController.text.isNotEmpty) {
                          _pinController.text = _pinController.text
                              .substring(0, _pinController.text.length - 1);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF4CAF50).withOpacity(0.4),
                          ),
                        ),
                        child: const Icon(
                          Icons.backspace_outlined,
                          color: Color(0xFF4CAF50),
                          size: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Bouton Clear
              GestureDetector(
                onTap: () {
                  _pinController.clear();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Text(
                    'Effacer',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Widget pour chaque touche numérique (Caissier)
  Widget _buildNumericKeyCashier(String digit) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          _pinController.text += digit;
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF4CAF50).withOpacity(0.4),
                const Color(0xFF2E7D32).withOpacity(0.3),
              ],
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFF4CAF50).withOpacity(0.5),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4CAF50).withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Text(
            digit,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

/// Custom painter for background glow effects
class _GlowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.5, -0.5),
        radius: 0.8,
        colors: [const Color(0xFF4CAF50).withOpacity(0.15), Colors.transparent],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    final paint2 = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.8, 0.8),
        radius: 0.6,
        colors: [const Color(0xFF2E7D32).withOpacity(0.1), Colors.transparent],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
