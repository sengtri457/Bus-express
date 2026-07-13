import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final guestProvider = StateNotifierProvider<GuestNotifier, GuestState>((ref) {
  return GuestNotifier();
});

class GuestState {
  final bool onboardingCompleted;
  final bool hasSkippedLogin;

  const GuestState({
    this.onboardingCompleted = false,
    this.hasSkippedLogin = false,
  });
}

class GuestNotifier extends StateNotifier<GuestState> {
  GuestNotifier() : super(const GuestState()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = GuestState(
      onboardingCompleted: prefs.getBool('onboarding_completed') ?? false,
      hasSkippedLogin: prefs.getBool('has_skipped_login') ?? false,
    );
  }

  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    state = GuestState(onboardingCompleted: true, hasSkippedLogin: state.hasSkippedLogin);
  }

  Future<void> setSkippedLogin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_skipped_login', true);
    state = const GuestState(onboardingCompleted: true, hasSkippedLogin: true);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('onboarding_completed');
    await prefs.remove('has_skipped_login');
    state = const GuestState();
  }
}
