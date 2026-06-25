import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/providers/shared/auth_provider.dart';
import 'package:sero/widgets/shared/brand_logo.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _isAnimationComplete = false;

  @override
  void initState() {
    super.initState();
    _handleSplashTiming();
  }

  Future<void> _handleSplashTiming() async {
    // Elegant delay for brand presence
    await Future.delayed(const Duration(milliseconds: 3000));
    if (!mounted) return;

    _isAnimationComplete = true;
    _navigateToNextScreen();
  }

  void _navigateToNextScreen() {
    if (!_isAnimationComplete) return;

    final userAsync = ref.read(authProvider);
    if (userAsync is AsyncData) {
      final user = userAsync.value;
      if (user != null) {
        // We always go to /home; AuthGuard there will now handle
        // status checks (pending) and role checks.
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } else if (userAsync is AsyncError) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authProvider, (previous, next) {
      if (next is AsyncData || next is AsyncError) {
        _navigateToNextScreen();
      }
    });

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: kPrimaryGreen, // Deep matte green for luxury look
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SocietyLogo(size: 80)
                  .animate()
                  .fade(duration: 1200.ms, curve: Curves.easeInCirc)
                  .scale(
                    begin: const Offset(0.9, 0.9),
                    end: const Offset(1.0, 1.0),
                    duration: 1500.ms,
                    curve: Curves.easeOutQuart,
                  ),

              const SizedBox(height: 48),

              Text(
                'SERO',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w300, // Thinner for elegance
                  letterSpacing: 10, // Extreme tracking for luxury vibe
                ),
              ).animate().fade(delay: 500.ms, duration: 1000.ms),

              const SizedBox(height: 4),

              Text(
                'Connects the Society',
                style: GoogleFonts.outfit(
                  color: Colors.white60,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 8,
                ),
              ).animate().fade(delay: 800.ms, duration: 1000.ms),

              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingDots extends StatefulWidget {
  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final opacity = ((_controller.value * 3 - index) % 3) / 3;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: opacity.clamp(0.2, 1.0)),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}











