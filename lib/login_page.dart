import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginPage extends StatefulWidget {
  final void Function()? onPressed;
  const LoginPage({super.key, required this.onPressed});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> signInWithEmailAndPassword() async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Login successful"),
          backgroundColor: Colors.green,
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final msg = switch (e.code) {
        'user-not-found' => 'No user found for that email',
        'wrong-password' => 'Wrong password provided',
        _ => e.message ?? 'Login failed',
      };
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: OverflowBar(
              overflowSpacing: 20,
              children: [
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: (text) {
                    if (text == null || text.isEmpty) return 'Email is empty';
                    if (!text.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                  decoration: const InputDecoration(
                    hintText: "Email",
                    border: OutlineInputBorder(),
                  ),
                ),
                TextFormField(
                  controller: _password,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  validator: (text) => (text == null || text.isEmpty)
                      ? 'Password is empty'
                      : null,
                  decoration: const InputDecoration(
                    hintText: "Password",
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  height: 45,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        await signInWithEmailAndPassword();
                      }
                    },
                    child: const Text("Login"),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  height: 45,
                  child: OutlinedButton(
                    onPressed: widget.onPressed,
                    child: const Text("Go to Sign Up"),
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
