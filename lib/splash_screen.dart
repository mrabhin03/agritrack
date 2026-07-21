// splash_screen.dart
import 'package:flutter/material.dart';
import 'app.dart';
import 'services/hive_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await Future.wait([
      HiveService.init(),
      Future.delayed(const Duration(seconds: 5)),
    ]);

    if (!mounted) return;
    setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    // Crossfade instead of a hard cut. Building AgriTrackApp (a whole new
    // MaterialApp + router + provider tree) is heavy, so swapping it in
    // instantly causes dropped frames right as the dashboard's entrance
    // animation starts — which makes that animation look broken rather
    // than smooth. A short crossfade gives the engine a moment to lay
    // everything out before it's fully visible.
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      child: _ready
          ? const AgriTrackApp(key: ValueKey('app'))
          : const _SplashView(key: ValueKey('splash')),
    );
  }
}

class _SplashView extends StatefulWidget {
  const _SplashView({super.key});

  @override
  State<_SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<_SplashView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF1D5039),
        body: SafeArea(
          child: Column(
            children: [
              // Centered logo + text block takes up the remaining space
              Expanded(
                child: Center(
                  child: FadeTransition(
                    opacity: _fade,
                    child: ScaleTransition(
                      scale: _scale,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/images/Splash.png',
                            width: 140,
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'AgriTrack',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Grow smarter, every day',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Loading indicator pinned near the bottom, not floating alone
              Padding(
                padding: const EdgeInsets.only(bottom: 48),
                child: Column(
                  children: [
                    const SizedBox(
                      width: 160,
                      child: _GradientLoadingBar(),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Loading your farm data...',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Gradient loading bar ───────────────────────────────
class _GradientLoadingBar extends StatelessWidget {
  const _GradientLoadingBar();

  static const _gradient = LinearGradient(
    colors: [Color(0xFF6FCF97), Color(0xFFA8E6C1)],
  );

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        height: 5,
        child: ShaderMask(
          shaderCallback: (rect) => _gradient.createShader(rect),
          blendMode: BlendMode.srcIn,
          child: LinearProgressIndicator(
            backgroundColor: Colors.white.withOpacity(0.15),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      ),
    );
  }
}