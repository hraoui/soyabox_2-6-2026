import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../utils/badge_code_utils.dart';

class CashierPinLoginScreen extends StatefulWidget {
  const CashierPinLoginScreen({super.key});

  @override
  State<CashierPinLoginScreen> createState() => _CashierPinLoginScreenState();
}

class _CashierPinLoginScreenState extends State<CashierPinLoginScreen> {
  final TextEditingController _pinController = TextEditingController();
  final FocusNode _badgeListenerFocusNode = FocusNode(debugLabel: 'cashier_badge_listener');
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _isBadgeLoading = false;

  // Badge HID
  Timer? _badgeCommitTimer;
  String _badgeBuffer = '';
  DateTime? _lastBadgeKeyAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _badgeListenerFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _badgeCommitTimer?.cancel();
    _badgeListenerFocusNode.dispose();
    _pinController.dispose();
    super.dispose();
  }

  // ── Badge HID ──────────────────────────────────────────────────────────────
  void _handleBadgeKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent || _isBadgeLoading || _isLoading) return;

    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter ||
        key == LogicalKeyboardKey.tab) {
      unawaited(_commitBadgeScan());
      return;
    }

    final char = event.character;
    if (char == null || char.isEmpty) return;
    if (char.codeUnitAt(0) < 32) return;

    final now = DateTime.now();
    if (_lastBadgeKeyAt != null &&
        now.difference(_lastBadgeKeyAt!) > const Duration(milliseconds: 350)) {
      _badgeBuffer = '';
    }
    _lastBadgeKeyAt = now;
    _badgeBuffer += char;

    _badgeCommitTimer?.cancel();
    _badgeCommitTimer = Timer(
      const Duration(milliseconds: 180),
      () => unawaited(_commitBadgeScan()),
    );
  }

  Future<void> _commitBadgeScan() async {
    _badgeCommitTimer?.cancel();
    final badgeCode = normalizeBadgeCode(_badgeBuffer);
    _badgeBuffer = '';
    _lastBadgeKeyAt = null;
    if (badgeCode.isEmpty || _isBadgeLoading) return;

    if (mounted) setState(() => _isBadgeLoading = true);

    try {
      final auth = Get.find<AuthController>();
      final success = await auth.loginCashierWithBadge(badgeCode);
      final role = auth.currentRole?.trim().toLowerCase();

      if (!success || auth.currentUser == null) {
        throw Exception('Badge refusé');
      }
      if (role != 'cashier') {
        throw Exception('Accès réservé aux caissiers');
      }
      if (mounted) Get.offAllNamed('/cashier-dashboard');
    } catch (e) {
      if (mounted) {
        Get.snackbar(
          'Badge refusé',
          e.toString(),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF388E3C),
          colorText: Colors.white,
          borderRadius: 8,
          margin: const EdgeInsets.all(16),
        );
        Future.delayed(
          const Duration(milliseconds: 300),
          () => _badgeListenerFocusNode.requestFocus(),
        );
      }
    } finally {
      if (mounted) setState(() => _isBadgeLoading = false);
    }
  }

  // ── PIN Login ──────────────────────────────────────────────────────────────
  Future<void> _handlePinLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final pin = _pinController.text.trim();
      final auth = Get.find<AuthController>();
      final success = await auth.loginCashierWithPin(pin);
      final role = auth.currentRole?.trim().toLowerCase();

      if (success && auth.currentUser != null && role == 'cashier') {
        if (mounted) Get.offAllNamed('/cashier-dashboard');
      } else {
        throw Exception("Échec de l'authentification: rôle caissier non trouvé");
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
        Future.delayed(
          const Duration(milliseconds: 300),
          () => _badgeListenerFocusNode.requestFocus(),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _badgeListenerFocusNode,
      autofocus: true,
      onKeyEvent: _handleBadgeKeyEvent,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0A0A0A), Color(0xFF1A1A1A), Color(0xFF0A2D0A)],
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
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 32),
                        _buildPinCard(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
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
            // ── Affichage PIN / Badge (même style que admin) ────────────────
            ValueListenableBuilder(
              valueListenable: _pinController,
              builder: (_, __, ___) {
                final txt = _pinController.text;
                return GestureDetector(
                  onTap: () => _badgeListenerFocusNode.requestFocus(),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: txt.isEmpty
                            ? Colors.white.withOpacity(0.12)
                            : const Color(0xFF4CAF50).withOpacity(0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          txt.isEmpty ? Icons.badge : Icons.lock_outline,
                          color: const Color(0xFF4CAF50),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            txt.isEmpty
                                ? 'PIN ou passez votre badge'
                                : '●' * txt.length,
                            style: TextStyle(
                              color: txt.isEmpty
                                  ? Colors.white.withOpacity(0.4)
                                  : Colors.white,
                              fontSize: txt.isEmpty ? 14 : 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (_isBadgeLoading)
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Color(0xFF4CAF50)),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // ── Clavier + champ PIN côte à côte ────────────────────────────
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 300;
                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildPinInputField()),
                      const SizedBox(width: 12),
                      Expanded(child: _buildNumericKeyboard()),
                    ],
                  );
                }
                return Column(
                  children: [
                    _buildPinInputField(),
                    const SizedBox(height: 12),
                    _buildNumericKeyboard(),
                  ],
                );
              },
            ),

            const SizedBox(height: 20),

            // ── Bouton connexion ────────────────────────────────────────────
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
                label: Text(
                  _isLoading ? 'Connexion...' : 'Se connecter',
                  style: const TextStyle(
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

            const SizedBox(height: 12),

            // ── Indice badge ────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.nfc, size: 14, color: Colors.white.withOpacity(0.4)),
                const SizedBox(width: 6),
                Text(
                  'Ou passez votre badge NFC/HID',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.4),
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Retour login ────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Get.offAllNamed('/login'),
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Retour Login', style: TextStyle(fontSize: 14)),
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

  Widget _buildPinInputField() {
    return ValueListenableBuilder(
      valueListenable: _pinController,
      builder: (context, value, _) {
        return Column(
          children: [
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
            if (_pinController.text.isNotEmpty)
              Text(
                '${_pinController.text.length} chiffres',
                style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.6)),
              ),
          ],
        );
      },
    );
  }

  Widget _buildNumericKeyboard() {
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
              ),
            ],
          ),
          child: Column(
            children: [
              _numRow(['1', '2', '3']),
              const SizedBox(height: 6),
              _numRow(['4', '5', '6']),
              const SizedBox(height: 6),
              _numRow(['7', '8', '9']),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(flex: 2, child: _numKey('0')),
                  const SizedBox(width: 6),
                  Expanded(child: _deleteKey()),
                ],
              ),
              const SizedBox(height: 8),
              _clearButton(),
            ],
          ),
        );
      },
    );
  }

  Widget _numRow(List<String> digits) {
    return Row(
      children: digits.expand((d) => [
        Expanded(child: _numKey(d)),
        if (d != digits.last) const SizedBox(width: 6),
      ]).toList(),
    );
  }

  Widget _numKey(String d) {
    return GestureDetector(
      onTap: () {
        _pinController.text += d;
        _badgeListenerFocusNode.requestFocus();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF4CAF50).withOpacity(0.4),
              const Color(0xFF2E7D32).withOpacity(0.3),
            ],
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4CAF50).withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Text(
          d,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _deleteKey() {
    return GestureDetector(
      onTap: () {
        if (_pinController.text.isNotEmpty) {
          _pinController.text =
              _pinController.text.substring(0, _pinController.text.length - 1);
        }
        _badgeListenerFocusNode.requestFocus();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF4CAF50).withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.4)),
        ),
        child: const Icon(Icons.backspace_outlined, color: Color(0xFF4CAF50), size: 14),
      ),
    );
  }

  Widget _clearButton() {
    return GestureDetector(
      onTap: () {
        _pinController.clear();
        _badgeListenerFocusNode.requestFocus();
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
    );
  }
}

// ── Glow Painter ──────────────────────────────────────────────────────────────
class _GlowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.5, -0.5),
          radius: 0.8,
          colors: [const Color(0xFF4CAF50).withOpacity(0.15), Colors.transparent],
        ).createShader(r),
    );
    canvas.drawRect(
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0.8, 0.8),
          radius: 0.6,
          colors: [const Color(0xFF2E7D32).withOpacity(0.1), Colors.transparent],
        ).createShader(r),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}