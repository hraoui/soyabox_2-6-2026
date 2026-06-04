import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../controllers/pos_controller.dart';
import '../controllers/sync_controller.dart';
import '../utils/badge_code_utils.dart';

class PosLockScreen extends StatefulWidget {
  const PosLockScreen({super.key});

  @override
  State<PosLockScreen> createState() => _PosLockScreenState();
}

class _PosLockScreenState extends State<PosLockScreen> {
  final TextEditingController _pinController = TextEditingController();
  final FocusNode _badgeListenerFocusNode = FocusNode(
    debugLabel: 'pos_badge_listener',
  );
  Timer? _badgeCommitTimer;
  String _badgeBuffer = '';
  DateTime? _lastBadgeKeyAt;
  String _badgeStatus = 'Lecture badge active';
  bool _isBadgeUnlocking = false;

  @override
  void dispose() {
    _badgeCommitTimer?.cancel();
    _badgeListenerFocusNode.dispose();
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pos = Get.find<PosController>();

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
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo et titre
                      _buildHeader(),
                      const SizedBox(height: 32),

                      // GRILLE : Formulaire et clavier à gauche, infos + actions à droite
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth > 800;
                          return isWide
                              ? Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Expanded(flex: 1, child: _unlockFormCard(pos)),
                                    const SizedBox(width: 16),
                                    Expanded(flex: 1, child: _infoActionCard(pos)),
                                  ],
                                )
                              : Column(
                                  children: [
                                    _unlockFormCard(pos),
                                    const SizedBox(height: 16),
                                    _infoActionCard(pos),
                                  ],
                                );
                        },
                      ),
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
        // Logo circulaire
        Container(
          width: 100,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFFD32F2F).withOpacity(0.8),
                const Color(0xFFB71C1C).withOpacity(0.9),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD32F2F).withOpacity(0.5),
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
          'POS VERROUILLÉ',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 3,
            shadows: [Shadow(color: Color(0xFFD32F2F), blurRadius: 10)],
          ),
        ),
        
     ],
    );
  }

  Widget _unlockFormCard(PosController pos) {
    return Container(
      padding: const EdgeInsets.all(24),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFD32F2F).withOpacity(0.8),
                      const Color(0xFFB71C1C).withOpacity(0.9),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD32F2F).withOpacity(0.4),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.lock_outline,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Déverrouillage',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWideScreen = constraints.maxWidth > 500;

              if (isWideScreen) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 1,
                      child: _buildPinInput(),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 1,
                      child: _buildNumericKeyboard(),
                    ),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildPinInput(),
                    const SizedBox(height: 16),
                    _buildNumericKeyboard(),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _infoActionCard(PosController pos) {
    return KeyboardListener(
      focusNode: _badgeListenerFocusNode,
      autofocus: true,
      onKeyEvent: (event) => _handleBadgeKeyEvent(event, pos),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _infoCard(),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => _badgeListenerFocusNode.requestFocus(),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _isBadgeUnlocking ? Icons.sync_rounded : Icons.badge_outlined,
                      size: 20,
                      color: const Color(0xFF4CAF50),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Lecteur badge',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _badgeStatus,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.7),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (pos.error != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFD32F2F).withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFFD32F2F).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Color(0xFFFF5252),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      pos.error!,
                      style: const TextStyle(
                        color: Color(0xFFFF5252),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final pin = _pinController.text.trim();
                      await _submitPin(pos, pin);
                    },
                    icon: const Icon(Icons.lock_open, size: 18),
                    label: const Text(
                      'Déverrouiller',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD32F2F),
                      foregroundColor: Colors.white,
                      elevation: 8,
                      shadowColor: const Color(0xFFD32F2F).withOpacity(0.6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: () => Get.offAllNamed('/login'),
                    icon: const Icon(Icons.login, size: 18),
                    label: const Text(
                      'Retour Login',
                      style: TextStyle(fontSize: 14),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withOpacity(0.3)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Widget pour le champ d'entrée du PIN
  Widget _buildPinInput() {
    return ValueListenableBuilder(
      valueListenable: _pinController,
      builder: (context, value, _) {
        return Column(
          children: [
            // Affichage des points du PIN
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.15)),
              ),
              child: Text(
                _pinController.text.isEmpty
                    ? 'Entrez votre PIN'
                    : '• ' * _pinController.text.length,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _pinController.text.isEmpty
                      ? Colors.white.withOpacity(0.5)
                      : Colors.white,
                  letterSpacing: 4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12),
            // Compteur de caractères
            if (_pinController.text.isNotEmpty)
              Text(
                '${_pinController.text.length} caractères',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
          ],
        );
      },
    );
  }

  /// Widget pour le clavier numérique
  Widget _buildNumericKeyboard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD32F2F).withOpacity(0.2),
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
              _buildNumericKey('1'),
              const SizedBox(width: 8),
              _buildNumericKey('2'),
              const SizedBox(width: 8),
              _buildNumericKey('3'),
            ],
          ),
          const SizedBox(height: 8),
          // Rangée 2: 4 5 6
          Row(
            children: [
              _buildNumericKey('4'),
              const SizedBox(width: 8),
              _buildNumericKey('5'),
              const SizedBox(width: 8),
              _buildNumericKey('6'),
            ],
          ),
          const SizedBox(height: 8),
          // Rangée 3: 7 8 9
          Row(
            children: [
              _buildNumericKey('7'),
              const SizedBox(width: 8),
              _buildNumericKey('8'),
              const SizedBox(width: 8),
              _buildNumericKey('9'),
            ],
          ),
          const SizedBox(height: 8),
          // Rangée 4: 0 et boutons de contrôle
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildNumericKey('0'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (_pinController.text.isNotEmpty) {
                      _pinController.text =
                          _pinController.text.substring(0, _pinController.text.length - 1);
                      setState(() {});
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF5252).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFFF5252).withOpacity(0.4),
                      ),
                    ),
                    child: const Icon(
                      Icons.backspace_outlined,
                      color: Color(0xFFFF5252),
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Bouton Clear
          GestureDetector(
            onTap: () {
              _pinController.clear();
              setState(() {});
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Text(
                'Effacer',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Widget pour chaque touche numérique
  Widget _buildNumericKey(String digit) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          _pinController.text += digit;
          setState(() {});
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFFD32F2F).withOpacity(0.4),
                const Color(0xFFB71C1C).withOpacity(0.3),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFFD32F2F).withOpacity(0.5),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD32F2F).withOpacity(0.2),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            digit,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 1,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _infoCard() {
    return Container(
      padding: const EdgeInsets.all(24),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFFF9800).withOpacity(0.8),
                      const Color(0xFFFF5722).withOpacity(0.9),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'POS Info',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoItem(Icons.table_restaurant, 'Sur place (tables)'),
                const SizedBox(height: 10),
                _buildInfoItem(Icons.shopping_bag, 'À emporter / livraison'),
                const SizedBox(height: 10),
                _buildInfoItem(Icons.phone_iphone, 'Commandes mobiles et web'),
                const SizedBox(height: 10),
                _buildInfoItem(Icons.payments, 'Paiements et encaissements'),
                const SizedBox(height: 10),
                _buildInfoItem(Icons.restaurant, 'Suivi des tickets cuisine'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFF4CAF50).withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.lightbulb_outline,
                  color: Color(0xFF4CAF50),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Connexion possible avec le PIN ou avec le badge serveur.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.9),
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFFFF5252)),
        const SizedBox(width: 10),
        Text(
          text,
          style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.8)),
        ),
      ],
    );
  }

  Future<void> _submitPin(PosController pos, String pin) async {
    final ok = await pos.unlockWithPin(pin);
    if (!ok || !mounted) return;
    if (Get.isRegistered<SyncController>()) {
      unawaited(Get.find<SyncController>().syncNow());
    }
    _pinController.clear();
    Get.offAllNamed('/pos-menu');
  }

  void _handleBadgeKeyEvent(KeyEvent event, PosController pos) {
    if (event is! KeyDownEvent || _isBadgeUnlocking) return;

    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter ||
        key == LogicalKeyboardKey.tab) {
      unawaited(_commitBadgeScan(pos));
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

    final preview = normalizeBadgeCode(_badgeBuffer);
    if (preview.isNotEmpty && mounted) {
      setState(() {
        _badgeStatus = 'Badge détecté: ${_badgePreview(preview)}';
      });
    }

    _badgeCommitTimer?.cancel();
    _badgeCommitTimer = Timer(
      const Duration(milliseconds: 180),
      () => unawaited(_commitBadgeScan(pos)),
    );
  }

  Future<void> _commitBadgeScan(PosController pos) async {
    _badgeCommitTimer?.cancel();
    final badgeCode = normalizeBadgeCode(_badgeBuffer);
    _badgeBuffer = '';
    _lastBadgeKeyAt = null;
    if (badgeCode.isEmpty || _isBadgeUnlocking) return;

    if (mounted) {
      setState(() {
        _isBadgeUnlocking = true;
        _badgeStatus = 'Lecture du badge en cours...';
      });
    }

    final ok = await pos.unlockWithBadge(badgeCode);
    if (!mounted) return;

    if (ok) {
      if (Get.isRegistered<SyncController>()) {
        unawaited(Get.find<SyncController>().syncNow());
      }
      _pinController.clear();
      Get.offAllNamed('/pos-menu');
      return;
    }

    setState(() {
      _isBadgeUnlocking = false;
      _badgeStatus = 'Badge refusé: ${_badgePreview(badgeCode)}';
    });
  }

  String _badgePreview(String badgeCode) {
    if (badgeCode.length <= 18) return badgeCode;
    return '${badgeCode.substring(0, 18)}...';
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
        colors: [const Color(0xFFD32F2F).withOpacity(0.15), Colors.transparent],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    final paint2 = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.8, 0.8),
        radius: 0.6,
        colors: [const Color(0xFFFF1744).withOpacity(0.1), Colors.transparent],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
