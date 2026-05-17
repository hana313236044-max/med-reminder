// This screen asks users to verify their email address.
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uhd/screens/auth_gate.dart';
import 'package:uhd/widgets/app_widgets.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String? userName;
  final String email;
  final String? age;
  final String? bloodType;

  const VerifyEmailScreen({
    super.key,
    this.userName,
    required this.email,
    this.age,
    this.bloodType,
  });

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen>
    with SingleTickerProviderStateMixin {
  bool _isChecking = false;
  bool _isResending = false;

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

  Future<void> _checkVerification() async {
    if (_isChecking) return;

    setState(() => _isChecking = true);
    try {
      await FirebaseAuth.instance.currentUser?.reload();
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.emailVerified) {
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AuthGate()),
          (route) => false,
        );
        return;
      }

      if (!mounted) return;
      showAuthMessage(
        context,
        'Email is not verified yet. Check your inbox and try again.',
        backgroundColor: Colors.redAccent,
      );
    } finally {
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  Future<void> _resendEmail() async {
    if (_isResending) return;

    setState(() => _isResending = true);
    try {
      await FirebaseAuth.instance.currentUser?.sendEmailVerification();
      if (!mounted) return;
      showAuthMessage(context, "Verification email resent");
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      showAuthMessage(
        context,
        error.message ?? 'Could not resend verification email',
        backgroundColor: Colors.redAccent,
      );
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  Future<void> _backToLogin() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AuthGate()),
      (route) => false,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
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
                  icon: Icons.verified_user_outlined,
                  title: "Verify email",
                  subtitle: "We sent a verification link to your email.",
                ),
                const SizedBox(height: 22),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: appTintSurfaceColor(context),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: appBorderColor(context)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        widget.email,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: appTextColor(context),
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Open the link in your inbox, then return here and check verification.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: appMutedTextColor(context),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                AuthPrimaryButton(
                  label: _isChecking ? "Checking..." : "I Verified My Email",
                  icon: Icons.check_circle_outline,
                  onPressed: _checkVerification,
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _resendEmail,
                  icon: const Icon(Icons.refresh),
                  label: Text(_isResending ? "Resending..." : "Resend Email"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: authPrimary,
                    minimumSize: const Size.fromHeight(52),
                    side: BorderSide(color: Colors.teal.shade100),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _backToLogin,
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
