import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/error/result.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/navigation_helper.dart';
import '../../models/user_model.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/user_repository.dart';
import '../../l10n/tr_extension.dart';
import '../widgets/animations.dart';
import 'widgets/auth_text_field.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.lightImpact();

    setState(() => _isLoading = true);

    final authRepo = AuthRepository();
    final result = await authRepo.loginWithEmail(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result is Success<UserModel>) {
      NavigationHelper.navigateByRole(context, result.data.role);
    } else {
      _showError((result as Failure).message);
    }
  }

  StreamSubscription<AuthState>? _googleAuthSub;

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      final redirectUrl = kIsWeb
          ? Uri.base.toString()
          : 'io.supabase.busbooking://login-callback/';
      final launched = await AuthRepository().client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectUrl,
      );

      if (!launched || !mounted) {
        _showError(context.tr.googleSignInFailed);
        return;
      }

      if (!mounted) return;

      _googleAuthSub?.cancel();
      _googleAuthSub = AuthRepository().client.auth.onAuthStateChange.listen((
        data,
      ) async {
        if (!mounted) return;
        final session = data.session;
        if (session == null) return;

        await _googleAuthSub?.cancel();
        _googleAuthSub = null;

        final user = session.user;
        final metadata = user.userMetadata ?? {};

        final existing = await UserRepository().client
            .from('users')
            .select('id, role, status')
            .eq('id', user.id)
            .maybeSingle();

        if (existing == null) {
          await UserRepository().client.from('users').insert({
            'id': user.id,
            'email': user.email,
            'name':
                metadata['full_name'] ??
                metadata['name'] ??
                user.email?.split('@').first ??
                'User',
            'phone': metadata['phone'] ?? '',
            'role': 'passenger',
            'status': 'active',
          });
          if (!mounted) return;
          NavigationHelper.navigateByRole(context, 'passenger');
          return;
        }

        if (!mounted) return;
        final status = existing['status'] as String? ?? 'active';
        if (status == 'suspended' || status == 'inactive') {
          await AuthRepository().client.auth.signOut();
          _showError(context.tr.accountSuspended(status));
          return;
        }

        final role = existing['role'] as String? ?? 'passenger';
        NavigationHelper.navigateByRole(context, role);
      });
    } catch (e) {
      _showError(context.tr.googleSignInError);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/khmerbg.jpg', fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: Container(color: Colors.white.withValues(alpha: 0.85)),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 20),
                      SlideFadeIn(
                        duration: const Duration(milliseconds: 500),
                        offset: 20,
                        child: Center(
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 12),
                            padding: const EdgeInsets.all(8),
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 255, 255, 255),
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.12),
                                  blurRadius: 15,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Image.asset(
                              'assets/images/bus.png',
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      SlideFadeIn(
                        duration: const Duration(milliseconds: 500),
                        offset: 20,
                        child: Column(
                          children: [
                            Text(
                              context.tr.welcomeBack,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: AppColors.darkSlate,
                                letterSpacing: -0.8,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              context.tr.signInSubtitle,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 15,
                                color: AppColors.textSoft,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      SlideFadeIn(
                        duration: const Duration(milliseconds: 600),
                        offset: 30,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: AppColors.warmGrey),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AuthTextField(
                                label: context.tr.emailLabel,
                                hint: context.tr.emailHint,
                                icon: Icons.email_outlined,
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return context.tr.emailRequired;
                                  }
                                  if (!v.contains('@')) {
                                    return context.tr.enterValidEmail;
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),
                              AuthTextField(
                                label: context.tr.passwordLabel,
                                hint: context.tr.passwordHint,
                                icon: Icons.lock_outline,
                                controller: _passwordController,
                                isPassword: true,
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return context.tr.passwordRequired;
                                  }
                                  if (v.length < 8) {
                                    return context.tr.passwordMinLength8;
                                  }
                                  if (!v.contains(RegExp(r'[A-Z]'))) {
                                    return context.tr.includeUppercase;
                                  }
                                  if (!v.contains(RegExp(r'[0-9]'))) {
                                    return context.tr.includeNumber;
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const ForgotPasswordScreen(),
                                    ),
                                  ),
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(50, 30),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    context.tr.forgotPasswordLink,
                                    style: const TextStyle(
                                      color: AppColors.primaryBlue,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _login,
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(
                                          context.tr.signInButton,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SlideFadeIn(
                        duration: const Duration(milliseconds: 650),
                        offset: 20,
                        child: Row(
                          children: [
                            const Expanded(
                              child: Divider(color: AppColors.warmGrey),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Text(
                                context.tr.orDivider,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textMuted.withValues(
                                    alpha: 0.8,
                                  ),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const Expanded(
                              child: Divider(color: AppColors.warmGrey),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      SlideFadeIn(
                        duration: const Duration(milliseconds: 700),
                        offset: 20,
                        child: SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton.icon(
                            onPressed: _isLoading ? null : _signInWithGoogle,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textPrimary,
                              side: const BorderSide(color: Color(0xFFD1D5DB)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Image.asset(
                                    'assets/images/google_logo.jpg',
                                    height: 20,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.g_mobiledata_rounded,
                                      size: 28,
                                      color: Color(0xFF4285F4),
                                    ),
                                  ),
                            label: Text(
                              context.tr.continueWithGoogle,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              context.tr.dontHaveAccount,
                              style: const TextStyle(
                                color: AppColors.textSoft,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SignupScreen(),
                                ),
                              ),
                              child: Text(
                                context.tr.signUpLink,
                                style: const TextStyle(
                                  color: AppColors.primaryBlue,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
