import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uhd/auth_widgets.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  bool _emailSent = false;
  bool _isLoading = false;
  String? _emailError;

  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.10),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );
    _animationController.forward();
  }

  Future<void> _sendEmail() async {
    if (_isLoading) return;

    final email = _emailController.text.trim();
    final emailError = _validateEmail(email);

    setState(() => _emailError = emailError);

    if (emailError != null) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      setState(() => _emailSent = true);
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      setState(() => _emailError = _authErrorMessage(error));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String? _validateEmail(String value) {
    if (value.isEmpty) {
      return "Email is required";
    }
    final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailPattern.hasMatch(value)) {
      return "Enter a valid email address";
    }
    return null;
  }

  String _authErrorMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'Enter a valid email address';
      case 'user-not-found':
        return 'No account found with this email';
      default:
        return error.message ?? 'Could not send reset email';
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthBackground(
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: AuthCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AuthHeader(
                  icon: Icons.mark_email_read_outlined,
                  title: "Reset password",
                  subtitle: "Enter your email and we will send reset steps.",
                ),
                const SizedBox(height: 26),
                if (_emailSent)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: appTintSurfaceColor(context),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: appBorderColor(context)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          color: authPrimary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "Email sent to ${_emailController.text.trim()}",
                            style: TextStyle(
                              color: appTextColor(context),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  AuthTextField(
                    controller: _emailController,
                    hintText: "Email",
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    errorText: _emailError,
                    onChanged: (value) {
                      if (_emailError != null) {
                        setState(
                          () => _emailError = _validateEmail(value.trim()),
                        );
                      }
                    },
                  ),
                const SizedBox(height: 22),
                if (!_emailSent)
                  AuthPrimaryButton(
                    label: _isLoading ? "Sending..." : "Send Email",
                    icon: Icons.send_outlined,
                    onPressed: _sendEmail,
                  ),
                if (_emailSent)
                  AuthPrimaryButton(
                    label: "Back to Login",
                    icon: Icons.arrow_back,
                    onPressed: () => Navigator.pop(context),
                  ),
                const SizedBox(height: 10),
                if (!_emailSent)
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "Back to login",
                      style: TextStyle(color: authPrimary),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
