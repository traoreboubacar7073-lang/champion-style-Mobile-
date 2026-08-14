import 'package:flutter/material.dart';
import '../data/repository.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import '../widgets/mini_charts.dart';

class RapportsScreen extends StatefulWidget {
  const RapportsScreen({super.key});

  @override
  State<RapportsScreen> createState() => _RapportsScreenState();
}

class _RapportsScreenState extends State<RapportsScreen> {
  bool _loading = true;
  double _totalRecettes = 0;
  double _totalDepenses = 0;
  List<LineChartPoint> _mensuel = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final paiements = await PaiementRepository().all();
    final depenses = await DepenseRepository().all();

    final recettes = paiements.fold<double>(0, (s, p) => s + p.montant);
    final dep = depenses.fold<double>(0, (s, d) => s + d.montantVerse);

    // Regroupement très simple par lot d'insertion (approximation, faute
    // de date exploitable de façon fiable pour un tri précis) — donne une
    // tendance visuelle plutôt qu'une comptabilité exacte au jour près.
    final points = <LineChartPoint>[];
    const chunk = 5;
    for (int i = 0; i < paiements.length; i += chunk) {
      final slice = paiements.skip(i).take(chunk);
      final total = slice.fold<double>(0, (s, p) => s + p.montant);
      points.add(LineChartPoint('', total));
    }
    if (points.isEmpty) points.add(const LineChartPoint('', 0));

    if (!mounted) return;
    setState(() {
      _totalRecettes = recettes;
      _totalDepenses = dep;
      _mensuel = points.reversed.toList();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final benefice = _totalRecettes - _totalDepenses;
    return Scaffold(
      appBar: AppBar(title: const Text('Rapports & Statistiques')),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  AppCard(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Rentrées d'argent", style: TextStyle(color: context.textFaint, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text(fmtFcfa(_totalRecettes), style: TextStyle(color: context.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
                          ],
                        ),
                        const Icon(Icons.account_balance_wallet_outlined, color: AppColors.deepGreen, size: 26),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppCard(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Dépenses', style: TextStyle(color: context.textFaint, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text(fmtFcfa(_totalDepenses), style: TextStyle(color: context.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
                          ],
                        ),
                        const Icon(Icons.trending_up, color: AppColors.rose, size: 26),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppCard(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Bénéfice ${benefice >= 0 ? "🟢" : "🔴"}', style: TextStyle(color: context.textFaint, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text(fmtFcfa(benefice.abs()), style: TextStyle(color: benefice >= 0 ? AppColors.deepGreen : AppColors.rose, fontSize: 20, fontWeight: FontWeight.w700)),
                          ],
                        ),
                        Icon(Icons.bar_chart_rounded, color: benefice >= 0 ? AppColors.deepGreen : AppColors.rose, size: 26),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Tendance des rentrées', style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 12),
                  AppCard(child: MiniLineChart(points: _mensuel, color: AppColors.gold, height: 130)),
                ],
              ),
      ),
    );
  }
}
