import 'package:flutter/material.dart';
import '../data/repository.dart';
import '../models/commande.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _commandeRepo = CommandeRepository();
  final _clientRepo = ClientRepository();

  List<Commande> _commandes = [];
  int _totalClients = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final commandes = await _commandeRepo.all();
    final clients = await _clientRepo.all();
    if (!mounted) return;
    setState(() {
      _commandes = commandes;
      _totalClients = clients.length;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppColors.gold));

    final enCours = _commandes.where((c) => c.statut != 'Livrée').length;
    final totalMontant = _commandes.fold<double>(0, (s, c) => s + c.montant);

    return RefreshIndicator(
      color: AppColors.gold,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const ScreenHeader(eyebrow: "Vue d'ensemble", title: 'Tableau de bord'),
          SizedBox(
            height: 96,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _KpiCard(label: 'Commandes en cours', value: '$enCours', icon: Icons.shopping_bag_outlined, color: AppColors.blue),
                const SizedBox(width: 12),
                _KpiCard(label: 'Clients enregistrés', value: '$_totalClients', icon: Icons.people_outline, color: AppColors.deepGreen),
                const SizedBox(width: 12),
                _KpiCard(label: 'Valeur commandes', value: fmtFcfa(totalMontant), icon: Icons.bar_chart_rounded, color: AppColors.gold),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('Commandes récentes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
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
                      AppAvatar(name: c.client, size: 36),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c.client, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14), overflow: TextOverflow.ellipsis),
                            Text('${c.id} · ${c.modele}', style: const TextStyle(color: AppColors.textFaint, fontSize: 11)),
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

  const _KpiCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 155,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: color.withOpacity(0.13), borderRadius: BorderRadius.circular(9)),
            child: Icon(icon, size: 16, color: color),
          ),
          const Spacer(),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16), overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: AppColors.textFaint, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
