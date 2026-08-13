import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/business_info.dart';
import 'dashboard_screen.dart';
import 'clients_screen.dart';
import 'commandes_screen.dart';
import 'factures_screen.dart';
import 'placeholder_screen.dart';

class DrawerItem {
  final String label;
  final IconData icon;
  final WidgetBuilder builder;
  const DrawerItem(this.label, this.icon, this.builder);
}

/// Liste complète des sections de l'application, utilisée à la fois pour
/// le tiroir latéral et l'écran "Plus" — reprend la même organisation que
/// la version ordinateur et la version web mobile.
final List<DrawerItem> drawerItems = [
  DrawerItem('Produits & Services', Icons.checkroom_outlined, (_) => const PlaceholderScreen(title: 'Produits & Services')),
  DrawerItem('Devis', Icons.description_outlined, (_) => const PlaceholderScreen(title: 'Devis')),
  DrawerItem('Paiements', Icons.credit_card_outlined, (_) => const PlaceholderScreen(title: 'Paiements')),
  DrawerItem('Dépenses', Icons.account_balance_wallet_outlined, (_) => const PlaceholderScreen(title: 'Dépenses')),
  DrawerItem('Fournisseurs', Icons.local_shipping_outlined, (_) => const PlaceholderScreen(title: 'Fournisseurs')),
  DrawerItem('Stock & Matières', Icons.inventory_2_outlined, (_) => const PlaceholderScreen(title: 'Stock & Matières')),
  DrawerItem('Employés', Icons.manage_accounts_outlined, (_) => const PlaceholderScreen(title: 'Employés')),
  DrawerItem('Rapports & Statistiques', Icons.bar_chart_rounded, (_) => const PlaceholderScreen(title: 'Rapports')),
  DrawerItem('Corbeille', Icons.delete_outline, (_) => const PlaceholderScreen(title: 'Corbeille')),
  DrawerItem('Paramètres', Icons.settings_outlined, (_) => const PlaceholderScreen(title: 'Paramètres')),
];

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static final List<Widget> _tabs = [
    const DashboardScreen(),
    const CommandesScreen(),
    const ClientsScreen(),
    const FacturesScreen(),
    const _PlusGrid(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const _AppDrawer(),
      appBar: AppBar(
        leadingWidth: 44,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu, size: 20),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Row(
          children: [
            Container(
              width: 28, height: 28,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: AppColors.deepGreen.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
              child: Image.asset('assets/images/logo_icon.png'),
            ),
            const SizedBox(width: 10),
            Text(BusinessInfo.nom, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
          ],
        ),
      ),
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: 'Accueil'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag_outlined), label: 'Commandes'),
          BottomNavigationBarItem(icon: Icon(Icons.people_outline), label: 'Clients'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), label: 'Factures'),
          BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: 'Plus'),
        ],
      ),
    );
  }
}

class _AppDrawer extends StatelessWidget {
  const _AppDrawer();

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF0F0F12),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Row(
                children: [
                  SizedBox(width: 42, height: 42, child: Image.asset('assets/images/logo.png')),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(BusinessInfo.nom, style: Theme.of(context).textTheme.titleLarge),
                      Text(BusinessInfo.slogan.toUpperCase(),
                          style: const TextStyle(color: AppColors.gold, fontSize: 9, letterSpacing: 1.2)),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  const _DrawerSectionLabel('Menu principal'),
                  _DrawerTile(icon: Icons.grid_view_rounded, label: 'Tableau de bord', onTap: () => Navigator.pop(context)),
                  _DrawerTile(icon: Icons.shopping_bag_outlined, label: 'Commandes', onTap: () => Navigator.pop(context)),
                  _DrawerTile(icon: Icons.people_outline, label: 'Clients', onTap: () => Navigator.pop(context)),
                  for (final item in drawerItems)
                    _DrawerTile(
                      icon: item.icon,
                      label: item.label,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: item.builder));
                      },
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Champions Style — v$appVersion',
                  style: const TextStyle(color: AppColors.textFaint, fontSize: 10)),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerSectionLabel extends StatelessWidget {
  final String label;
  const _DrawerSectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Text(label.toUpperCase(),
          style: const TextStyle(color: AppColors.textFaint, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.1)),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _DrawerTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Icon(icon, size: 18, color: AppColors.textMuted),
      title: Text(label, style: const TextStyle(fontSize: 14, color: Colors.white)),
      onTap: onTap,
    );
  }
}

/// Grille "Plus" — accessible depuis le 5ᵉ onglet de la barre du bas,
/// donne accès à tous les autres modules de l'application.
class _PlusGrid extends StatelessWidget {
  const _PlusGrid();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ScreenHeaderInline(),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  for (final item in drawerItems)
                    _PlusTile(
                      icon: item.icon,
                      label: item.label,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: item.builder)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ScreenHeaderInline extends StatelessWidget {
  const ScreenHeaderInline({super.key});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('TOUT LE RESTE', style: TextStyle(color: AppColors.gold, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
          const SizedBox(height: 3),
          Text('Plus', style: Theme.of(context).textTheme.headlineMedium),
        ],
      ),
    );
  }
}

class _PlusTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _PlusTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: AppColors.gold),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
