import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../supabase_config.dart';
import '../widgets/animations.dart';
import 'widgets/auth_text_field.dart';
import 'login_screen.dart';
import '../../l10n/tr_extension.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _agreedToTerms = false;
  int _currentStep = 0; // 0 = personal info, 1 = credentials

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreedToTerms) {
      _showError(context.tr.agreeTermsError);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Pass name and phone as metadata → trigger picks it up
      final response = await SupabaseConfig.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        data: {
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
        },
      );

      if (!mounted) return;

      if (response.user == null) {
        _showError(context.tr.registrationFailed);
        return;
      }

      // Trigger already inserted into users table automatically ✅
      _showSuccess();
    } on AuthException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccess() {
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
                context.tr.accountCreatedTitle,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2563EB),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                context.tr.verificationSent(_emailController.text.trim()),
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
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
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
                    context.tr.goToLogin,
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

  void _nextStep() {
    if (_currentStep == 0) {
      // Validate step 1 fields
      if (_nameController.text.trim().isEmpty) {
        _showError(context.tr.fullNameRequired);
        return;
      }
      if (_phoneController.text.trim().isEmpty) {
        _showError(context.tr.phoneRequired);
        return;
      }
      setState(() => _currentStep = 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: Color(0xFF2563EB),
            size: 20,
          ),
          onPressed: () {
            if (_currentStep == 1) {
              setState(() => _currentStep = 0);
            } else {
              Navigator.pop(context);
            }
          },
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
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),

                    // Header Icon
                    SlideFadeIn(
                      duration: const Duration(milliseconds: 500),
                      offset: 20,
                      child: Center(
                        child: Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            gradient: AppGradients.primaryBlue,
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2563EB).withOpacity(0.2),
                                blurRadius: 15,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.directions_bus_rounded,
                            size: 42,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Title
                    SlideFadeIn(
                      duration: const Duration(milliseconds: 500),
                      offset: 20,
                      child: Column(
                        children: [
                          Text(
                            context.tr.createAccountTitle,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.8,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            context.tr.signupSubtitle,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Step indicator
                    _StepIndicator(currentStep: _currentStep),
                    const SizedBox(height: 32),

                    // Elegant Form Card
                    SlideFadeIn(
                      duration: const Duration(milliseconds: 600),
                      offset: 30,
                      child: Container(
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
                            // Step 1: Personal Info
                            if (_currentStep == 0) ...[
                              AuthTextField(
                                label: context.tr.fullNameLabel,
                                hint: context.tr.fullNameHint,
                                icon: Icons.person_outline_rounded,
                                controller: _nameController,
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return context.tr.fullNameRequired;
                                  }
                                  if (v.length < 2) return context.tr.nameTooShort;
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),
                              AuthTextField(
                                label: context.tr.phoneNumberLabel,
                                hint: context.tr.phoneNumberHint,
                                icon: Icons.phone_outlined,
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                validator: (v) {
                                  if (v == null || v.isEmpty)
                                    return context.tr.phoneRequired;
                                  if (v.length < 8)
                                    return context.tr.enterValidPhone;
                                  return null;
                                },
                              ),
                              const SizedBox(height: 28),
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: _nextStep,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2563EB),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        context.tr.continueButton,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 18,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],

                            // Step 2: Credentials
                            if (_currentStep == 1) ...[
                              AuthTextField(
                                label: context.tr.emailAddressLabel,
                                hint: context.tr.emailAddressHint,
                                icon: Icons.email_outlined,
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) {
                                  if (v == null || v.isEmpty)
                                    return context.tr.emailRequired;
                                  if (!RegExp(
                                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                  ).hasMatch(v)) {
                                    return context.tr.enterValidEmail;
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),
                              AuthTextField(
                                label: context.tr.passwordLabel,
                                hint: context.tr.passwordHint,
                                icon: Icons.lock_outline_rounded,
                                controller: _passwordController,
                                isPassword: true,
                                validator: (v) {
                                  if (v == null || v.isEmpty)
                                    return context.tr.passwordRequired;
                                  if (v.length < 8)
                                    return context.tr.passwordMinLength8;
                                  if (!v.contains(RegExp(r'[A-Z]'))) {
                                    return context.tr.includeUppercase;
                                  }
                                  if (!v.contains(RegExp(r'[0-9]'))) {
                                    return context.tr.includeNumber;
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),
                              AuthTextField(
                                label: context.tr.confirmPasswordLabel,
                                hint: context.tr.confirmPasswordHint,
                                icon: Icons.lock_outline_rounded,
                                controller: _confirmPasswordController,
                                isPassword: true,
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return context.tr.pleaseConfirmPassword;
                                  }
                                  if (v != _passwordController.text) {
                                    return context.tr.passwordsDoNotMatch;
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),

                              // Password strength
                              _PasswordStrengthIndicator(
                                password: _passwordController.text,
                              ),
                              const SizedBox(height: 16),

                              // Terms checkbox
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: Checkbox(
                                      value: _agreedToTerms,
                                      onChanged: (v) => setState(
                                        () => _agreedToTerms = v ?? false,
                                      ),
                                      activeColor: const Color(0xFF2563EB),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: RichText(
                                      text: TextSpan(
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF64748B),
                                          height: 1.4,
                                          fontFamily: 'Inter',
                                        ),
                                        children: [
                                          TextSpan(text: context.tr.iAgreeTo),
                                          TextSpan(
                                            text: context.tr.termsAndConditions,
                                            style: const TextStyle(
                                              color: Color(0xFF2563EB),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          TextSpan(text: context.tr.andConjunction),
                                          TextSpan(
                                            text: context.tr.privacyPolicy,
                                            style: const TextStyle(
                                              color: Color(0xFF2563EB),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 28),

                              // Sign up button
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _signup,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2563EB),
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor: const Color(
                                      0xFF93C5FD,
                                    ),
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
                                          context.tr.createAccountButton,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Login link
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            context.tr.alreadyHaveAccount,
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LoginScreen(),
                              ),
                            ),
                            child: Text(
                              context.tr.signInLink,
                              style: const TextStyle(
                                color: Color(0xFF2563EB),
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Step Indicator ──────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  const _StepIndicator({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StepDot(step: 0, currentStep: currentStep, label: context.tr.stepPersonal),
        Expanded(
          child: Container(
            height: 2,
            color: currentStep >= 1
                ? const Color(0xFF2563EB)
                : const Color(0xFFE2E8F0),
          ),
        ),
        _StepDot(step: 1, currentStep: currentStep, label: context.tr.stepAccount),
      ],
    );
  }
}

class _StepDot extends StatelessWidget {
  final int step;
  final int currentStep;
  final String label;
  const _StepDot({
    required this.step,
    required this.currentStep,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = currentStep >= step;
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(50),
          ),
          child: Center(
            child: isActive && currentStep > step
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : Text(
                    '${step + 1}',
                    style: TextStyle(
                      color: isActive ? Colors.white : const Color(0xFF94A3B8),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isActive ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

// ─── Password Strength ───────────────────────────────────────────────────────

class _PasswordStrengthIndicator extends StatelessWidget {
  final String password;
  const _PasswordStrengthIndicator({required this.password});

  int get _strength {
    int score = 0;
    if (password.length >= 8) score++;
    if (password.contains(RegExp(r'[A-Z]'))) score++;
    if (password.contains(RegExp(r'[0-9]'))) score++;
    if (password.contains(RegExp(r'[!@#\$%^&*]'))) score++;
    return score;
  }

  String _labelText(BuildContext context) {
    switch (_strength) {
      case 0:
      case 1:
        return context.tr.passwordWeak;
      case 2:
        return context.tr.passwordFair;
      case 3:
        return context.tr.passwordGood;
      case 4:
        return context.tr.passwordStrong;
      default:
        return '';
    }
  }

  Color get _color {
    switch (_strength) {
      case 0:
      case 1:
        return const Color(0xFFEF4444);
      case 2:
        return const Color(0xFFF59E0B);
      case 3:
        return const Color(0xFF3B82F6);
      case 4:
        return const Color(0xFF10B981);
      default:
        return const Color(0xFFE5E7EB);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.tr.passwordStrengthLabel,
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
            Text(
              _labelText(context),
              style: TextStyle(
                fontSize: 12,
                color: _color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(4, (i) {
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                height: 4,
                decoration: BoxDecoration(
                  color: i < _strength ? _color : const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Text(
          context.tr.passwordStrengthHint,
          style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
        ),
      ],
    );
  }
}
