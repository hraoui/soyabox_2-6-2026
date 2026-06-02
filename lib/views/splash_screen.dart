import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/app_update_controller.dart';
import '../widgets/update_dialog.dart';

// ─────────────────────────────────────────────
// Modèle d'une particule sushi
// ─────────────────────────────────────────────
class _SushiParticle {
  final String emoji;
  double x, y;
  double vx, vy;
  double size;
  double rotation;
  double rotSpeed;
  double opacity;

  _SushiParticle({
    required this.emoji,
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.rotation,
    required this.rotSpeed,
    this.opacity = 0.0,
  });
}

// ─────────────────────────────────────────────
// SplashScreen principal
// ─────────────────────────────────────────────
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ── Animations logo ──────────────────────────
  late final AnimationController _fadeCtrl;
  late final AnimationController _scaleCtrl;
  late final AnimationController _pulseCtrl;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  late final Animation<double> _pulse;

  // ── Particules sushi ─────────────────────────
  late final AnimationController _particleCtrl;
  final List<_SushiParticle> _particles = [];
  final Random _rnd = Random();
  Timer? _spawnTimer;
  bool _promptUpdateAfterLogin = false;

  static const _sushiEmojis = [
    '🍣',
    '🍱',
    '🍤',
    '🥢',
    '🍙',
    '🐟',
    '🦐',
    '🥑',
    '🍚',
    '🫙',
    '🌿',
    '🍜',
  ];

  @override
  void initState() {
    super.initState();

    // Fade + scale du card central
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeInOut);
    _scale = Tween<double>(
      begin: 0.72,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _scaleCtrl, curve: Curves.elasticOut));
    _pulse = Tween<double>(
      begin: 1.0,
      end: 1.06,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _fadeCtrl.forward();
    _scaleCtrl.forward();

    // Contrôleur particules (60 fps continu)
    _particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
    _particleCtrl.addListener(_tickParticles);

    // Spawn périodique de nouvelles particules
    _spawnTimer = Timer.periodic(const Duration(milliseconds: 320), (_) {
      if (mounted) _spawnParticle();
    });
    // Burst initial
    for (int i = 0; i < 12; i++) {
      Future.delayed(Duration(milliseconds: i * 80), _spawnParticle);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runStartupUpdateCheck();
    });

    // Navigation vers login après 5s
    Timer(const Duration(seconds: 5), () {
      if (mounted) {
        print('🎯 [SPLASH] Navigating to /login...');
        Get.offAllNamed('/login');
        if (_promptUpdateAfterLogin) {
          Future.delayed(
            const Duration(milliseconds: 350),
            _showStartupUpdateDialogIfNeeded,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _scaleCtrl.dispose();
    _pulseCtrl.dispose();
    _particleCtrl.dispose();
    _spawnTimer?.cancel();
    super.dispose();
  }

  // ── Crée une nouvelle particule depuis le centre ──
  void _spawnParticle() {
    if (!mounted) return;
    final size = MediaQuery.of(context).size;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final angle = _rnd.nextDouble() * 2 * pi;
    final speed = 0.8 + _rnd.nextDouble() * 2.2;

    setState(() {
      _particles.add(
        _SushiParticle(
          emoji: _sushiEmojis[_rnd.nextInt(_sushiEmojis.length)],
          x: cx + _rnd.nextDouble() * 60 - 30,
          y: cy + _rnd.nextDouble() * 60 - 30,
          vx: cos(angle) * speed,
          vy: sin(angle) * speed - 0.5, // légère gravité vers le haut
          size: 20 + _rnd.nextDouble() * 28,
          rotation: _rnd.nextDouble() * 2 * pi,
          rotSpeed: (_rnd.nextDouble() - 0.5) * 0.12,
          opacity: 0.0,
        ),
      );
    });
  }

  // ── Mise à jour physique des particules ──────
  void _tickParticles() {
    if (!mounted) return;
    final size = MediaQuery.of(context).size;
    setState(() {
      for (final p in _particles) {
        p.x += p.vx * 1.4;
        p.y += p.vy * 1.4;
        p.vy += 0.04; // gravité douce
        p.rotation += p.rotSpeed;
        if (p.opacity < 1.0) p.opacity = (p.opacity + 0.06).clamp(0.0, 1.0);
        // Fade-out en bordure
        final distX = (p.x / size.width - 0.5).abs();
        final distY = (p.y / size.height - 0.5).abs();
        if (distX > 0.42 || distY > 0.42) {
          p.opacity = (p.opacity - 0.04).clamp(0.0, 1.0);
        }
      }
      _particles.removeWhere(
        (p) =>
            p.opacity <= 0 &&
            (p.x < -80 ||
                p.x > size.width + 80 ||
                p.y < -80 ||
                p.y > size.height + 80),
      );
    });
  }

  Future<void> _runStartupUpdateCheck() async {
    try {
      final controller = Get.find<AppUpdateController>();
      await controller.initialize();
      final result = await controller.checkForUpdates();
      if (!mounted) {
        return;
      }
      _promptUpdateAfterLogin = result == AppUpdateCheckState.available;
    } catch (_) {
      // Ignore startup update errors to keep splash non-blocking.
    }
  }

  void _showStartupUpdateDialogIfNeeded() {
    if (Get.isDialogOpen == true) {
      return;
    }

    final controller = Get.find<AppUpdateController>();
    final updateInfo = controller.latestUpdate;
    if (updateInfo == null) {
      return;
    }

    Get.dialog(
      GetBuilder<AppUpdateController>(
        builder: (state) => UpdateDialog(
          currentVersion: state.currentVersion,
          updateInfo: updateInfo,
          isBusy: state.isOpeningDownload,
          onDownload: () async {
            final opened = await state.openLatestUpdate();
            if (opened) {
              if (Get.isDialogOpen == true) {
                Get.back();
              }
              Get.snackbar(
                'Mise a jour',
                'Telechargement lance. Fermez ensuite l application puis executez l installateur.',
                snackPosition: SnackPosition.BOTTOM,
              );
            } else {
              Get.snackbar(
                'Erreur',
                state.errorMessage ??
                    'Impossible d ouvrir le telechargement de la mise a jour.',
                snackPosition: SnackPosition.BOTTOM,
              );
            }
          },
        ),
      ),
      barrierDismissible: true,
    );
  }

  // ── Dégradé de fond style Soyabox ────────────
  static const _bgGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0D0D1A), Color(0xFF1A0A2E), Color(0xFF0A1628)],
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Fond dégradé sombre ──────────────────
          Container(decoration: const BoxDecoration(gradient: _bgGradient)),

          // ── Halo coloré décoratif ────────────────
          _ColorHalo(
            color: const Color(0xFFE14141).withOpacity(0.18),
            offset: const Offset(-0.3, -0.25),
            radius: 320,
          ),
          _ColorHalo(
            color: const Color(0xFF5B3FE8).withOpacity(0.14),
            offset: const Offset(0.35, 0.30),
            radius: 280,
          ),
          _ColorHalo(
            color: const Color(0xFF00C9A7).withOpacity(0.10),
            offset: const Offset(0.0, 0.45),
            radius: 200,
          ),

          // ── Grille subtile style tech ────────────
          const _GridOverlay(),

          // ── Particules sushi ─────────────────────
          ..._particles.map(
            (p) => Positioned(
              left: p.x - p.size / 2,
              top: p.y - p.size / 2,
              child: Opacity(
                opacity: p.opacity.clamp(0.0, 1.0),
                child: Transform.rotate(
                  angle: p.rotation,
                  child: Text(p.emoji, style: TextStyle(fontSize: p.size)),
                ),
              ),
            ),
          ),

          // ── Card central animé ───────────────────
          Center(
            child: FadeTransition(
              opacity: _fade,
              child: ScaleTransition(
                scale: _scale,
                child: AnimatedBuilder(
                  animation: _pulse,
                  builder: (_, child) =>
                      Transform.scale(scale: _pulse.value, child: child),
                  child: _SoyaCard(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Card glassmorphism style Soyabox
// ─────────────────────────────────────────────
class _SoyaCard extends StatelessWidget {
  const _SoyaCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: Colors.white.withOpacity(0.07),
        border: Border.all(color: Colors.white.withOpacity(0.18), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE14141).withOpacity(0.25),
            blurRadius: 48,
            spreadRadius: -6,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.45),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Badge "POS" en haut à droite
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [Color(0xFFE14141), Color(0xFFFF6B6B)],
                ),
              ),
              child: const Text(
                'POS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Icône app
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.08),
              border: Border.all(color: Colors.white.withOpacity(0.15)),
            ),
            child: Image.asset('assets/branding/app_icon.png', height: 72),
          ),
          const SizedBox(height: 20),

          // Titre
          const Text(
            'Bienvenue sur votre POS',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFFE14141),
              letterSpacing: 0.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Sous-titre
          Text(
            'Centralisez les commandes\nsalle, web & mobile.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.65),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),

          // Loader stylisé
          _AnimatedLoader(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Loader 3 points pulsants
// ─────────────────────────────────────────────
class _AnimatedLoader extends StatefulWidget {
  @override
  State<_AnimatedLoader> createState() => _AnimatedLoaderState();
}

class _AnimatedLoaderState extends State<_AnimatedLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _c,
          builder: (_, _) {
            final t = ((_c.value - i * 0.2) % 1.0).clamp(0.0, 1.0);
            final scale = 0.6 + 0.6 * sin(t * pi);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color.lerp(
                      const Color(0xFFE14141),
                      const Color(0xFFFF6B6B),
                      t,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────
// Halo coloré décoratif
// ─────────────────────────────────────────────
class _ColorHalo extends StatelessWidget {
  final Color color;
  final Offset offset; // en fraction de la taille écran
  final double radius;

  const _ColorHalo({
    required this.color,
    required this.offset,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Positioned(
      left: size.width * (0.5 + offset.dx) - radius,
      top: size.height * (0.5 + offset.dy) - radius,
      child: Container(
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, Colors.transparent]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Grille subtile décorative
// ─────────────────────────────────────────────
class _GridOverlay extends StatelessWidget {
  const _GridOverlay();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _GridPainter());
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.035)
      ..strokeWidth = 0.8;
    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
