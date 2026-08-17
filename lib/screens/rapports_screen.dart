import 'package:flutter/material.dart';
import '../data/repository.dart';
import '../models/paiement.dart';
import '../models/depense.dart';
import '../models/boutique.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import '../widgets/mini_charts.dart';

const List<String> _moisAbbrRapports = ['janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin', 'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'];

DateTime? _parseFrDateRapports(String s) {
  final parts = s.trim().split(RegExp(r'\s+'));
  if (parts.length != 3) return null;
  final day = int.tryParse(parts[0]);
  final monthIdx = _moisAbbrRapports.indexOf(parts[1]);
  final year = int.tryParse(parts[2]);
  if (day == null || monthIdx == -1 || year == null) return null;
  return DateTime(year, monthIdx + 1, day);
}

String _fmtDateRapports(DateTime d) => '${d.day.toString().padLeft(2, '0')} ${_moisAbbrRapports[d.month - 1]} ${d.year}';

class RapportsScreen extends StatefulWidget {
  const RapportsScreen({super.key});

  @override
  State<RapportsScreen> createState() => _RapportsScreenState();
}

class _RapportsScreenState extends State<RapportsScreen> {
  bool _loading = true;
  List<Paiement> _paiements = [];
  List<Depense> _depenses = [];
  List<VenteBoutique> _ventesBoutique = [];

  DateTime? _dateDebut;
  DateTime? _dateFin;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final paiements = await PaiementRepository().all();
    final depenses = await DepenseRepository().all();
    final ventesBoutique = await VenteBoutiqueRepository().all();
    if (!mounted) return;
    setState(() {
      _paiements = paiements;
      _depenses = depenses;
      _ventesBoutique = ventesBoutique;
      _loading = false;
    });
  }

  bool _dansLaPeriode(DateTime? d) {
    if (d == null) return false;
    if (_dateDebut != null && d.isBefore(_dateDebut!)) return false;
    if (_dateFin != null && d.isAfter(_dateFin!)) return false;
    return true;
  }

  bool get _filtreActif => _dateDebut != null || _dateFin != null;

  List<T> _filtrerParDate<T>(List<T> items, String Function(T) dateDe) {
    if (!_filtreActif) return items;
    return items.where((it) => _dansLaPeriode(_parseFrDateRapports(dateDe(it)))).toList();
  }

  List<LineChartPoint> _tendance(List<double> montants) {
    final points = <LineChartPoint>[];
    const chunk = 5;
    for (int i = 0; i < montants.length; i += chunk) {
      final slice = montants.skip(i).take(chunk);
      points.add(LineChartPoint('', slice.fold<double>(0, (s, v) => s + v)));
    }
    if (points.isEmpty) points.add(const LineChartPoint('', 0));
    return points.reversed.toList();
  }

  Future<void> _choisirDate({required bool debut}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: (debut ? _dateDebut : _dateFin) ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
    );
    if (picked == null) return;
    setState(() {
      if (debut) {
        _dateDebut = DateTime(picked.year, picked.month, picked.day);
      } else {
        _dateFin = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final paiementsFiltres = _filtrerParDate(_paiements, (p) => p.date);
    final depensesFiltrees = _filtrerParDate(_depenses, (d) => d.date);
    final ventesFiltrees = _filtrerParDate(_ventesBoutique, (v) => v.date);

    final totalRecettes = paiementsFiltres.fold<double>(0, (s, p) => s + p.montant);
    final totalDepenses = depensesFiltrees.fold<double>(0, (s, d) => s + d.montantVerse);
    final totalBoutique = ventesFiltrees.fold<double>(0, (s, v) => s + v.montant);
    final benefice = totalRecettes - totalDepenses;

    final tendanceCouture = _tendance([for (final p in paiementsFiltres) p.montant]);
    final tendanceBoutique = _tendance([for (final v in ventesFiltrees) v.montant]);

    return Scaffold(
      appBar: AppBar(title: const Text('Rapports & Statistiques')),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text('PÉRIODE', style: TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.1)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _choisirDate(debut: true),
                          style: OutlinedButton.styleFrom(side: BorderSide(color: context.cardBorder), padding: const EdgeInsets.symmetric(vertical: 12)),
                          child: Text(_dateDebut != null ? 'Du ${_fmtDateRapports(_dateDebut!)}' : 'Du…', style: TextStyle(color: context.textPrimary, fontSize: 12.5)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _choisirDate(debut: false),
                          style: OutlinedButton.styleFrom(side: BorderSide(color: context.cardBorder), padding: const EdgeInsets.symmetric(vertical: 12)),
                          child: Text(_dateFin != null ? 'Au ${_fmtDateRapports(_dateFin!)}' : 'Au…', style: TextStyle(color: context.textPrimary, fontSize: 12.5)),
                        ),
                      ),
                    ],
                  ),
                  if (_filtreActif) ...[
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => setState(() { _dateDebut = null; _dateFin = null; }),
                      child: const Text('Réinitialiser la période', style: TextStyle(color: AppColors.rose, fontSize: 12.5, fontWeight: FontWeight.w600)),
                    ),
                  ],
                  const SizedBox(height: 22),
                  AppCard(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Rentrées d'argent", style: TextStyle(color: context.textFaint, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text(fmtFcfa(totalRecettes), style: TextStyle(color: context.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
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
                            Text(fmtFcfa(totalDepenses), style: TextStyle(color: context.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
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
                  const SizedBox(height: 12),
                  AppCard(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Ventes en boutique', style: TextStyle(color: context.textFaint, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text(fmtFcfa(totalBoutique), style: TextStyle(color: context.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
                          ],
                        ),
                        const Icon(Icons.storefront_outlined, color: AppColors.pink, size: 26),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text('Tendance — Couture', style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 12),
                  AppCard(child: MiniLineChart(points: tendanceCouture, color: AppColors.gold, height: 120)),
                  const SizedBox(height: 22),
                  Text('Tendance — Boutique', style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 12),
                  AppCard(child: MiniLineChart(points: tendanceBoutique, color: AppColors.pink, height: 120)),
                ],
              ),
      ),
    );
  }
}
