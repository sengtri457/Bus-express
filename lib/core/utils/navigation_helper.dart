import 'package:flutter/material.dart';

import '../../features/screens/passengers/passenger_main_screen.dart';
import '../../features/screens/drivers/driver_home_screen.dart';
import '../../features/screens/conductors/conductor_home_screen.dart';
import '../../features/screens/operators/operator_home_screen.dart';
import '../../features/screens/superAdmin/super_admin_home_screen.dart';
import '../../features/screens/splash_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NavigationHelper {
  NavigationHelper._();

  static void navigateByRole(BuildContext context, String? role) {
    Widget screen;
    switch (role) {
      case 'passenger':
        screen = const PassengerMainScreen();
      case 'driver':
        screen = const DriverHomeScreen();
      case 'conductor':
        screen = const ConductorHomeScreen();
      case 'operator_admin':
        screen = const OperatorHomeScreen();
      case 'super_admin':
        screen = const SuperAdminHomeScreen();
      default:
        screen = const SplashScreen();
    }
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => screen),
      (route) => false,
    );
  }

  static Future<void> navigateByRoleAsync(
    BuildContext context,
    String? role,
  ) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      navigateByRole(context, role);
      return;
    }
    final data = await Supabase.instance.client
        .from('users')
        .select('role, status')
        .eq('id', user.id)
        .single();
    final status = data['status'] as String?;
    if (status == 'suspended') {
      if (context.mounted) {
        await Supabase.instance.client.auth.signOut();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const SplashScreen()),
          (route) => false,
        );
      }
      return;
    }
    final resolvedRole = data['role'] as String? ?? role;
    navigateByRole(context, resolvedRole);
  }
}
