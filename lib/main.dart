import 'package:flutter/material.dart';
import 'package:flutter_application_9/login_page.dart';
import 'home_screen.dart';
import 'sales_screen.dart';
import 'products_screen.dart';
import 'receipts_screen.dart';
import 'customers_screen.dart';

// Optional: You can remove this later if you already have a separate login file
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Smart POS Login',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 60,
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  // Navigate to Home Screen
                  Navigator.pushReplacementNamed(context, '/home');
                },
                child: const Text('Login', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart POS',
      // This is the starting screen
      initialRoute: '/',
      routes: {
        '/': (_) => LoginPage(onPressed: () {}),
        '/home': (_) => const HomeScreen(),
        '/sale': (_) => const SalesScreen(),
        '/products': (_) => const ProductsScreen(),
        '/receipts': (_) => const ReceiptsScreen(),
        '/customers': (_) => const CustomersScreen(),
      },
    );
  }
}
