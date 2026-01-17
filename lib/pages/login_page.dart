import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../services/auth_service.dart';
import 'signup_page.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  bool _showResendVerification = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() => _errorMessage = 'loginEmptyFields'.tr());
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _showResendVerification = false;
    });

    try {
      await _authService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => const HomePage()));
      }
    } catch (e) {
      String errorMsg = e.toString();

      // E-posta doğrulanmamış hatası kontrolü
      if (errorMsg.contains('EMAIL_NOT_VERIFIED')) {
        setState(() {
          _errorMessage = 'emailNotVerified'.tr();
          _showResendVerification = true;
        });
      } else {
        setState(() => _errorMessage = errorMsg);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendVerificationEmail() async {
    setState(() => _isLoading = true);
    try {
      await _authService.resendVerificationEmail();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('verificationEmailSent'.tr()),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showForgotPasswordDialog() async {
    final resetEmailController = TextEditingController();

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF16213E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'forgotPassword'.tr(),
              style: const TextStyle(color: Colors.white),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'forgotPasswordDesc'.tr(),
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: resetEmailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'loginEmail'.tr(),
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.1),
                    prefixIcon: const Icon(
                      Icons.email,
                      color: Color(0xFF00B4D8),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'cancel'.tr(),
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00B4D8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () async {
                  if (resetEmailController.text.trim().isEmpty) {
                    return;
                  }
                  try {
                    await _authService.sendPasswordResetEmail(
                      resetEmailController.text.trim(),
                    );
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('resetPasswordSent'.tr()),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(e.toString()),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: Text(
                  'send'.tr(),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F3460), Color(0xFF16213E)],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 40),

                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  const Color(
                                    0xFF00B4D8,
                                  ).withValues(alpha: 0.8),
                                  const Color(
                                    0xFFE94560,
                                  ).withValues(alpha: 0.8),
                                ],
                              ),
                            ),
                            padding: const EdgeInsets.all(20),
                            child: const Icon(
                              Icons.lightbulb,
                              size: 60,
                              color: Colors.white,
                            ),
                          ),

                          const SizedBox(height: 24),
                          const Text(
                            'Focusly',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'loginSubtitle'.tr(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),

                          const SizedBox(height: 48),

                          if (_errorMessage != null)
                            Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.shade400.withValues(
                                  alpha: 0.2,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red.shade400),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    _errorMessage!,
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 13,
                                    ),
                                  ),
                                  if (_showResendVerification) ...[
                                    const SizedBox(height: 8),
                                    GestureDetector(
                                      onTap: _resendVerificationEmail,
                                      child: Text(
                                        'resendVerification'.tr(),
                                        style: const TextStyle(
                                          color: Color(0xFF00B4D8),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),

                          TextField(
                            controller: _emailController,
                            enabled: !_isLoading,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(color: Colors.white),
                            decoration: _input('loginEmail'.tr(), Icons.email),
                          ),

                          const SizedBox(height: 16),

                          TextField(
                            controller: _passwordController,
                            enabled: !_isLoading,
                            obscureText: _obscurePassword,
                            style: const TextStyle(color: Colors.white),
                            decoration: _passwordInput('loginPassword'.tr()),
                          ),

                          const SizedBox(height: 12),

                          // Şifremi Unuttum linki
                          Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: _showForgotPasswordDialog,
                              child: Text(
                                'forgotPassword'.tr(),
                                style: const TextStyle(
                                  color: Color(0xFF00B4D8),
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00B4D8),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child:
                                _isLoading
                                    ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                    : Text(
                                      'loginButton'.tr(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                          ),

                          const Spacer(),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'loginNoAccount'.tr(),
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                              ),
                              GestureDetector(
                                onTap:
                                    () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => const SignUpPage(),
                                      ),
                                    ),
                                child: Text(
                                  'loginCreateAccount'.tr(),
                                  style: const TextStyle(
                                    color: Color(0xFF00B4D8),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  InputDecoration _input(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
    filled: true,
    fillColor: Colors.white.withValues(alpha: 0.1),
    prefixIcon: Icon(icon, color: const Color(0xFF00B4D8)),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
  );

  InputDecoration _passwordInput(String label) => _input(
    label,
    Icons.lock,
  ).copyWith(
    suffixIcon: IconButton(
      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
      color: const Color(0xFF00B4D8),
      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
    ),
  );
}
