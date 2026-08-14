import 'package:flutter/material.dart';
import '../data/repository.dart';
import '../models/commande.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import 'clients_screen.dart';
import 'commandes_screen.dart';
import 'factures_screen.dart';
import 'produits_screen.dart';
import 'placeholder_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Commande> _commandes = [];
  int _totalClients = 0;
  double _totalPaiements = 0;
  double _totalDepenses = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final commandes = await CommandeRepository().all();
    final clients = await ClientRepository().all();
    final paiements = await PaiementRepository().all();
    final depenses = await DepenseRepository().all();
    if (!mounted) return;
    setState(() {
      _commandes = commandes;
      _totalClients = clients.length;
      _totalPaiements = paiements.fold(0, (s, p) => s + p.montant);
      _totalDepenses = depenses.fold(0.0, (s, d) => s + d.montantVerse);
      _loading = false;
    });
  }

  void _push(Widget screen) => Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppColors.gold));

    final enCours = _commandes.where((c) => c.statut != 'Livrée').length;
    final benefice = _totalPaiements - _totalDepenses;
    final enBenefice = benefice >= 0;

    return RefreshIndicator(
      color: AppColors.gold,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const ScreenHeader(eyebrow: "Vue d'ensemble", title: 'Tableau de bord'),
          SizedBox(
            height: 106,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _KpiCard(label: 'Commandes en cours', value: '$enCours', icon: Icons.shopping_bag_outlined, color: AppColors.blue),
                const SizedBox(width: 12),
                _KpiCard(label: 'Clients enregistrés', value: '$_totalClients', icon: Icons.people_outline, color: AppColors.purple),
                const SizedBox(width: 12),
                _KpiCard(label: 'Paiements reçus', value: fmtFcfa(_totalPaiements), icon: Icons.account_balance_wallet_outlined, color: AppColors.gold),
                const SizedBox(width: 12),
                _KpiCard(
                  label: 'Bénéfice (total)',
                  value: fmtFcfa(benefice.abs()),
                  icon: Icons.bar_chart_rounded,
                  color: enBenefice ? AppColors.deepGreen : AppColors.rose,
                  badge: enBenefice ? '🟢' : '🔴',
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          Text('Actions rapides', style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.85,
            children: [
              _QuickAction(label: 'Commande', icon: Icons.shopping_bag_outlined, onTap: () => _push(const CommandesScreen())),
              _QuickAction(label: 'Client', icon: Icons.people_outline, onTap: () => _push(const ClientsScreen())),
              _QuickAction(label: 'Facture', icon: Icons.receipt_long_outlined, onTap: () => _push(const FacturesScreen())),
              _QuickAction(label: 'Devis', icon: Icons.description_outlined, onTap: () => _push(const PlaceholderScreen(title: 'Devis'))),
              _QuickAction(label: 'Paiement', icon: Icons.credit_card_outlined, onTap: () => _push(const PlaceholderScreen(title: 'Paiements'))),
              _QuickAction(label: 'Dépense', icon: Icons.account_balance_wallet_outlined, onTap: () => _push(const PlaceholderScreen(title: 'Dépenses'))),
              _QuickAction(label: 'Produit', icon: Icons.checkroom_outlined, onTap: () => _push(const ProduitsScreen())),
              _QuickAction(label: 'Rapport', icon: Icons.bar_chart_rounded, onTap: () => _push(const PlaceholderScreen(title: 'Rapports'))),
            ],
          ),
          const SizedBox(height: 26),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Commandes récentes', style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w600, fontSize: 16)),
              GestureDetector(
                onTap: () => _push(const CommandesScreen()),
                child: const Text('Voir tout', style: TextStyle(color: AppColors.gold, fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_commandes.isEmpty)
            const EmptyState(icon: Icons.shopping_bag_outlined, text: 'Aucune commande pour le moment.')
          else
            ..._commandes.take(5).map(
              (c) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppCard(
                  child: Row(
                    children: [
                      AppAvatar(name: c.client, size: 40),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c.client, style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w500, fontSize: 15), overflow: TextOverflow.ellipsis),
                            Text('${c.id} · ${c.modele}', style: TextStyle(color: context.textFaint, fontSize: 12)),
                          ],
                        ),
                      ),
                      StatutBadge(statut: c.statut),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? badge;

  const _KpiCard({required this.label, required this.value, required this.icon, required this.color, this.badge});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 168,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, size: 17, color: color),
              ),
              if (badge != null) Text(badge!, style: const TextStyle(fontSize: 13)),
            ],
          ),
          const Spacer(),
          Text(value, style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w700, fontSize: 17), overflow: TextOverflow.ellipsis, maxLines: 1),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(color: context.textFaint, fontSize: 11.5), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _QuickAction({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.cardBorder),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: AppColors.gold),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(fontSize: 11.5, color: context.textMuted, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
