import 'package:flutter/material.dart';
import 'package:uhd/GettingStart.dart';
import 'package:uhd/ForgotPassword_Screen.dart';
import 'package:uhd/Home.dart';
import 'package:uhd/Signup_Screen.dart';
import 'package:uhd/auth_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  static final List<Map<String, String>> users = [
    {
      "username": "Hana",
      "password": "Hana123@@",
      "email": "hana@gmail.com",
      "age": "22",
      "bloodType": "A+",
    },
    {
      "username": "Sarina",
      "password": "Sarina12!",
      "email": "sarin@gmail.com",
      "age": "24",
      "bloodType": "O+",
    },
    {
      "username": "Lare",
      "password": "Lare123!",
      "email": "lare@gmail.com",
      "age": "21",
      "bloodType": "B+",
    },
  ];

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _hidePassword = true;
  String? _usernameError;
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

  void _validateLogin() {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    final usernameError = _validateName(username);
    final passwordError = _validatePassword(password);

    setState(() {
      _usernameError = usernameError;
      _passwordError = passwordError;
    });

    if (usernameError != null || passwordError != null) {
      return;
    }

    Map<String, String>? user;
    for (final savedUser in LoginScreen.users) {
      if (savedUser["username"] == username &&
          savedUser["password"] == password) {
        user = savedUser;
        break;
      }
    }

    if (user == null) {
      setState(() => _passwordError = "Invalid username or password");
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => HomePage(
          userName: user!["username"] ?? username,
          email: user["email"] ?? "Not added",
          age: user["age"] ?? "Not added",
          bloodType: user["bloodType"] ?? "Not added",
        ),
      ),
    );
  }

  String? _validateName(String value) {
    if (value.isEmpty) {
      return "Name is required";
    }
    if (value.length <= 2) {
      return "Name must be more than 2 characters";
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

  @override
  void dispose() {
    _animationController.dispose();
    _usernameController.dispose();
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
                  controller: _usernameController,
                  hintText: "Username",
                  icon: Icons.person_outline,
                  errorText: _usernameError,
                  onChanged: (value) {
                    if (_usernameError != null) {
                      setState(
                        () => _usernameError = _validateName(value.trim()),
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
                  label: "Login",
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
                        builder: (_) => SignupScreen(users: LoginScreen.users),
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
