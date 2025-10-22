import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'repositories/user_repository.dart';
import 'session.dart';
import 'product_store.dart';
import 'customer_store.dart';
import 'receipt_store.dart';

class AppBootstrap extends StatefulWidget {
  final Widget child;
  const AppBootstrap({super.key, required this.child});

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  bool _ready = false;
  final _userRepo = UserRepository();

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final user = FirebaseAuth.instance.currentUser!;
    final profile = await _userRepo.ensureProfile(user);

    session.setProfile(orgId: profile.orgId, role: profile.role);
    productStore.bind(profile.orgId);
    customerStore.bind(profile.orgId);
    receiptStore.bind(profile.orgId);

    setState(() => _ready = true);
  }

  @override
  void dispose() {
    productStore.unbind();
    customerStore.unbind();
    receiptStore.unbind();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return widget.child;
  }
}
