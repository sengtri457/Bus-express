import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/tr_extension.dart';
import '../../core/utils/navigation_helper.dart';
import '../../models/user_model.dart';
import '../../core/error/result.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/user_repository.dart';
import '../auth/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _ringCtrl;
  late AnimationController _logoCtrl;
  late Animation<double> _ringAnim;

  @override
  void initState() {
    super.initState();

    // Pulsing ring behind logo
    _ringCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _ringAnim = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _ringCtrl, curve: Curves.easeInOutSine),
    );

    // Logo entrance
    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    await Future.delayed(const Duration(milliseconds: 2600));
    if (!mounted) return;

    final authRepo = AuthRepository();
    final supabaseUser = AuthRepository().client.auth.currentUser;

    if (supabaseUser == null) {
      _navigateTo(const LoginScreen());
      return;
    }

    try {
      final userRepo = UserRepository();
      final result = await userRepo.getCurrentUser(supabaseUser.id);

      if (!mounted) return;

      if (result is Success<UserModel>) {
        final user = result.data;
        if (user.isSuspended) {
          await authRepo.signOut();
          if (mounted) _navigateTo(const LoginScreen());
          return;
        }
        NavigationHelper.navigateByRole(context, user.role);
      } else {
        _navigateTo(const LoginScreen());
      }
    } catch (_) {
      if (mounted) _navigateTo(const LoginScreen());
    }
  }

  void _navigateTo(Widget screen) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (ctx, a1, a2) => screen,
        transitionDuration: const Duration(milliseconds: 500),
        transitionsBuilder: (ctx, animation, a2, child) => FadeTransition(
          opacity: animation,
          child: child,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _ringCtrl.dispose();
    _logoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.darkBlue),
        child: Stack(
          children: [
            // ── Decorative background circles ──────────────────
            const Positioned(
              top: -80,
              right: -60,
              child: _GlowCircle(
                size: 260,
                color: Color(0xFF2563EB),
                opacity: 0.15,
              ),
            ),
            const Positioned(
              bottom: -100,
              left: -80,
              child: _GlowCircle(
                size: 300,
                color: Color(0xFF1E40AF),
                opacity: 0.12,
              ),
            ),

            // ── Main content ───────────────────────────────────
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo with pulsing ring
                  AnimatedBuilder(
                    animation: _ringAnim,
                    builder: (_, child) => Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer glow ring
                        Transform.scale(
                          scale: _ringAnim.value,
                          child: Container(
                            width: 130,
                            height: 130,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.08),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                        // Inner ring
                        Transform.scale(
                          scale: 2.0 - _ringAnim.value,
                          child: Container(
                            width: 115,
                            height: 115,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.05),
                            ),
                          ),
                        ),
                        child!,
                      ],
                    ),
                    child: ScaleTransition(
                      scale: CurvedAnimation(
                        parent: _logoCtrl,
                        curve: Curves.elasticOut,
                      ),
                      child: FadeTransition(
                        opacity: _logoCtrl,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(26),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2563EB)
                                    .withValues(alpha: 0.4),
                                blurRadius: 30,
                                spreadRadius: 2,
                                offset: const Offset(0, 8),
                              ),
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.18),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/images/bus.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // App title — character reveal
                  Text(
                    context.tr.appTitle,
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -1.0,
                    ),
                  )
                      .animate(delay: 300.ms)
                      .fadeIn(duration: 600.ms, curve: Curves.easeOut)
                      .slideY(
                        begin: 0.3,
                        end: 0,
                        duration: 600.ms,
                        curve: Curves.easeOutCubic,
                      ),

                  const SizedBox(height: 8),

                  // Subtitle — staggered word fade
                  Text(
                    'Premium Travel Made Simple',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withValues(alpha: 0.70),
                      letterSpacing: 0.3,
                    ),
                  )
                      .animate(delay: 500.ms)
                      .fadeIn(duration: 700.ms)
                      .slideY(
                        begin: 0.4,
                        end: 0,
                        duration: 700.ms,
                        curve: Curves.easeOutCubic,
                      ),

                  const SizedBox(height: 72),

                  // Wave loading indicator
                  _SplashLoader()
                      .animate(delay: 700.ms)
                      .fadeIn(duration: 500.ms),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Decorative glow circle ────────────────────────────────────

class _GlowCircle extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;

  const _GlowCircle({
    required this.size,
    required this.color,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: opacity),
            color.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }
}

// ── Custom splash wave loader ─────────────────────────────────

class _SplashLoader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              shape: BoxShape.circle,
            ),
          )
              .animate(
                onPlay: (c) => c.repeat(),
                delay: Duration(milliseconds: i * 180),
              )
              .moveY(
                begin: 0,
                end: -10,
                duration: 420.ms,
                curve: Curves.easeInOut,
              )
              .then()
              .moveY(
                begin: -10,
                end: 0,
                duration: 420.ms,
                curve: Curves.easeInOut,
              ),
        );
      }),
    );
  }
}

