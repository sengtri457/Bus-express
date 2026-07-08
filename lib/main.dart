import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/reset_password_screen.dart';
import 'features/screens/splash_screen.dart';
import 'l10n/app_localizations.dart';
import 'providers/locale_provider.dart';
import 'services/notification_service.dart';
import 'supabase_config.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  // Capture initial deep link (cold start) before Supabase initializes
  final initialUri = kIsWeb ? null : await AppLinks().getLatestLink();

  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.implicit,
    ),
  );

  // Process the initial deep link manually (supabase_flutter skips on mobile)
  if (initialUri != null &&
      initialUri.fragment.contains('access_token') &&
      initialUri.fragment.contains('type=recovery')) {
    try {
      await Supabase.instance.client.auth.getSessionFromUrl(initialUri);
    } catch (_) {
      // silently fail — auth state listener handles the result
    }
  }

  await NotificationService.instance.init();
  // runApp(
  //   DevicePreview(
  //     enabled: true,
  //     tools: [...DevicePreview.defaultTools],
  //     builder: (context) => const ProviderScope(child: MyApp()),
  //   ),
  // );
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  late final StreamSubscription<AuthState> _authSubscription;

  @override
  void initState() {
    super.initState();
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((
      data,
    ) {
      if (data.event == AuthChangeEvent.passwordRecovery) {
        ResetPasswordScreen.isRecoveringPassword = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (context) => const ResetPasswordScreen(),
            ),
          );
        });
      }
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    return MaterialApp(
      navigatorKey: navigatorKey,
      // ignore: deprecated_member_use
      useInheritedMediaQuery: true,
      builder: DevicePreview.appBuilder,
      locale: locale,
      title: 'Bus Express',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const SplashScreen(),
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => const SplashScreen(),
          settings: settings,
        );
      },
    );
  }
}
