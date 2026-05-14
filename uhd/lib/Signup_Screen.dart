import 'package:flutter/material.dart';
import 'package:uhd/VerifyEmail_Screen.dart';
import 'package:uhd/auth_widgets.dart';

class SignupScreen extends StatefulWidget {
  final List<Map<String, String>> users;

  const SignupScreen({super.key, required this.users});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with SingleTickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _ageController = TextEditingController();

  final List<String> _bloodTypes = const [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];

  String? _selectedBloodType;
  bool _hidePassword = true;
  String? _usernameError;
  String? _emailError;
  String? _ageError;
  String? _bloodTypeError;
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

  void _createAccount() {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final age = _ageController.text.trim();
    final usernameError = _validateName(username);
    final emailError = _validateEmail(email);
    final ageError = _validateAge(age);
    final bloodTypeError = _selectedBloodType == null
        ? "Please select your blood type"
        : null;
    final passwordError = _validatePassword(password);

    setState(() {
      _usernameError = usernameError;
      _emailError = emailError;
      _ageError = ageError;
      _bloodTypeError = bloodTypeError;
      _passwordError = passwordError;
    });

    if (usernameError != null ||
        emailError != null ||
        ageError != null ||
        bloodTypeError != null ||
        passwordError != null) {
      return;
    }

    final usernameExists = widget.users.any(
      (user) => user["username"] == username,
    );

    final emailExists = widget.users.any((user) => user["email"] == email);

    if (usernameExists || emailExists) {
      setState(() {
        if (usernameExists) {
          _usernameError = "Username already exists";
        }
        if (emailExists) {
          _emailError = "Email already exists";
        }
      });
      return;
    }

    widget.users.add({
      "username": username,
      "password": password,
      "email": email,
      "age": age,
      "bloodType": _selectedBloodType!,
    });

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => VerifyEmailScreen(
          userName: username,
          email: email,
          age: age,
          bloodType: _selectedBloodType!,
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

  String? _validateAge(String value) {
    if (value.isEmpty) {
      return "Age is required";
    }
    if (!RegExp(r'^\d+$').hasMatch(value)) {
      return "Age must contain digits only";
    }
    final age = int.parse(value);
    if (age < 0 || age > 130) {
      return "Age must be between 0 and 130";
    }
    return null;
  }

  String? _validatePassword(String value) {
    if (value.isEmpty) {
      return "Password is required";
    }
    if (!_hasValidPassword(value)) {
      return "Complete all password requirements below";
    }
    return null;
  }

  bool _hasValidPassword(String value) {
    return _hasMinLength(value) &&
        _hasUppercase(value) &&
        _hasLowercase(value) &&
        _hasNumber(value) &&
        _hasSymbol(value);
  }

  bool _hasMinLength(String value) => value.length >= 6;
  bool _hasUppercase(String value) => RegExp(r'[A-Z]').hasMatch(value);
  bool _hasLowercase(String value) => RegExp(r'[a-z]').hasMatch(value);
  bool _hasNumber(String value) => RegExp(r'[0-9]').hasMatch(value);
  bool _hasSymbol(String value) => RegExp(r'[^A-Za-z0-9]').hasMatch(value);

  @override
  void dispose() {
    _animationController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _ageController.dispose();
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
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    tooltip: "Back to login",
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                  ),
                ),
                const AuthHeader(
                  icon: Icons.person_add_alt_1_outlined,
                  title: "Create account",
                  subtitle: "Add your basic health details to get started.",
                ),
                const SizedBox(height: 24),
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
                  controller: _ageController,
                  hintText: "Age",
                  icon: Icons.cake_outlined,
                  keyboardType: TextInputType.number,
                  errorText: _ageError,
                  onChanged: (value) {
                    if (_ageError != null) {
                      setState(() => _ageError = _validateAge(value.trim()));
                    }
                  },
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: _selectedBloodType,
                  decoration: authInputDecoration(
                    hintText: "Blood type",
                    icon: Icons.bloodtype_outlined,
                    errorText: _bloodTypeError,
                  ),
                  items: _bloodTypes
                      .map(
                        (type) => DropdownMenuItem<String>(
                          value: type,
                          child: Text(type),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedBloodType = value;
                      _bloodTypeError = null;
                    });
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
                    setState(() {
                      _passwordError = _passwordError == null
                          ? null
                          : _validatePassword(value.trim());
                    });
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
                const SizedBox(height: 10),
                PasswordChecklist(
                  password: _passwordController.text,
                  hasMinLength: _hasMinLength,
                  hasUppercase: _hasUppercase,
                  hasLowercase: _hasLowercase,
                  hasNumber: _hasNumber,
                  hasSymbol: _hasSymbol,
                ),
                const SizedBox(height: 22),
                AuthPrimaryButton(
                  label: "Create Account",
                  icon: Icons.check_circle_outline,
                  onPressed: _createAccount,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PasswordChecklist extends StatelessWidget {
  final String password;
  final bool Function(String) hasMinLength;
  final bool Function(String) hasUppercase;
  final bool Function(String) hasLowercase;
  final bool Function(String) hasNumber;
  final bool Function(String) hasSymbol;

  const PasswordChecklist({
    super.key,
    required this.password,
    required this.hasMinLength,
    required this.hasUppercase,
    required this.hasLowercase,
    required this.hasNumber,
    required this.hasSymbol,
  });

  @override
  Widget build(BuildContext context) {
    final requirements = [
      _PasswordRequirement("At least 6 characters", hasMinLength(password)),
      _PasswordRequirement("One uppercase letter", hasUppercase(password)),
      _PasswordRequirement("One lowercase letter", hasLowercase(password)),
      _PasswordRequirement("One number", hasNumber(password)),
      _PasswordRequirement("One symbol", hasSymbol(password)),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF8F6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.teal.shade100),
      ),
      child: Column(
        children: requirements
            .map(
              (requirement) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Icon(
                      requirement.isMet
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      size: 18,
                      color: requirement.isMet
                          ? authPrimary
                          : Colors.blueGrey.shade300,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        requirement.label,
                        style: TextStyle(
                          color: requirement.isMet
                              ? authInk
                              : Colors.blueGrey.shade500,
                          fontSize: 13,
                          fontWeight: requirement.isMet
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _PasswordRequirement {
  final String label;
  final bool isMet;

  const _PasswordRequirement(this.label, this.isMet);
}
