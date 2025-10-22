import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'auth_page.dart';
import 'home_screen.dart';
import 'sales_screen.dart';
import 'receipts_screen.dart';
import 'products_screen.dart';
import 'customers_screen.dart';
import 'reports_screen.dart';
import 'app_bootstrap.dart';

import 'package:flutter_localizations/flutter_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart POS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: false, primarySwatch: Colors.indigo),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('bn')],
      initialRoute: '/',
      routes: {
        '/': (_) => const AuthGate(),
        // Bind once after login
        '/home': (_) => const HomeScreen(),
        // Direct screens (do not wrap again)
        '/sale': (_) => const SalesScreen(),
        '/receipts': (_) => const ReceiptsScreen(),
        '/products': (_) => const ProductsScreen(),
        '/customers': (_) => const CustomersScreen(),
        '/reports': (_) => const ReportsScreen(),
      },
    );
  }
}

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
