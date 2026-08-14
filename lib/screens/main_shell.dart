import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/business_info.dart';
import '../widgets/shared_widgets.dart';
import 'dashboard_screen.dart';
import 'clients_screen.dart';
import 'commandes_screen.dart';
import 'factures_screen.dart';
import 'parametres_screen.dart';
import 'search_screen.dart';
import 'produits_screen.dart';
import 'stock_screen.dart';
import 'rapports_screen.dart';
import 'devis_screen.dart';
import 'paiements_screen.dart';
import 'depenses_screen.dart';
import 'fournisseurs_screen.dart';
import 'employes_screen.dart';
import 'corbeille_screen.dart';
import 'calendrier_screen.dart';
import '../services/notifications_service.dart';

class DrawerItem {
  final String label;
  final IconData icon;
  final Color color;
  final WidgetBuilder builder;
  const DrawerItem(this.label, this.icon, this.color, this.builder);
}

/// Liste complète des sections de l'application, utilisée à la fois pour
/// le tiroir latéral et l'écran "Plus" — reprend la même organisation que
/// la version ordinateur et la version web mobile. Chaque section a sa
/// propre couleur, pour que les tuiles du menu "Plus" soient visuellement
/// distinctes d'un coup d'œil.
final List<DrawerItem> drawerItems = [
  DrawerItem('Produits & Services', Icons.checkroom_outlined, AppColors.gold, (_) => const ProduitsScreen()),
  DrawerItem('Devis', Icons.description_outlined, AppColors.blue, (_) => const DevisScreen()),
  DrawerItem('Calendrier', Icons.calendar_month_outlined, AppColors.purple, (_) => const CalendrierScreen()),
  DrawerItem('Paiements', Icons.credit_card_outlined, AppColors.deepGreen, (_) => const PaiementsScreen()),
  DrawerItem('Dépenses', Icons.account_balance_wallet_outlined, AppColors.rose, (_) => const DepensesScreen()),
  DrawerItem('Fournisseurs', Icons.local_shipping_outlined, AppColors.pink, (_) => const FournisseursScreen()),
  DrawerItem('Stock & Matières', Icons.inventory_2_outlined, AppColors.blue, (_) => const StockScreen()),
  DrawerItem('Employés', Icons.manage_accounts_outlined, AppColors.purple, (_) => const EmployesScreen()),
  DrawerItem('Rapports & Statistiques', Icons.bar_chart_rounded, AppColors.gold, (_) => const RapportsScreen()),
  DrawerItem('Corbeille', Icons.delete_outline, AppColors.textFaint, (_) => const CorbeilleScreen()),
  DrawerItem('Paramètres', Icons.settings_outlined, AppColors.textFaint, (_) => const ParametresScreen()),
];

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  void _selectTab(int i) => setState(() => _index = i);

  // Construit l'écran actif à chaque changement d'onglet — contrairement à
  // un IndexedStack (qui garde tous les onglets figés en mémoire dès le
  // premier affichage), ceci force chaque écran à se recharger avec les
  // données les plus récentes à chaque fois qu'on y retourne. C'est ce qui
  // garantit qu'un client ajouté apparaît bien dans le formulaire de
  // commande, qu'une commande facturée apparaît dans les factures, etc.
  Widget _currentTab() {
    switch (_index) {
      case 0: return const DashboardScreen();
      case 1: return const CommandesScreen();
      case 2: return const ClientsScreen();
      case 3: return const FacturesScreen();
      default: return const _PlusGrid();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _AppDrawer(onSelectTab: _selectTab),
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
            Expanded(
              child: Text(BusinessInfo.nom, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: context.textPrimary), overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        actions: [
          _NotificationBell(onSelectTab: _selectTab),
          IconButton(
            icon: const Icon(Icons.search, size: 22),
            tooltip: 'Rechercher',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen())),
          ),
        ],
      ),
      body: _currentTab(),
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
  final void Function(int) onSelectTab;
  const _AppDrawer({required this.onSelectTab});

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
                  _DrawerTile(icon: Icons.grid_view_rounded, label: 'Tableau de bord', onTap: () { Navigator.pop(context); onSelectTab(0); }),
                  _DrawerTile(icon: Icons.shopping_bag_outlined, label: 'Commandes', onTap: () { Navigator.pop(context); onSelectTab(1); }),
                  _DrawerTile(icon: Icons.people_outline, label: 'Clients', onTap: () { Navigator.pop(context); onSelectTab(2); }),
                  _DrawerTile(icon: Icons.receipt_long_outlined, label: 'Factures', onTap: () { Navigator.pop(context); onSelectTab(3); }),
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
class _NotificationBell extends StatefulWidget {
  final void Function(int) onSelectTab;
  const _NotificationBell({required this.onSelectTab});

  @override
  State<_NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<_NotificationBell> {
  List<AlertItem> _alerts = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final alerts = await computeAlerts();
    if (!mounted) return;
    setState(() {
      _alerts = alerts;
      _loaded = true;
    });
  }

  void _openPanel() async {
    await _load();
    if (!mounted) return;
    await showAppBottomSheet(
      context,
      title: 'Notifications',
      child: _alerts.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('Rien à signaler pour le moment.', style: TextStyle(color: AppColors.textFaint, fontSize: 13))),
            )
          : Column(
              children: [
                for (final a in _alerts)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).pop();
                        final index = {'commandes': 1, 'factures': 3}[a.cible];
                        if (index != null) {
                          widget.onSelectTab(index);
                        } else {
                          Navigator.push(context, MaterialPageRoute(builder: (_) {
                            if (a.cible == 'stock') return const StockScreen();
                            if (a.cible == 'depenses') return const DepensesScreen();
                            return const DashboardScreen();
                          }));
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: context.cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: context.cardBorder)),
                        child: Row(
                          children: [
                            Container(
                              width: 34, height: 34,
                              decoration: BoxDecoration(color: a.color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                              child: Icon(a.icon, size: 16, color: a.color),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(a.titre, style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                                  Text(a.detail, style: TextStyle(color: context.textFaint, fontSize: 11.5), overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_none_rounded, size: 22),
          tooltip: 'Notifications',
          onPressed: _openPanel,
        ),
        if (_loaded && _alerts.isNotEmpty)
          Positioned(
            right: 6, top: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(color: AppColors.rose, borderRadius: BorderRadius.circular(999)),
              constraints: const BoxConstraints(minWidth: 16),
              child: Text('${_alerts.length}', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
            ),
          ),
      ],
    );
  }
}

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
                      color: item.color,
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
  final Color color;
  final VoidCallback onTap;
  const _PlusTile({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.cardBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Icône géante, à peine visible, positionnée en fond pour que
            // chaque tuile ait une identité visuelle propre d'un coup d'œil
            // — sans dépendre d'images externes à charger.
            Positioned(
              right: -18,
              bottom: -18,
              child: Transform.rotate(
                angle: -0.35,
                child: Icon(icon, size: 92, color: color.withOpacity(context.isDark ? 0.16 : 0.13)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(color: color.withOpacity(0.16), borderRadius: BorderRadius.circular(10)),
                    child: Icon(icon, size: 18, color: color),
                  ),
                  const SizedBox(height: 10),
                  Text(label, style: TextStyle(fontSize: 14, color: context.textPrimary, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
