import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_page.dart';
import 'home_screen.dart';
import 'app_bootstrap.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasError) {
          return Scaffold(
            body: Center(child: Text('Auth error: ${snap.error}')),
          );
        }
        if (snap.hasData) {
          return AppBootstrap(child: const HomeScreen());
        }
        return const AuthPage();
      },
    );
  }
}
