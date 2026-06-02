// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';

// ── Palette clavier ───────────────────────────────────────────────────────────
class _KB {
  static const keyBg        = Color(0x14FFFFFF);
  static const keyBorder    = Color(0x22FFFFFF);
  static const keyText      = Colors.white;

  static const letterBg     = Color(0x1A1565C0);
  static const letterBorder = Color(0x661565C0);

  static const accentBg     = Color(0xFFD32F2F);

  static const deleteBg     = Color(0x33FF5252);
  static const deleteBorder = Color(0x66FF5252);

  static const clearBg      = Color(0x18FFFFFF);
  static const divider      = Color(0x1AFFFFFF);
}

class AdminPinLoginScreen extends StatefulWidget {
  const AdminPinLoginScreen({super.key});

  @override
  State<AdminPinLoginScreen> createState() =>
      _AdminPinLoginScreenState();
}

class _AdminPinLoginScreenState
    extends State<AdminPinLoginScreen> {
  final TextEditingController _pinController =
      TextEditingController();

  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _showPin = false;

  // Modes clavier
  bool _isNumericMode = false;
  bool _isUpperCase = false;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  // ── Saisie clavier ────────────────────────────────────────────────────────
  void _onKeyTap(String char) {
    setState(() {
      _pinController.text += char;
    });
  }

  void _onBackspace() {
    if (_pinController.text.isNotEmpty) {
      setState(() {
        _pinController.text = _pinController.text.substring(
          0,
          _pinController.text.length - 1,
        );
      });
    }
  }

  void _onClear() {
    setState(() {
      _pinController.clear();
    });
  }

  // ── Login ────────────────────────────────────────────────────────────────
  Future<void> _handlePinLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final pin = _pinController.text.trim();

      final auth = Get.find<AuthController>();

      final success =
          await auth.loginSuperAdminWithPin(pin);

      final role =
          auth.currentRole?.trim().toLowerCase();

      if (!success || auth.currentUser == null) {
        throw Exception(
          "Échec de l'authentification",
        );
      }

      if (role != 'admin' &&
          role != 'superadmin') {
        throw Exception(
          'Accès réservé aux administrateurs',
        );
      }

      if (mounted) {
        Get.offAllNamed('/financial-dashboard');
      }
    } catch (e) {
      if (mounted) {
        Get.snackbar(
          'Erreur de connexion',
          e.toString(),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFD32F2F),
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

  // ── UI ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
   return Scaffold(
  body: Stack(
    children: [
      Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0A0A0A),
              Color(0xFF1A1A1A),
              Color(0xFF2D0A0A),
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _GlowPainter(),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints:
                      const BoxConstraints(
                    maxWidth: 860,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 32),
                      _buildBody(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      // ── BOUTON RETOUR ─────────────────────
      SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Align(
            alignment: Alignment.topLeft,
            child: GestureDetector(
              onTap: () {
                Get.offAllNamed('/login');
              },
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius:
                      BorderRadius.circular(14),
                  border: Border.all(
                    color:
                        Colors.white.withOpacity(0.1),
                  ),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
        ),
      ),
    ],
  ),
);
  }

  // ── Header ───────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFFD32F2F)
                    .withOpacity(0.8),
                const Color(0xFFB71C1C)
                    .withOpacity(0.9),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD32F2F)
                    .withOpacity(0.5),
                blurRadius: 28,
                spreadRadius: 4,
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/branding/app_icon.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'ADMIN PIN',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 3,
            shadows: [
              Shadow(
                color: Color(0xFFD32F2F),
                blurRadius: 10,
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Accès au tableau de bord financier',
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withOpacity(0.65),
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  // ── Body ─────────────────────────────────────────────────────────────────
  Widget _buildBody() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth > 560;

        if (wide) {
          return Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: _formCard(),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 6,
                child: _keyboardCard(),
              ),
            ],
          );
        }

        return Column(
          children: [
            _formCard(),
            const SizedBox(height: 16),
            _keyboardCard(),
          ],
        );
      },
    );
  }

  Widget _cardShell({
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  // ── Formulaire ───────────────────────────────────────────────────────────
  Widget _formCard() {
    return _cardShell(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(
                      0xFFD32F2F,
                    ).withOpacity(0.2),
                    borderRadius:
                        BorderRadius.circular(
                      10,
                    ),
                  ),
                  child: const Icon(
                    Icons.lock_outline,
                    color:
                        Color(0xFFFF5252),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Authentification',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight:
                        FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            ValueListenableBuilder(
              valueListenable: _pinController,
              builder: (_, val, __) {
                final txt =
                    _pinController.text;

                return Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white
                        .withOpacity(0.07),
                    borderRadius:
                        BorderRadius.circular(
                      12,
                    ),
                    border: Border.all(
                      color: txt.isEmpty
                          ? Colors.white
                              .withOpacity(
                              0.12,
                            )
                          : const Color(
                              0xFFFF5252,
                            ).withOpacity(
                              0.5,
                            ),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.lock_outline,
                        color:
                            Color(0xFFFF5252),
                        size: 18,
                      ),
                      const SizedBox(
                          width: 10),
                      Expanded(
                        child: Text(
                          txt.isEmpty
                              ? 'Code PIN'
                              : (_showPin
                                  ? txt
                                  : '●' *
                                      txt
                                          .length),
                          style: TextStyle(
                            fontSize:
                                txt.isEmpty
                                    ? 14
                                    : 20,
                            fontWeight:
                                FontWeight
                                    .w700,
                            letterSpacing:
                                _showPin
                                    ? 2
                                    : 4,
                            color:
                                txt.isEmpty
                                    ? Colors
                                        .white
                                        .withOpacity(
                                        0.4,
                                      )
                                    : Colors
                                        .white,
                          ),
                        ),
                      ),
                      if (txt.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _showPin =
                                  !_showPin;
                            });
                          },
                          child: Icon(
                            _showPin
                                ? Icons
                                    .visibility_off
                                : Icons
                                    .visibility,
                            color: Colors.white
                                .withOpacity(
                              0.5,
                            ),
                            size: 18,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 48,
              child:
                  ElevatedButton.icon(
                onPressed: _isLoading
                    ? null
                    : _handlePinLogin,
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child:
                            CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation(
                            Colors.white,
                          ),
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.login,
                        size: 18,
                      ),
                label: Text(
                  _isLoading
                      ? 'Connexion...'
                      : 'Se connecter',
                ),
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(
                    0xFFD32F2F,
                  ),
                  foregroundColor:
                      Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Keyboard ─────────────────────────────────────────────────────────────
  Widget _keyboardCard() {
    return _cardShell(
      child: _InlineKeyboard(
        isNumericMode: _isNumericMode,
        isUpperCase: _isUpperCase,

        onKey: _onKeyTap,
        onBackspace: _onBackspace,
        onClear: _onClear,
        onSubmit: _handlePinLogin,

        onToggleMode: () {
          setState(() {
            _isNumericMode =
                !_isNumericMode;
          });
        },

        onToggleCase: () {
          setState(() {
            _isUpperCase =
                !_isUpperCase;
          });
        },
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// KEYBOARD
// ════════════════════════════════════════════════════════════════════════════

class _InlineKeyboard extends StatelessWidget {
  const _InlineKeyboard({
    required this.isNumericMode,
    required this.isUpperCase,
    required this.onKey,
    required this.onBackspace,
    required this.onClear,
    required this.onSubmit,
    required this.onToggleMode,
    required this.onToggleCase,
  });

  final bool isNumericMode;
  final bool isUpperCase;

  final ValueChanged<String> onKey;

  final VoidCallback onBackspace;
  final VoidCallback onClear;
  final VoidCallback onSubmit;

  final VoidCallback onToggleMode;
  final VoidCallback onToggleCase;

  static const _row1 = [
    'A',
    'Z',
    'E',
    'R',
    'T',
    'Y',
    'U',
    'I',
    'O',
    'P',
  ];

  static const _row2 = [
    'Q',
    'S',
    'D',
    'F',
    'G',
    'H',
    'J',
    'K',
    'L',
  ];

  static const _row3 = [
    'W',
    'X',
    'C',
    'V',
    'B',
    'N',
    'M',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding:
                  const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(
                  0xFF1565C0,
                ).withOpacity(0.2),
                borderRadius:
                    BorderRadius.circular(
                  10,
                ),
              ),
              child: Icon(
                isNumericMode
                    ? Icons.dialpad
                    : Icons
                        .keyboard_alt_outlined,
                color:
                    const Color(0xFF64B5F6),
                size: 20,
              ),
            ),

            const SizedBox(width: 10),

            Text(
              isNumericMode
                  ? 'Pavé numérique'
                  : 'Clavier',
              style: const TextStyle(
                fontSize: 15,
                fontWeight:
                    FontWeight.w700,
                color: Colors.white,
              ),
            ),

            const Spacer(),

            GestureDetector(
              onTap: onToggleMode,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white
                      .withOpacity(0.08),
                  borderRadius:
                      BorderRadius.circular(
                    20,
                  ),
                ),
                child: Text(
                  isNumericMode
                      ? 'ABC'
                      : '123',
                  style:
                      const TextStyle(
                    color: Colors.white,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        Divider(
          color: _KB.divider,
          height: 1,
        ),

        const SizedBox(height: 12),

        isNumericMode
            ? _buildNumpad()
            : _buildAlpha(),
      ],
    );
  }

  // ── NUMPAD ───────────────────────────────────────────────────────────────
  Widget _buildNumpad() {
    return Column(
      children: [
        _numRow(['1', '2', '3']),
        const SizedBox(height: 6),
        _numRow(['4', '5', '6']),
        const SizedBox(height: 6),
        _numRow(['7', '8', '9']),
        const SizedBox(height: 6),

        Row(
          children: [
            Expanded(
              flex: 2,
              child: _numKey('0'),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _deleteKey(),
            ),
          ],
        ),

        const SizedBox(height: 10),

        _clearAndSubmit(),
      ],
    );
  }

  Widget _numRow(List<String> digits) {
    return Row(
      children: digits.expand((d) {
        return [
          Expanded(child: _numKey(d)),
          if (d != digits.last)
            const SizedBox(width: 6),
        ];
      }).toList(),
    );
  }

  Widget _numKey(String d) {
    return GestureDetector(
      onTap: () => onKey(d),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFD32F2F)
                  .withOpacity(0.35),
              const Color(0xFFB71C1C)
                  .withOpacity(0.25),
            ],
          ),
          borderRadius:
              BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            d,
            style: const TextStyle(
              fontSize: 18,
              fontWeight:
                  FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  // ── ALPHA ────────────────────────────────────────────────────────────────
  Widget _buildAlpha() {
    final row1 = _row1
        .map(
          (e) => isUpperCase
              ? e.toUpperCase()
              : e.toLowerCase(),
        )
        .toList();

    final row2 = _row2
        .map(
          (e) => isUpperCase
              ? e.toUpperCase()
              : e.toLowerCase(),
        )
        .toList();

    final row3 = _row3
        .map(
          (e) => isUpperCase
              ? e.toUpperCase()
              : e.toLowerCase(),
        )
        .toList();

    return Column(
      children: [
        _letterRow(row1),

        const SizedBox(height: 5),

        _letterRow(row2),

        const SizedBox(height: 5),

        Row(
          children: [
            GestureDetector(
              onTap: onToggleCase,
              child: Container(
                height: 36,
                width: 50,
                decoration: BoxDecoration(
                  color: isUpperCase
                      ? const Color(
                          0xFFD32F2F,
                        )
                      : _KB.keyBg,
                  borderRadius:
                      BorderRadius.circular(
                    7,
                  ),
                  border: Border.all(
                    color: isUpperCase
                        ? const Color(
                            0xFFFF5252,
                          )
                        : _KB.keyBorder,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.keyboard_capslock,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 3),

            Expanded(
              child: _letterRow(row3),
            ),
          ],
        ),

        const SizedBox(height: 8),

        Row(
          children: [
            for (final d in [
              '1',
              '2',
              '3',
              '4',
              '5',
              '6',
              '7',
              '8',
              '9',
              '0',
            ]) ...[
              Expanded(
                child: _quickNumKey(d),
              ),
              if (d != '0')
                const SizedBox(width: 3),
            ],
          ],
        ),

        const SizedBox(height: 10),

        _clearAndSubmit(),
      ],
    );
  }

  Widget _letterRow(
    List<String> letters,
  ) {
    return Row(
      children: letters.expand((l) {
        return [
          Expanded(
            child: _letterKey(l),
          ),
          if (l != letters.last)
            const SizedBox(width: 3),
        ];
      }).toList(),
    );
  }

  Widget _letterKey(String l) {
    return GestureDetector(
      onTap: () => onKey(l),
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: _KB.letterBg,
          borderRadius:
              BorderRadius.circular(7),
          border: Border.all(
            color: _KB.letterBorder,
          ),
        ),
        child: Center(
          child: Text(
            l,
            style: const TextStyle(
              fontSize: 11,
              fontWeight:
                  FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _quickNumKey(String d) {
    return GestureDetector(
      onTap: () => onKey(d),
      child: Container(
        height: 32,
        decoration: BoxDecoration(
          color: _KB.keyBg,
          borderRadius:
              BorderRadius.circular(7),
          border: Border.all(
            color: _KB.keyBorder,
          ),
        ),
        child: Center(
          child: Text(
            d,
            style: TextStyle(
              fontSize: 12,
              fontWeight:
                  FontWeight.w700,
              color: Colors.white
                  .withOpacity(0.85),
            ),
          ),
        ),
      ),
    );
  }

  // ── COMMON ───────────────────────────────────────────────────────────────
  Widget _deleteKey() {
    return GestureDetector(
      onTap: onBackspace,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: _KB.deleteBg,
          borderRadius:
              BorderRadius.circular(10),
          border: Border.all(
            color: _KB.deleteBorder,
          ),
        ),
        child: const Center(
          child: Icon(
            Icons.backspace_outlined,
            color: Color(0xFFFF5252),
          ),
        ),
      ),
    );
  }

  Widget _clearAndSubmit() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: onClear,
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: _KB.clearBg,
                borderRadius:
                    BorderRadius.circular(
                  10,
                ),
              ),
              child: const Center(
                child: Text(
                  'Effacer',
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(width: 8),

        if (!isNumericMode) ...[
          GestureDetector(
            onTap: onBackspace,
            child: Container(
              height: 44,
              width: 52,
              decoration: BoxDecoration(
                color: _KB.deleteBg,
                borderRadius:
                    BorderRadius.circular(
                  10,
                ),
              ),
              child: const Icon(
                Icons.backspace_outlined,
                color:
                    Color(0xFFFF5252),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],

        Expanded(
          child: GestureDetector(
            onTap: onSubmit,
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: _KB.accentBg,
                borderRadius:
                    BorderRadius.circular(
                  10,
                ),
              ),
              child: const Center(
                child: Text(
                  'Valider',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Glow Painter ────────────────────────────────────────────────────────────
class _GlowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(
        0,
        0,
        size.width,
        size.height,
      ),
      Paint()
        ..shader = RadialGradient(
          center:
              const Alignment(-0.5, -0.5),
          radius: 0.8,
          colors: [
            const Color(0xFFD32F2F)
                .withOpacity(0.15),
            Colors.transparent,
          ],
        ).createShader(
          Rect.fromLTWH(
            0,
            0,
            size.width,
            size.height,
          ),
        ),
    );
  }

  @override
  bool shouldRepaint(
    covariant CustomPainter oldDelegate,
  ) {
    return false;
  }
}