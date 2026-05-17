import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uhd/Home.dart';
import 'package:uhd/Login_Screen.dart';
import 'package:uhd/VerifyEmail_Screen.dart';
import 'package:uhd/auth_widgets.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen();
        }

        final user = snapshot.data;
        if (user == null) {
          return const LoginScreen();
        }

        if (!user.emailVerified) {
          return VerifyEmailScreen(email: user.email ?? '');
        }

        return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get(),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const _LoadingScreen();
            }

            final data = profileSnapshot.data?.data() ?? {};
            return HomePage(
              userName:
                  (data['username'] as String?) ??
                  user.displayName ??
                  'MediTrack user',
              email: (data['email'] as String?) ?? user.email ?? 'Not added',
              age: (data['age'] as String?) ?? 'Not added',
              bloodType: (data['bloodType'] as String?) ?? 'Not added',
            );
          },
        );
      },
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appScaffoldColor(context),
      body: const Center(child: CircularProgressIndicator(color: authPrimary)),
    );
  }
}
