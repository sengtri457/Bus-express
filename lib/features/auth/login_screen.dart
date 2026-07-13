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
import '../../providers/guest_provider.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/user_repository.dart';
import '../../l10n/tr_extension.dart';
import '../screens/passengers/passenger_main_screen.dart';
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
  StreamSubscription<AuthState>? _googleAuthSub;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _googleAuthSub?.cancel();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.lightImpact();

    setState(() => _isLoading = true);

    final result = await AuthRepository().loginWithEmail(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result is Success<UserModel>) {
      final role = result.data.role ?? 'passenger';
      if (role == 'passenger') {
        _showSuccessDialog(role);
      } else {
        NavigationHelper.navigateByRole(context, role);
      }
    } else {
      _showError((result as Failure).message);
    }
  }

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

      _googleAuthSub?.cancel();
      _googleAuthSub = AuthRepository().client.auth.onAuthStateChange.listen(
        _onGoogleAuthChange,
      );
    } catch (_) {
      _showError(context.tr.googleSignInError);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onGoogleAuthChange(AuthState data) async {
    final session = data.session;
    if (session == null || !mounted) return;

    await _googleAuthSub?.cancel();
    _googleAuthSub = null;

    final user = session.user;
    final existing = await UserRepository().client
        .from('users')
        .select('id, role, status')
        .eq('id', user.id)
        .maybeSingle();

    if (!mounted) return;

    if (existing == null) {
      await _createGoogleUser(user);
      return;
    }

    final status = existing['status'] as String? ?? 'active';
    if (status == 'suspended' || status == 'inactive') {
      await AuthRepository().client.auth.signOut();
      _showError(context.tr.accountSuspended(status));
      return;
    }

    final role = existing['role'] as String? ?? 'passenger';
    if (role == 'passenger') {
      _showSuccessDialog(role);
    } else {
      NavigationHelper.navigateByRole(context, role);
    }
  }

  Future<void> _createGoogleUser(User user) async {
    final metadata = user.userMetadata ?? {};
    await UserRepository().client.from('users').insert({
      'id': user.id,
      'email': user.email,
      'name': metadata['full_name'] ??
          metadata['name'] ??
          user.email?.split('@').first ??
          'User',
      'phone': metadata['phone'] ?? '',
      'role': 'passenger',
      'status': 'active',
    });

    if (mounted) _showSuccessDialog('passenger');
  }

  void _showSuccessDialog(String role) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _LoginSuccessDialog(role: role),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String? _emailValidator(String? v) {
    if (v == null || v.isEmpty) return context.tr.emailRequired;
    if (!v.contains('@')) return context.tr.enterValidEmail;
    return null;
  }

  String? _passwordValidator(String? v) {
    if (v == null || v.isEmpty) return context.tr.passwordRequired;
    if (v.length < 8) return context.tr.passwordMinLength8;
    return null;
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
            child: Column(
              children: [
                _buildSkipButton(),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildHeader(),
                            const SizedBox(height: 32),
                            SlideFadeIn(
                              duration: const Duration(milliseconds: 600),
                              offset: 30,
                              child: _buildFormCard(),
                            ),
                            _buildDivider(),
                            const SizedBox(height: 24),
                            _buildGoogleButton(),
                            const SizedBox(height: 28),
                            _buildSignupRow(),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
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
                color: Colors.white,
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
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard() {
    return Container(
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
            validator: _emailValidator,
          ),
          const SizedBox(height: 20),
          AuthTextField(
            label: context.tr.passwordLabel,
            hint: context.tr.passwordHint,
            icon: Icons.lock_outline,
            controller: _passwordController,
            isPassword: true,
            validator: _passwordValidator,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ForgotPasswordScreen(),
                ),
              ),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(50, 30),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
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
    );
  }

  Widget _buildDivider() {
    return SlideFadeIn(
      duration: const Duration(milliseconds: 650),
      offset: 20,
      child: Row(
        children: [
          const Expanded(child: Divider(color: AppColors.warmGrey)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              context.tr.orDivider,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textMuted.withValues(alpha: 0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Expanded(child: Divider(color: AppColors.warmGrey)),
        ],
      ),
    );
  }

  Widget _buildGoogleButton() {
    return SlideFadeIn(
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
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Image.asset(
                  'assets/images/google_logo.jpg',
                  height: 20,
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.g_mobiledata_rounded,
                    size: 28,
                    color: Color(0xFF4285F4),
                  ),
                ),
          label: Text(
            context.tr.continueWithGoogle,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  Widget _buildSignupRow() {
    return Center(
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
              MaterialPageRoute(builder: (_) => const SignupScreen()),
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
    );
  }

  Widget _buildSkipButton() {
    return Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: const EdgeInsets.only(right: 8, top: 4),
        child: TextButton(
          onPressed: _skipLogin,
          child: Text(
            'Skip',
            style: TextStyle(
              color: AppColors.textMuted.withValues(alpha: 0.7),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  void _skipLogin() {
    ref.read(guestProvider.notifier).setSkippedLogin();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const PassengerMainScreen()),
        (route) => false,
      );
    });
  }
}

class _LoginSuccessDialog extends StatelessWidget {
  final String role;

  const _LoginSuccessDialog({required this.role});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).pop();
                  NavigationHelper.navigateByRole(context, role);
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceGrey,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/images/popup.webp',
                width: double.infinity,
                height: 200,
                fit: BoxFit.fill,
                errorBuilder: (_, _, _) => Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSoft,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.warmGrey, width: 2),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image_outlined,
                        size: 48,
                        color: AppColors.textMuted.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Welcome Info Image',
                        style: TextStyle(
                          color: AppColors.textMuted.withValues(alpha: 0.7),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Welcome to Bus Express!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.darkSlate,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Thank you for signing in. You can now book tickets, track your trips, and enjoy a seamless travel experience.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary.withValues(alpha: 0.9),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  NavigationHelper.navigateByRole(context, role);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Get Started',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
