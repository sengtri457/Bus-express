import 'package:flutter/material.dart';
import '../../supabase_config.dart';
import '../auth/login_screen.dart';

// ─── Home screens (create these later per role) ───────────────────────────────
// import '../../passenger/screens/passenger_home_screen.dart';
// import '../../driver/screens/driver_home_screen.dart';
// import '../../conductor/screens/conductor_home_screen.dart';
// import '../../operator/screens/operator_home_screen.dart';
// import '../../admin/screens/admin_home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnim = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeIn));

    _scaleAnim = Tween<double>(begin: 0.8, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.elasticOut),
    );

    _animController.forward();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final session = SupabaseConfig.client.auth.currentSession;

    if (session == null) {
      // Not logged in → go to Login
      _navigateTo(const LoginScreen());
      return;
    }

    // Logged in → fetch role and route accordingly
    try {
      final userData = await SupabaseConfig.client
          .from('users')
          .select('role')
          .eq('id', session.user.id)
          .single();

      final role = userData['role'] as String;
      _navigateByRole(role);
    } catch (_) {
      _navigateTo(const LoginScreen());
    }
  }

  void _navigateByRole(String role) {
    // Replace with your actual home screens when ready
    switch (role) {
      case 'passenger':
      // _navigateTo(const PassengerHomeScreen());
      case 'driver':
      // _navigateTo(const DriverHomeScreen());
      case 'conductor':
      // _navigateTo(const ConductorHomeScreen());
      case 'operator_admin':
      // _navigateTo(const OperatorHomeScreen());
      case 'super_admin':
      // _navigateTo(const AdminHomeScreen());
      default:
        _navigateTo(const LoginScreen());
    }
    // Temporary: go to login until home screens are built
    _navigateTo(const LoginScreen());
  }

  void _navigateTo(Widget screen) {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A73E8), Color(0xFF0D47A1)],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: ScaleTransition(
              scale: _scaleAnim,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: const Icon(
                      Icons.directions_bus_rounded,
                      size: 56,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Bus Booking',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your journey starts here',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 60),
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
