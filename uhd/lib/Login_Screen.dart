import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uhd/GettingStart.dart';
import 'package:uhd/ForgotPassword_Screen.dart';
import 'package:uhd/Home.dart';
import 'package:uhd/Signup_Screen.dart';
import 'package:uhd/auth_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _hidePassword = true;
  bool _isLoading = false;
  String? _emailError;
  String? _passwordError;

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
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.10), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
  }

  Future<void> _validateLogin() async {
    if (_isLoading) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final emailError = _validateEmail(email);
    final passwordError = _validatePassword(password);

    setState(() {
      _emailError = emailError;
      _passwordError = passwordError;
    });

    if (emailError != null || passwordError != null) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      await user?.reload();
      final refreshedUser = FirebaseAuth.instance.currentUser;

      if (refreshedUser == null) {
        throw FirebaseAuthException(code: 'user-not-found');
      }

      if (!refreshedUser.emailVerified) {
        await FirebaseAuth.instance.signOut();
        if (!mounted) return;
        showAuthMessage(
          context,
          'Please verify your email before logging in.',
          backgroundColor: Colors.redAccent,
        );
        return;
      }

      final profile = await FirebaseFirestore.instance
          .collection('users')
          .doc(refreshedUser.uid)
          .get();
      final data = profile.data() ?? {};

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomePage(
            userName:
                (data['username'] as String?) ??
                refreshedUser.displayName ??
                'MediTrack user',
            email:
                (data['email'] as String?) ??
                refreshedUser.email ??
                'Not added',
            age: (data['age'] as String?) ?? 'Not added',
            bloodType: (data['bloodType'] as String?) ?? 'Not added',
          ),
        ),
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      setState(() => _passwordError = _authErrorMessage(error));
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

  String? _validatePassword(String value) {
    if (value.isEmpty) {
      return "Password is required";
    }
    if (!_hasValidPassword(value)) {
      return "Use 6+ chars with upper, lower, number, and symbol";
    }
    return null;
  }

  bool _hasValidPassword(String value) {
    return value.length >= 6 &&
        RegExp(r'[A-Z]').hasMatch(value) &&
        RegExp(r'[a-z]').hasMatch(value) &&
        RegExp(r'[0-9]').hasMatch(value) &&
        RegExp(r'[^A-Za-z0-9]').hasMatch(value);
  }

  String _authErrorMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'Enter a valid email address';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password';
      default:
        return error.message ?? 'Could not login. Please try again.';
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
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
                  icon: Icons.medication_liquid_outlined,
                  title: "Welcome back",
                  subtitle: "Sign in to manage medicines and reminders.",
                ),
                const SizedBox(height: 28),
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
                const SizedBox(height: 14),
                AuthTextField(
                  controller: _passwordController,
                  hintText: "Password",
                  icon: Icons.lock_outline,
                  obscureText: _hidePassword,
                  errorText: _passwordError,
                  onChanged: (value) {
                    if (_passwordError != null) {
                      setState(
                        () => _passwordError = _validatePassword(value.trim()),
                      );
                    }
                  },
                  suffixIcon: IconButton(
                    tooltip: _hidePassword ? "Show password" : "Hide password",
                    onPressed: () {
                      setState(() => _hidePassword = !_hidePassword);
                    },
                    icon: Icon(
                      _hidePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: Colors.blueGrey,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ForgotPasswordScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      "Forgot password?",
                      style: TextStyle(color: authPrimary),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                AuthPrimaryButton(
                  label: _isLoading ? "Logging in..." : "Login",
                  icon: Icons.login,
                  onPressed: _validateLogin,
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey.shade300)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        "OR",
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey.shade300)),
                  ],
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SignupScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.person_add_alt_1_outlined),
                  label: const Text("Create Account"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: authPrimary,
                    minimumSize: const Size.fromHeight(52),
                    side: BorderSide(color: Colors.teal.shade100),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const GettingStartedPage(),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF8F6),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.teal.shade100),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: authPrimary,
                          child: Icon(Icons.help_outline, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Need a quick guide?",
                                style: TextStyle(
                                  color: authInk,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                "Open Getting Started",
                                style: TextStyle(
                                  color: Colors.blueGrey.shade500,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: authPrimary,
                          size: 18,
                        ),
                      ],
                    ),
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
