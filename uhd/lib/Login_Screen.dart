 import 'package:flutter/material.dart';
import 'package:uhd/GettingStart.dart';
import 'Home.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginScreen(),
    );
  }
}

/// ================= LOGIN SCREEN =================

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<Map<String, String>> validUsers = [
    {"username": "Hana", "password": "1234", "email": "hana@gmail.com"},
    {"username": "Sarina", "password": "12", "email": "sarin@gmail.com"},
    {"username": "Lare", "password": "123", "email": "lare@gmail.com"},
  ];

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation =
        CurvedAnimation(parent: _animationController, curve: Curves.easeIn);

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _animationController.forward();
  }

  void _validateLogin() {
    bool valid = validUsers.any(
      (u) =>
          u["username"] == _usernameController.text.trim() &&
          u["password"] == _passwordController.text.trim(),
    );

    if (valid) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomePage(
            userName: _usernameController.text.trim(),
          ),
        ),
      );
    } else {
      _show("Invalid username or password");
    }
  }

  void _forgotPassword() {
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text("Forgot Password"),
        content: TextField(
          controller: emailController,
          decoration: InputDecoration(
            labelText: "Enter your email",
            prefixIcon: const Icon(Icons.email),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              final user = validUsers.firstWhere(
                (u) => u["email"] == emailController.text.trim(),
                orElse: () => {},
              );

              Navigator.pop(context);

              if (user.isNotEmpty) {
                _show(
                  "Password for ${user["username"]}: ${user["password"]}",
                );
              } else {
                _show("Email not found");
              }
            },
            child: const Text("Submit"),
          ),
        ],
      ),
    );
  }

  void _show(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
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
    return Scaffold(
      body: Stack(
        alignment: Alignment.center,
        children: [
          /// ===== BACKGROUND IMAGE =====
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('images/yyt.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          /// ===== DARK OVERLAY =====
          Container(
            color: Colors.black.withOpacity(0.45),
          ),

          /// ===== LOGIN CARD =====
          SingleChildScrollView(
            child: SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  width: 360,
                  padding: const EdgeInsets.fromLTRB(22, 40, 22, 25),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.96),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 25,
                        offset: Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      /// ===== APP ICON =====
                      CircleAvatar(
                        radius: 42,
                        backgroundColor: Colors.teal,
                        child: Icon(
                          Icons.favorite_border,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),

                      const SizedBox(height: 18),

                      const Text(
                        "Welcome Back",
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 5),

                      const Text(
                        "Login to continue",
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 15,
                        ),
                      ),

                      const SizedBox(height: 28),

                      /// ===== USERNAME =====
                      TextField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          hintText: "Username",
                          prefixIcon: const Icon(Icons.person),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      /// ===== PASSWORD =====
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: "Password",
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: const Icon(Icons.visibility_off),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      /// ===== FORGOT PASSWORD =====
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _forgotPassword,
                          child: const Text(
                            "Forgot password?",
                            style: TextStyle(
                              color: Colors.teal,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      /// ===== LOGIN BUTTON =====
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: _validateLogin,
                          child: const Text(
                            "Login",
                            style: TextStyle(
                              fontSize: 17,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      /// ===== OR =====
                      Row(
                        children: const [
                          Expanded(child: Divider()),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: Text("OR"),
                          ),
                          Expanded(child: Divider()),
                        ],
                      ),

                      const SizedBox(height: 12),

                      /// ===== CREATE ACCOUNT =====
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  CreateAccountScreen(users: validUsers),
                            ),
                          );
                        },
                        child: const Text(
                          "Create Account",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.teal,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      /// ===== GETTING STARTED BOX =====
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.teal,
                            width: 1.3,
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.teal,
                              child: const Icon(
                                Icons.help_outline,
                                color: Colors.white,
                              ),
                            ),

                            const SizedBox(width: 12),

                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    "Not sure how to use the app?",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 3),
                                  Text(
                                    "Open Getting Started Guide",
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            IconButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const GettingStartedPage(),
                                  ),
                                );
                              },
                              icon: const Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.teal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ================= CREATE ACCOUNT SCREEN =================

class CreateAccountScreen extends StatefulWidget {
  final List<Map<String, String>> users;

  const CreateAccountScreen({
    super.key,
    required this.users,
  });

  @override
  State<CreateAccountScreen> createState() =>
      _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _username = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _email = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation =
        CurvedAnimation(parent: _animationController, curve: Curves.easeIn);

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _username.dispose();
    _password.dispose();
    _email.dispose();
    super.dispose();
  }

  void _createAccount() {
    if (_username.text.isEmpty ||
        _password.text.isEmpty ||
        _email.text.isEmpty) {
      _show("Please fill all fields");
      return;
    }

    bool exists = widget.users.any(
      (u) => u["username"] == _username.text.trim(),
    );

    if (exists) {
      _show("Username already exists");
      return;
    }

    widget.users.add({
      "username": _username.text.trim(),
      "password": _password.text.trim(),
      "email": _email.text.trim(),
    });

    _show("Account created successfully");
    Navigator.pop(context);
  }
void _show(String msg) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.white,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              msg,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),

      behavior: SnackBarBehavior.floating,

      backgroundColor: Colors.redAccent,

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),

      margin: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 20,
      ),

      duration: const Duration(seconds: 2),

      elevation: 10,
    ),
  );
}
  // void _show(String msg) {
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(content: Text(msg)),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('images/yyt.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          Container(
            color: Colors.black.withOpacity(0.45),
          ),

          SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                width: 360,
                padding: const EdgeInsets.fromLTRB(22, 35, 22, 25),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.96),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ),

                    const Text(
                      "Create Account",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 24),

                    TextField(
                      controller: _username,
                      decoration: InputDecoration(
                        hintText: "Username",
                        prefixIcon: const Icon(Icons.person),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    TextField(
                      controller: _email,
                      decoration: InputDecoration(
                        hintText: "Email",
                        prefixIcon: const Icon(Icons.email),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    TextField(
                      controller: _password,
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: "Password",
                        prefixIcon: const Icon(Icons.lock),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 22),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: _createAccount,
                        child: const Text(
                          "Create Account",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
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
// import 'package:flutter/material.dart';
// import 'Home.dart';

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return const MaterialApp(
//       debugShowCheckedModeBanner: false,
//       home: LoginScreen(),
      
//     );
    
//   }
  
// }

// /// ================= LOGIN SCREEN =================

// class LoginScreen extends StatefulWidget {
//   const LoginScreen({super.key});

//   @override
//   State<LoginScreen> createState() => _LoginScreenState();
  
// }

// class _LoginScreenState extends State<LoginScreen>
//     with SingleTickerProviderStateMixin {

//   final _usernameController = TextEditingController();
//   final _passwordController = TextEditingController();

//   late AnimationController _animationController;
//   late Animation<double> _fadeAnimation;
//   late Animation<Offset> _slideAnimation;

//   final List<Map<String, String>> validUsers = [
//     {"username": "Hana", "password": "1234", "email": "hana@gmail.com"},
//     {"username": "Sarina", "password": "12", "email": "sarin@gmail.com"},
//     {"username": "Lare", "password": "123", "email": "lare@gmail.com"},
//   ];

//   @override
//   void initState() {
//     super.initState();

//     _animationController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 800),
//     );

//     _fadeAnimation =
//         CurvedAnimation(parent: _animationController, curve: Curves.easeIn);

//     _slideAnimation = Tween<Offset>(
//       begin: const Offset(0, 0.15),
//       end: Offset.zero,
//     ).animate(CurvedAnimation(
//       parent: _animationController,
//       curve: Curves.easeOut,
//     ));

//     _animationController.forward();
//   }

//   void _validateLogin() {
//     bool valid = validUsers.any(//cheky akatawa
//       (u) =>
//           u["username"] == _usernameController.text.trim() &&
//           u["password"] == _passwordController.text.trim(),
//     );

//     if (valid) {//agar drust buu
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(
//           builder: (_) =>
//               HomePage(userName: _usernameController.text.trim()),//nawy bakarhenar nerdrawa bo home
//         ),
//       );
//     } else {
//       _show("Invalid username or password");
//     }
//   }

//   void _forgotPassword() {
//     final emailController = TextEditingController();

//     showDialog(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: const Text("Forgot Password"),
//         content: TextField(
//           controller: emailController,
//           decoration: const InputDecoration(
//             labelText: "Enter your email",
//             prefixIcon: Icon(Icons.email),
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text("Cancel"),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               final user = validUsers.firstWhere(
//                 (u) => u["email"] == emailController.text.trim(),
//                 orElse: () => {},
//               );
//               Navigator.pop(context);

//               if (user.isNotEmpty) {
//                 _show(
//                     "Password for ${user["username"]}: ${user["password"]}");
//               } else {
//                 _show("Email not found");
//               }
//             },
//             child: const Text("Submit"),
//           ),
//         ],
//       ),
//     );
//   }

//   void _show(String msg) {
//     ScaffoldMessenger.of(context)
//         .showSnackBar(SnackBar(content: Text(msg)));
//   }

//   @override
//   void dispose() {
//     _animationController.dispose();
//     _usernameController.dispose();
//     _passwordController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Stack(
//         alignment: Alignment.center,
//         children: [

//           /// ===== BACKGROUND IMAGE =====
//           Container(
//             decoration: const BoxDecoration(
//               image: DecorationImage(
//                 image: AssetImage('images/yyt.jpg'),
//                 fit: BoxFit.cover,
//               ),
//             ),
//           ),

 
// /// ===== DARK OVERLAY (OPTIONAL BUT NICE) =====
//           Container(
//             color: Colors.black.withOpacity(0.4),
//           ),

//           /// ===== LOGIN CARD =====
//           SlideTransition(
//             position: _slideAnimation,
//             child: FadeTransition(
//               opacity: _fadeAnimation,
//               child: Container(
//                 width: 360,
//                 padding: const EdgeInsets.fromLTRB(20, 50, 20, 25),
//                 decoration: BoxDecoration(
//                   color: Colors.white,//rangy containaraka
//                   borderRadius: BorderRadius.circular(24),
//                   boxShadow: const [
//                     BoxShadow(
//                       color: Colors.black26,
//                       blurRadius: 25,
//                       offset: Offset(0, 12),
//                     ),
//                   ],
//                 ),
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [

//                     TextField(
//                       controller: _usernameController,
//                       decoration: InputDecoration(
//                         labelText: "Username",
//                         prefixIcon: const Icon(Icons.person),
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 15),

//                     TextField(
//                       controller: _passwordController,
//                       obscureText: true,//katek ka password anusin dearnaby
//                       decoration: InputDecoration(
//                         labelText: "Password",
//                         prefixIcon: const Icon(Icons.lock),
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                       ),
//                     ),

//                     const SizedBox(height: 10),
//                   /////////////forget
//                     Align(
//                       alignment: Alignment.centerRight,
//                       child: TextButton(
//                         onPressed: _forgotPassword,
//                         child: const Text("Forgot password?"),
//                       ),
//                     ),

//                     const SizedBox(height: 10),

//                     SizedBox(
//                       width: double.infinity,//containary login
//                       height: 45,
//                       child: ElevatedButton(
//                         onPressed: _validateLogin,
//                         child: const Text("Login"),
//                       ),
//                     ),

//                     const SizedBox(height: 15),

//                     Row(
//                       children: const [
//                         Expanded(child: Divider()),
//                         Padding(
//                           padding: EdgeInsets.symmetric(horizontal: 8),//durkawtnaway xataka la or
//                           child: Text("OR"),
//                         ),
//                         Expanded(child: Divider()),//or axata nawarast
//                       ],
//                     ),

//                     TextButton(
//                       onPressed: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (_) =>
//                                 CreateAccountScreen(users: validUsers),
//                           ),
//                         );
//                       },
//                       child: const Text("Create Account"),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// /// ================= CREATE ACCOUNT SCREEN =================
// class CreateAccountScreen extends StatefulWidget {
//   final List<Map<String, String>> users;
//   const CreateAccountScreen({super.key, required this.users});

//   @override
//   State<CreateAccountScreen> createState() => _CreateAccountScreenState();
// }

// class _CreateAccountScreenState extends State<CreateAccountScreen>
//     with SingleTickerProviderStateMixin {
//   final TextEditingController _username = TextEditingController();
//   final TextEditingController _password = TextEditingController();
//   final TextEditingController _email = TextEditingController();

//   late AnimationController _animationController;
//   late Animation<double> _fadeAnimation;
//   late Animation<Offset> _slideAnimation;

//   @override
//   void initState() {
//     super.initState();

//     _animationController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 800),
//     );

//     _fadeAnimation =
//         CurvedAnimation(parent: _animationController, curve: Curves.easeIn);

//     _slideAnimation = Tween<Offset>(
//       begin: const Offset(0, 0.15),
//       end: Offset.zero,
//     ).animate(CurvedAnimation(
//       parent: _animationController,
//       curve: Curves.easeOut,
//     ));

//     _animationController.forward();
//   }

//   @override
//   void dispose() {
//     _animationController.dispose();
//     _username.dispose();
//     _password.dispose();
//     _email.dispose();
//     super.dispose();
//   }

//   void _createAccount() {
//     if (_username.text.isEmpty ||
//         _password.text.isEmpty ||
//         _email.text.isEmpty) {
//       _show("Please fill all fields");
//       return;
//     }

//     bool exists = widget.users.any(
//       (u) => u["username"] == _username.text.trim(),
//     );

//     if (exists) {
//       _show("Username already exists");
//       return;
//     }

//     widget.users.add({
//       "username": _username.text.trim(),
//       "password": _password.text.trim(),
//       "email": _email.text.trim(),
//     });

//     _show("Account created successfully");
//     Navigator.pop(context);
//   }

//   void _show(String msg) {
//     ScaffoldMessenger.of(context)
//         .showSnackBar(SnackBar(content: Text(msg)));
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Stack(
//         alignment: Alignment.center,
//         children: [
//           /// ===== BACKGROUND IMAGE =====
//           Container(
//             decoration: const BoxDecoration(
//               image: DecorationImage(
//                 image: AssetImage('images/yyt.jpg'),
//                 fit: BoxFit.cover,
//               ),
//             ),
//           ),

//           /// ===== DARK OVERLAY =====
//           Container(
//             color: Colors.black.withOpacity(0.4),
//           ),

//           /// ===== CREATE ACCOUNT CARD =====
//           SlideTransition(
//             position: _slideAnimation,
//             child: FadeTransition(
//               opacity: _fadeAnimation,
//               child: Container(
//                 width: 360,
//                 padding: const EdgeInsets.fromLTRB(20, 50, 20, 25),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(24),
//                   boxShadow: const [
//                     BoxShadow(
//                       color: Colors.black26,
//                       blurRadius: 25,
//                       offset: Offset(0, 12),
//                     ),
//                   ],
//                 ),
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     /// Close button
//                     Align(
//                       alignment: Alignment.topRight,
//                       child: IconButton(
//                         onPressed: () => Navigator.pop(context),
//                         icon: const Icon(Icons.close),
//                       ),
//                     ),
//                     const Text(
//                       "Create Account",
//                       style: TextStyle(
//                         fontSize: 24,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     const SizedBox(height: 20),
//                     TextField(
//                       controller: _username,
//                       decoration: InputDecoration(
//                         labelText: "Username",
//                         prefixIcon: const Icon(Icons.person),
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 15),
//                     TextField(
//                       controller: _email,
//                       decoration: InputDecoration(
//                         labelText: "Email",
//                         prefixIcon: const Icon(Icons.email),
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 15),
//                     TextField(
//                       controller: _password,
//                       obscureText: true,
//                       decoration: InputDecoration(
//                         labelText: "Password",
//                         prefixIcon: const Icon(Icons.lock),
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 20),
//                     SizedBox(
//                       width: double.infinity,
//                       height: 45,
//                       child: ElevatedButton(
//                         onPressed: _createAccount,
//                         child: const Text("Create Account"),
                        
//                       ),
                      
//                     ),
//                   ],
                  
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }