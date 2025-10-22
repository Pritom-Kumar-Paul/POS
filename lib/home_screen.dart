import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool wide = MediaQuery.of(context).size.width > 700;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart POS'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              try {
                await FirebaseAuth.instance.signOut(); // ✅ Logout from Firebase
                if (context.mounted) {
                  Navigator.of(
                    context,
                  ).pushReplacementNamed('/'); // Back to AuthPage
                }
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Logout failed: $e')));
              }
            },
          ),
        ],
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(24),
        crossAxisCount: wide ? 4 : 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          _Tile(
            icon: Icons.point_of_sale,
            label: 'New Sale',
            onTap: () => Navigator.of(context).pushNamed('/sale'),
          ),
          _Tile(
            icon: Icons.receipt_long,
            label: 'Receipts',
            onTap: () => Navigator.of(context).pushNamed('/receipts'),
          ),
          _Tile(
            icon: Icons.inventory_2_outlined,
            label: 'Products',
            onTap: () => Navigator.of(context).pushNamed('/products'),
          ),
          _Tile(
            icon: Icons.people_alt_outlined,
            label: 'Customers',
            onTap: () => Navigator.of(context).pushNamed('/customers'),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _Tile({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      elevation: 2,
      color: cs.surfaceVariant,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 40, color: cs.primary),
              const SizedBox(height: 10),
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
