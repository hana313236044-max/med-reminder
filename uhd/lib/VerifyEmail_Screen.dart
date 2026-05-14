import 'package:flutter/material.dart';
import 'package:uhd/Home.dart';
import 'package:uhd/auth_widgets.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String userName;
  final String email;
  final String age;
  final String bloodType;

  const VerifyEmailScreen({
    super.key,
    required this.userName,
    required this.email,
    required this.age,
    required this.bloodType,
  });

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen>
    with SingleTickerProviderStateMixin {
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

  void _verifyNow() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => HomePage(
          userName: widget.userName,
          email: widget.email,
          age: widget.age,
          bloodType: widget.bloodType,
        ),
      ),
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
                    color: const Color(0xFFEAF8F6),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.teal.shade100),
                  ),
                  child: Column(
                    children: [
                      Text(
                        widget.email,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: authInk,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "No backend yet, so Verify Now will continue to Home.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.blueGrey.shade500,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                AuthPrimaryButton(
                  label: "Verify Now",
                  icon: Icons.check_circle_outline,
                  onPressed: _verifyNow,
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () {
                    showAuthMessage(context, "Verification email resent");
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text("Resend Email"),
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
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Back",
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
