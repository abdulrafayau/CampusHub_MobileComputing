import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../data/app_store.dart';
import '../auth/login_screen.dart';
import '../onboarding/onboarding_screen.dart';
import '../shell/home_shell.dart';

/// Choreographed launch sequence (~3.4 s):
///   1. Building photo fades in with a slow push-in.
///   2. A navy plinth rises from the bottom like a curtain.
///   3. The AU crest pops onto the plinth edge while a ring draws a full loop.
///   4. "LoopAir" sets letter by letter, then the tagline.
///   5. A hairline progress rule runs underneath, then everything dissolves.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 3400));
  late final AnimationController _exit =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 420));

  Animation<double> _iv(double a, double b, [Curve curve = Curves.easeOutCubic]) =>
      CurvedAnimation(parent: _c, curve: Interval(a, b, curve: curve));

  late final _photo = _iv(0.0, 0.45, Curves.easeOut);
  late final _push = _iv(0.0, 1.0, Curves.easeOutSine);
  late final _plinth = _iv(0.10, 0.36, Curves.easeOutQuart);
  late final _crest = _iv(0.30, 0.50, Curves.easeOutBack);
  late final _ring = _iv(0.34, 0.66, Curves.easeInOutCubic);
  late final _tag = _iv(0.62, 0.78);
  late final _foot = _iv(0.70, 0.86);
  late final _bar = _iv(0.05, 0.96, Curves.easeInOut);

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    _c.forward().whenComplete(_leave);
  }

  Future<void> _leave() async {
    final store = context.read<AppStore>();
    while (!store.ready) {
      await Future.delayed(const Duration(milliseconds: 60));
    }
    await _exit.forward();
    if (!mounted) return;
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (_, _, _) => store.currentUser != null
          ? const HomeShell()
          : (store.onboarded ? const LoginScreen() : const OnboardingScreen()),
      transitionsBuilder: (_, a, _, child) => FadeTransition(
        opacity: CurvedAnimation(parent: a, curve: Curves.easeOut),
        child: child,
      ),
    ));
  }

  @override
  void dispose() {
    _c.dispose();
    _exit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final plinthTop = size.height * 0.56;
    const crest = 92.0;

    return Scaffold(
      backgroundColor: AppColors.navy,
      body: AnimatedBuilder(
        animation: Listenable.merge([_c, _exit]),
        builder: (context, _) {
          final exitT = Curves.easeIn.transform(_exit.value);
          return Opacity(
            opacity: 1 - exitT,
            child: Transform.scale(
              scale: 1 + exitT * 0.03,
              child: Stack(children: [
                // 1. Photo
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  height: plinthTop + 40,
                  child: Opacity(
                    opacity: _photo.value,
                    child: ClipRect(
                      child: Transform.scale(
                        scale: 1.14 - 0.14 * _push.value,
                        alignment: const Alignment(0.2, 0.3),
                        child: Image.asset('assets/images/building.png',
                            fit: BoxFit.cover, alignment: const Alignment(0.15, 0.4)),
                      ),
                    ),
                  ),
                ),
                // flat tint for legibility of the status bar, no gradient
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  height: plinthTop + 40,
                  child: ColoredBox(color: AppColors.navy.withValues(alpha: 0.18)),
                ),

                // 2. Plinth
                Positioned(
                  left: 0,
                  right: 0,
                  top: plinthTop + (size.height - plinthTop) * (1 - _plinth.value),
                  bottom: 0,
                  child: const ColoredBox(color: AppColors.navy),
                ),
                // hairline on the plinth edge, draws left to right
                Positioned(
                  left: 0,
                  top: plinthTop + (size.height - plinthTop) * (1 - _plinth.value),
                  width: size.width * _ring.value,
                  height: 2,
                  child: const ColoredBox(color: Color(0xFF3D7BC4)),
                ),

                // 3. Crest + ring
                Positioned(
                  top: plinthTop - crest / 2 - 14,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: SizedBox(
                      width: crest + 28,
                      height: crest + 28,
                      child: CustomPaint(
                        painter: _LoopPainter(_ring.value),
                        child: Center(
                          child: Opacity(
                            opacity: _crest.value.clamp(0.0, 1.0),
                            child: Transform.scale(
                              scale: 0.6 + 0.4 * _crest.value,
                              child: Container(
                                width: crest,
                                height: crest,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.25),
                                      blurRadius: 24,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Image.asset('assets/logos/air_university.jpeg',
                                    fit: BoxFit.contain),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // 4. Wordmark + tagline
                Positioned(
                  top: plinthTop + crest / 2 + 34,
                  left: 24,
                  right: 24,
                  child: Column(children: [
                    _Wordmark(progress: _c.value),
                    const SizedBox(height: 10),
                    Opacity(
                      opacity: _tag.value,
                      child: Transform.translate(
                        offset: Offset(0, 8 * (1 - _tag.value)),
                        child: Text(
                          'Attendance and societies, accounted for.',
                          textAlign: TextAlign.center,
                          style: AppText.body.copyWith(
                              color: Colors.white.withValues(alpha: 0.72), fontSize: 14.5),
                        ),
                      ),
                    ),
                  ]),
                ),

                // 5. Footer + progress
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: MediaQuery.paddingOf(context).bottom + 36,
                  child: Column(children: [
                    Container(
                      width: 128,
                      height: 2,
                      color: Colors.white.withValues(alpha: 0.12),
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: _bar.value,
                        child: Container(color: Colors.white.withValues(alpha: 0.85)),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Opacity(
                      opacity: _foot.value,
                      child: Text(
                        'AIR UNIVERSITY  ·  ISLAMABAD',
                        style: AppText.label.copyWith(
                            color: Colors.white.withValues(alpha: 0.55),
                            letterSpacing: 2.4,
                            fontSize: 10.5),
                      ),
                    ),
                  ]),
                ),
              ]),
            ),
          );
        },
      ),
    );
  }
}

class _Wordmark extends StatelessWidget {
  final double progress;
  const _Wordmark({required this.progress});

  @override
  Widget build(BuildContext context) {
    const word = 'LoopAir';
    const start = 0.44, step = 0.035, span = 0.12;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(word.length, (i) {
        final t = ((progress - (start + i * step)) / span).clamp(0.0, 1.0);
        final e = Curves.easeOutCubic.transform(t);
        final isAir = i >= 4;
        return Opacity(
          opacity: e,
          child: Transform.translate(
            offset: Offset(0, 18 * (1 - e)),
            child: Text(
              word[i],
              style: AppText.display.copyWith(
                fontSize: 40,
                letterSpacing: -1.2,
                fontWeight: isAir ? FontWeight.w300 : FontWeight.w600,
                color: isAir ? const Color(0xFF9CC3EE) : Colors.white,
              ),
            ),
          ),
        );
      }),
    );
  }
}

/// Draws the "loop": an arc that sweeps a full circle around the crest,
/// with a small leading node, then settles as a closed ring.
class _LoopPainter extends CustomPainter {
  final double t;
  _LoopPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0) return;
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 2;
    final rect = Rect.fromCircle(center: c, radius: r);
    final track = Paint()
      ..color = Colors.white.withValues(alpha: 0.10 * t)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(c, r, track);

    final sweep = 2 * math.pi * t;
    final arc = Paint()
      ..color = const Color(0xFF9CC3EE)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2;
    canvas.drawArc(rect, -math.pi / 2, sweep, false, arc);

    if (t < 1) {
      final a = -math.pi / 2 + sweep;
      final p = Offset(c.dx + r * math.cos(a), c.dy + r * math.sin(a));
      canvas.drawCircle(p, 3.5, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(_LoopPainter old) => old.t != t;
}
