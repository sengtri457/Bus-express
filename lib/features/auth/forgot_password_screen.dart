import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../supabase_config.dart';
import 'widgets/auth_text_field.dart';
import 'login_screen.dart';
import '../../l10n/tr_extension.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _emailSent = false;
  bool _canResend = true;
  int _resendCountdown = 0;

  // Step: 0 = enter email, 1 = reset password (after clicking email link)
  // Note: Supabase handles the OTP via deep link. Here we show the
  // reset password form for users who return from the email link.
  final int _step = 0;

  @override
  void dispose() {
    _emailController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showError(context.tr.enterValidEmailAddress);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await SupabaseConfig.client.auth.resetPasswordForEmail(
        email,
        redirectTo: 'io.supabase.busbooking://reset-callback/',
        // Change this to your app's deep link scheme
      );

      if (!mounted) return;
      setState(() {
        _emailSent = true;
        _isLoading = false;
      });

      _startResendCountdown();
    } on AuthException catch (e) {
      _showError(e.message);
    } catch (_) {
      _showError(context.tr.somethingWentWrong);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updatePassword() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showError(context.tr.passwordsDoNotMatchValidator);
      return;
    }
    if (_newPasswordController.text.length < 8) {
      _showError(context.tr.passwordMinLength8);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await SupabaseConfig.client.auth.updateUser(
        UserAttributes(password: _newPasswordController.text.trim()),
      );

      if (!mounted) return;
      _showSuccessDialog();
    } on AuthException catch (e) {
      _showError(e.message);
    } catch (_) {
      _showError(context.tr.somethingWentWrong);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _startResendCountdown() {
    setState(() {
      _canResend = false;
      _resendCountdown = 60;
    });

    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _resendCountdown--);
      if (_resendCountdown <= 0) {
        setState(() => _canResend = true);
        return false;
      }
      return true;
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF10B981),
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                context.tr.passwordResetTitle,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                context.tr.passwordResetBody,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    context.tr.backToLogin,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.only(left: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_rounded,
              color: Color(0xFF0F172A),
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/khmerbg.jpg', fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: Container(color: Colors.white.withValues(alpha: 0.85)),
          ),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: _step == 0 ? _buildEmailStep() : _buildResetStep(),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Step 0: Enter Email ────────────────────────────────────────────────────

  Widget _buildEmailStep() {
    if (_emailSent) return _buildEmailSentView();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 10),

        // Icon
        Center(
          child: Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFDBEAFE), width: 1.5),
            ),
            child: const Icon(
              Icons.lock_reset_rounded,
              size: 38,
              color: Color(0xFF2563EB),
            ),
          ),
        ),
        const SizedBox(height: 28),

        Text(
          context.tr.forgotPasswordTitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          context.tr.forgotPasswordSubtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 15,
            color: Color(0xFF64748B),
            height: 1.5,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 32),

        // Beautiful Form Card
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
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
                label: context.tr.emailAddressLabel,
                hint: context.tr.emailAddressHint,
                icon: Icons.email_outlined,
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _sendResetEmail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFF93C5FD),
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
                          context.tr.sendResetLink,
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
        const SizedBox(height: 32),

        Center(
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.arrow_back_rounded,
                  size: 16,
                  color: Color(0xFF64748B),
                ),
                const SizedBox(width: 6),
                Text(
                  context.tr.backToLoginLink,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // ─── Email Sent View ────────────────────────────────────────────────────────

  Widget _buildEmailSentView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),

        // Animated envelope icon
        Center(
          child: Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(45),
              border: Border.all(color: const Color(0xFFDBEAFE), width: 1.5),
            ),
            child: const Icon(
              Icons.mark_email_read_rounded,
              size: 44,
              color: Color(0xFF2563EB),
            ),
          ),
        ),
        const SizedBox(height: 28),

        Text(
          context.tr.checkYourEmail,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 12),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
              height: 1.6,
              fontFamily: 'Inter',
            ),
            children: [
              TextSpan(text: context.tr.resetLinkSent(_emailController.text.trim())),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Steps info inside Card
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoStep(number: '1', text: context.tr.infoStep1),
              const SizedBox(height: 16),
              _InfoStep(number: '2', text: context.tr.infoStep2),
              const SizedBox(height: 16),
              _InfoStep(number: '3', text: context.tr.infoStep3),
            ],
          ),
        ),

        const SizedBox(height: 36),

        // Resend
        Center(
          child: Text(
            context.tr.didNotReceiveEmail,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton(
            onPressed: _canResend ? _sendResetEmail : null,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF2563EB),
              disabledForegroundColor: const Color(0xFF94A3B8),
              side: BorderSide(
                color: _canResend
                    ? const Color(0xFF2563EB)
                    : const Color(0xFFE2E8F0),
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              _canResend ? context.tr.resendEmail : context.tr.resendInCountdown(_resendCountdown),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 24),

        Center(
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.arrow_back_rounded,
                  size: 16,
                  color: Color(0xFF64748B),
                ),
                const SizedBox(width: 6),
                Text(
                  context.tr.backToLoginLink,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // ─── Step 1: Reset Password Form ────────────────────────────────────────────

  Widget _buildResetStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 10),

        Center(
          child: Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFDBEAFE), width: 1.5),
            ),
            child: const Icon(
              Icons.key_rounded,
              size: 38,
              color: Color(0xFF2563EB),
            ),
          ),
        ),
        const SizedBox(height: 28),

        Text(
          context.tr.setNewPassword,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          context.tr.setNewPasswordSubtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 15,
            color: Color(0xFF64748B),
            height: 1.5,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 32),

        // Beautiful Form Card
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
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
                label: context.tr.newPasswordLabel,
                hint: context.tr.newPasswordHint,
                icon: Icons.lock_outline_rounded,
                controller: _newPasswordController,
                isPassword: true,
                validator: (v) {
                  if (v == null || v.isEmpty) return context.tr.passwordRequired;
                  if (v.length < 8) return context.tr.passwordMinLength8;
                  return null;
                },
              ),
              const SizedBox(height: 20),

              AuthTextField(
                label: context.tr.confirmNewPasswordLabel,
                hint: context.tr.confirmNewPasswordHint,
                icon: Icons.lock_outline_rounded,
                controller: _confirmPasswordController,
                isPassword: true,
                validator: (v) {
                  if (v != _newPasswordController.text) {
                    return context.tr.passwordsDoNotMatchValidator;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updatePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFF93C5FD),
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
                          context.tr.resetPasswordButton,
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
        const SizedBox(height: 20),
      ],
    );
  }
}

// ─── Info Step Widget ─────────────────────────────────────────────────────────

class _InfoStep extends StatelessWidget {
  final String number;
  final String text;
  const _InfoStep({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFDBEAFE)),
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Color(0xFF2563EB),
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF334155),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
