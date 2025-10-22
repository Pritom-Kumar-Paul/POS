import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width > 700;
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart POS'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/', (r) => false);
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
        children: const [
          _Tile(icon: Icons.point_of_sale, label: 'New Sale', route: '/sale'),
          _Tile(
            icon: Icons.receipt_long,
            label: 'Receipts',
            route: '/receipts',
          ),
          _Tile(
            icon: Icons.inventory_2_outlined,
            label: 'Products',
            route: '/products',
          ),
          _Tile(
            icon: Icons.people_alt_outlined,
            label: 'Customers',
            route: '/customers',
          ),
          _Tile(
            icon: Icons.assessment_outlined,
            label: 'Reports',
            route: '/reports',
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  const _Tile({required this.icon, required this.label, required this.route});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: cs.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => Navigator.of(context).pushNamed(route),
        borderRadius: BorderRadius.circular(12),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 36, color: cs.primary),
              const SizedBox(height: 8),
              Text(label, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
      ),
    );
  }
}
