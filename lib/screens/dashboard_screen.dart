import 'package:flutter/material.dart';
import '../data/repository.dart';
import '../models/commande.dart';
import '../models/facture.dart';
import '../models/client.dart';
import '../models/modele.dart';
import '../models/stock.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import '../widgets/mini_charts.dart';
import 'clients_screen.dart';
import 'commandes_screen.dart';
import 'factures_screen.dart';
import 'produits_screen.dart';
import 'stock_screen.dart';
import 'rapports_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _ActiviteItem {
  final IconData icon;
  final Color color;
  final String titre;
  final String sousTitre;
  final VoidCallback onTap;
  _ActiviteItem({required this.icon, required this.color, required this.titre, required this.sousTitre, required this.onTap});
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Commande> _commandes = [];
  List<Client> _clients = [];
  List<Facture> _factures = [];
  List<Modele> _modeles = [];
  List<StockItem> _stock = [];
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
    final factures = await FactureRepository().all();
    final modeles = await ModeleRepository().all();
    final stock = await StockRepository().all();
    final paiements = await PaiementRepository().all();
    final depenses = await DepenseRepository().all();
    if (!mounted) return;
    setState(() {
      _commandes = commandes;
      _clients = clients;
      _factures = factures;
      _modeles = modeles;
      _stock = stock;
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
    final stockBas = _stock.where((s) => s.bas).toList();

    final Map<String, int> parStatut = {};
    for (final c in _commandes) {
      parStatut[c.statut] = (parStatut[c.statut] ?? 0) + 1;
    }
    final segments = [
      for (final entry in parStatut.entries)
        DonutSegment(entry.key, entry.value.toDouble(), StatutColors.of(entry.key)),
    ];

    final Map<String, int> ventesParModele = {};
    for (final c in _commandes) {
      if (c.modele.isEmpty) continue;
      ventesParModele[c.modele] = (ventesParModele[c.modele] ?? 0) + 1;
    }
    final topProduits = ventesParModele.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    final activites = <_ActiviteItem>[
      if (_commandes.isNotEmpty)
        _ActiviteItem(
          icon: Icons.shopping_bag_outlined, color: AppColors.blue,
          titre: 'Commande ${_commandes.first.id} — ${_commandes.first.statut}',
          sousTitre: _commandes.first.client,
          onTap: () => _push(const CommandesScreen()),
        ),
      if (_factures.isNotEmpty)
        _ActiviteItem(
          icon: Icons.receipt_long_outlined, color: AppColors.deepGreen,
          titre: 'Facture ${_factures.first.id} créée',
          sousTitre: 'Pour ${_factures.first.client}',
          onTap: () => _push(const FacturesScreen()),
        ),
      if (_clients.isNotEmpty)
        _ActiviteItem(
          icon: Icons.person_outline, color: AppColors.purple,
          titre: 'Client récent',
          sousTitre: _clients.first.nom,
          onTap: () => _push(const ClientsScreen()),
        ),
    ];

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
                _KpiCard(label: 'Commandes en cours', value: '$enCours', icon: Icons.shopping_bag_outlined, color: AppColors.blue, onTap: () => _push(const CommandesScreen())),
                const SizedBox(width: 12),
                _KpiCard(label: 'Clients enregistrés', value: '${_clients.length}', icon: Icons.people_outline, color: AppColors.purple, onTap: () => _push(const ClientsScreen())),
                const SizedBox(width: 12),
                _KpiCard(label: 'Paiements reçus', value: fmtFcfa(_totalPaiements), icon: Icons.account_balance_wallet_outlined, color: AppColors.gold, onTap: () => _push(const RapportsScreen())),
                const SizedBox(width: 12),
                _KpiCard(
                  label: 'Bénéfice (total)', value: fmtFcfa(benefice.abs()), icon: Icons.bar_chart_rounded,
                  color: enBenefice ? AppColors.deepGreen : AppColors.rose, badge: enBenefice ? '🟢' : '🔴',
                  onTap: () => _push(const RapportsScreen()),
                ),
                const SizedBox(width: 12),
                _KpiCard(label: 'Stock à surveiller', value: '${stockBas.length}', icon: Icons.warning_amber_rounded, color: AppColors.rose, onTap: () => _push(const StockScreen())),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _SectionTitle(title: "Vue d'ensemble", onVoirTout: () => _push(const RapportsScreen())),
          const SizedBox(height: 10),
          AppCard(
            onTap: () => _push(const RapportsScreen()),
            child: MiniLineChart(points: [LineChartPoint('', _totalPaiements)], color: AppColors.gold, height: 90),
          ),
          const SizedBox(height: 22),

          _SectionTitle(title: 'Répartition des commandes', onVoirTout: () => _push(const CommandesScreen())),
          const SizedBox(height: 10),
          AppCard(
            onTap: () => _push(const CommandesScreen()),
            child: _commandes.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: Text('Aucune commande pour le moment.', style: TextStyle(color: context.textFaint, fontSize: 13))),
                  )
                : Row(
                    children: [
                      MiniDonutChart(segments: segments, centerLabel: '${_commandes.length}', centerSubLabel: 'TOTAL'),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final entry in parStatut.entries)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 3),
                                child: Row(
                                  children: [
                                    Container(width: 8, height: 8, decoration: BoxDecoration(color: StatutColors.of(entry.key), shape: BoxShape.circle)),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(entry.key, style: TextStyle(color: context.textMuted, fontSize: 12.5), overflow: TextOverflow.ellipsis)),
                                    Text('${entry.value}', style: TextStyle(color: context.textPrimary, fontSize: 12.5, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 22),

          _SectionTitle(title: 'Commandes récentes', onVoirTout: () => _push(const CommandesScreen())),
          const SizedBox(height: 10),
          if (_commandes.isEmpty)
            const EmptyState(icon: Icons.shopping_bag_outlined, text: 'Aucune commande pour le moment.')
          else
            ..._commandes.take(4).map(
              (c) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppCard(
                  onTap: () => _push(const CommandesScreen()),
                  child: Row(
                    children: [
                      AppAvatar(name: c.client, size: 38),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c.client, style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w500, fontSize: 14.5), overflow: TextOverflow.ellipsis),
                            Text('${c.id} · ${c.modele}', style: TextStyle(color: context.textFaint, fontSize: 11.5)),
                          ],
                        ),
                      ),
                      StatutBadge(statut: c.statut),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 22),

          _SectionTitle(title: 'Top Produits & Services', onVoirTout: () => _push(const ProduitsScreen())),
          const SizedBox(height: 10),
          if (topProduits.isEmpty)
            const EmptyState(icon: Icons.checkroom_outlined, text: 'Aucun produit vendu pour le moment.')
          else
            AppCard(
              onTap: () => _push(const ProduitsScreen()),
              child: Column(
                children: [
                  for (int i = 0; i < topProduits.length && i < 4; i++)
                    Padding(
                      padding: EdgeInsets.only(bottom: i == topProduits.length - 1 || i == 3 ? 0 : 10),
                      child: Row(
                        children: [
                          Expanded(child: Text(topProduits[i].key, style: TextStyle(color: context.textPrimary, fontSize: 13.5), overflow: TextOverflow.ellipsis)),
                          Text('${topProduits[i].value} vente${topProduits[i].value > 1 ? "s" : ""}', style: TextStyle(color: context.textFaint, fontSize: 12)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 22),

          _SectionTitle(title: 'Stock faible', onVoirTout: () => _push(const StockScreen())),
          const SizedBox(height: 10),
          if (stockBas.isEmpty)
            AppCard(
              onTap: () => _push(const StockScreen()),
              child: Text('Tous les articles sont à un niveau suffisant.', style: TextStyle(color: context.textFaint, fontSize: 13)),
            )
          else
            AppCard(
              onTap: () => _push(const StockScreen()),
              child: Column(
                children: [
                  for (int i = 0; i < stockBas.length && i < 4; i++)
                    Padding(
                      padding: EdgeInsets.only(bottom: i == stockBas.length - 1 || i == 3 ? 0 : 10),
                      child: Row(
                        children: [
                          Expanded(child: Text(stockBas[i].nom, style: TextStyle(color: context.textPrimary, fontSize: 13.5), overflow: TextOverflow.ellipsis)),
                          Text('${stockBas[i].qte.toStringAsFixed(0)} / ${stockBas[i].seuil.toStringAsFixed(0)} ${stockBas[i].unite}',
                              style: const TextStyle(color: AppColors.rose, fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 22),

          Text('Activités récentes', style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w600, fontSize: 15)),
          const SizedBox(height: 10),
          if (activites.isEmpty)
            const EmptyState(icon: Icons.history, text: 'Aucune activité pour le moment.')
          else
            ...activites.map(
              (a) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppCard(
                  onTap: a.onTap,
                  child: Row(
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(color: a.color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                        child: Icon(a.icon, size: 17, color: a.color),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(a.titre, style: TextStyle(color: context.textPrimary, fontSize: 13.5, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                            Text(a.sousTitre, style: TextStyle(color: context.textFaint, fontSize: 12), overflow: TextOverflow.ellipsis),
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
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final VoidCallback onVoirTout;
  const _SectionTitle({required this.title, required this.onVoirTout});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w600, fontSize: 15)),
        GestureDetector(
          onTap: onVoirTout,
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Voir tout', style: TextStyle(color: AppColors.gold, fontSize: 12.5, fontWeight: FontWeight.w600)),
              Icon(Icons.chevron_right, color: AppColors.gold, size: 16),
            ],
          ),
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? badge;
  final VoidCallback onTap;

  const _KpiCard({required this.label, required this.value, required this.icon, required this.color, this.badge, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
      ),
    );
  }
}
