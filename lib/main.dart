import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'customers_screen.dart';
import 'firebase_options.dart';
import 'auth_gate.dart';
import 'home_screen.dart';
import 'products_screen.dart';
import 'sales_screen.dart';
import 'receipts_screen.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
// dev only

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // DEV ONLY: protibar app open e login page dite chaile, ei line on korো
  // await FirebaseAuth.instance.signOut();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tender App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: false, primarySwatch: Colors.indigo),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('bn')],
      home: const AuthGate(), // 🔑 login gate
      routes: {
        '/home': (_) => const HomeScreen(),
        '/sale': (_) => const SalesScreen(),
        '/receipts': (_) => const ReceiptsScreen(),
        '/products': (_) => const ProductsScreen(),
        '/customers': (_) => const CustomersScreen(),
      },
    );
  }
}
