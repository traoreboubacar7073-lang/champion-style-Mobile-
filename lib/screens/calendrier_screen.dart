import 'package:flutter/material.dart';
import '../data/repository.dart';
import '../models/commande.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

const List<String> _moisComplets = [
  'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
  'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre',
];
const List<String> _joursAbbr = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
const List<String> _moisAbbrCal = ['janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin', 'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'];

DateTime? _parseFrDateCal(String s) {
  final parts = s.trim().split(RegExp(r'\s+'));
  if (parts.length != 3) return null;
  final day = int.tryParse(parts[0]);
  final monthIdx = _moisAbbrCal.indexOf(parts[1]);
  final year = int.tryParse(parts[2]);
  if (day == null || monthIdx == -1 || year == null) return null;
  return DateTime(year, monthIdx + 1, day);
}

class CalendrierScreen extends StatefulWidget {
  const CalendrierScreen({super.key});

  @override
  State<CalendrierScreen> createState() => _CalendrierScreenState();
}

class _CalendrierScreenState extends State<CalendrierScreen> {
  List<Commande> _commandes = [];
  bool _loading = true;
  DateTime _moisAffiche = DateTime(DateTime.now().year, DateTime.now().month, 1);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final commandes = await CommandeRepository().all();
    if (!mounted) return;
    setState(() {
      _commandes = commandes;
      _loading = false;
    });
  }

  List<Commande> _livraisonsLe(DateTime jour) {
    return _commandes.where((c) {
      final d = _parseFrDateCal(c.livraison);
      return d != null && d.year == jour.year && d.month == jour.month && d.day == jour.day;
    }).toList();
  }

  /// Une livraison dont la commande est passée au statut "Livrée" est
  /// considérée comme validée — elle s'affiche en vert sur le calendrier
  /// au lieu de la couleur "à venir", pour distinguer en un coup d'œil ce
  /// qui reste à faire de ce qui est déjà terminé.
  bool _livraisonValideeLe(DateTime jour, List<Commande> livraisons) {
    return livraisons.isNotEmpty && livraisons.every((c) => c.statut == 'Livrée');
  }

  List<Commande> _essayagesLe(DateTime jour) {
    return _commandes.where((c) {
      if (c.dateEssayage.isEmpty) return false;
      final d = _parseFrDateCal(c.dateEssayage);
      return d != null && d.year == jour.year && d.month == jour.month && d.day == jour.day;
    }).toList();
  }

  void _ouvrirJour(DateTime jour, List<Commande> livraisons, List<Commande> essayages) {
    showAppBottomSheet(
      context,
      title: '${jour.day} ${_moisComplets[jour.month - 1]} ${jour.year}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (livraisons.isEmpty && essayages.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text('Aucun rendez-vous ce jour-là.', style: TextStyle(color: context.textFaint, fontSize: 13)),
            ),
          if (livraisons.isNotEmpty) ...[
            Text('LIVRAISONS', style: TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.6)),
            const SizedBox(height: 8),
            for (final c in livraisons)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: context.cardBg, borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    children: [
                      Icon(Icons.local_shipping_outlined, size: 16, color: c.statut == 'Livrée' ? AppColors.deepGreen : AppColors.gold),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c.client, style: TextStyle(color: context.textPrimary, fontSize: 13.5, fontWeight: FontWeight.w500)),
                            Text('${c.id} · ${c.modele}', style: TextStyle(color: context.textFaint, fontSize: 11.5)),
                          ],
                        ),
                      ),
                      StatutBadge(statut: c.statut),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 10),
          ],
          if (essayages.isNotEmpty) ...[
            Text('ESSAYAGES', style: TextStyle(color: AppColors.purple, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.6)),
            const SizedBox(height: 8),
            for (final c in essayages)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: context.cardBg, borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    children: [
                      const Icon(Icons.event_outlined, size: 16, color: AppColors.purple),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c.client, style: TextStyle(color: context.textPrimary, fontSize: 13.5, fontWeight: FontWeight.w500)),
                            Text('${c.id} · ${c.modele}', style: TextStyle(color: context.textFaint, fontSize: 11.5)),
                          ],
                        ),
                      ),
                      StatutBadge(statut: c.statut),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final premierJourMois = DateTime(_moisAffiche.year, _moisAffiche.month, 1);
    final joursDansMois = DateTime(_moisAffiche.year, _moisAffiche.month + 1, 0).day;
    // Décalage pour commencer la grille un lundi (1 = lundi ... 7 = dimanche).
    final decalage = premierJourMois.weekday - 1;
    final aujourdHui = DateTime.now();

    return Scaffold(
      appBar: AppBar(title: const Text('Calendrier')),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () => setState(() => _moisAffiche = DateTime(_moisAffiche.year, _moisAffiche.month - 1, 1)),
                      ),
                      Text('${_moisComplets[_moisAffiche.month - 1]} ${_moisAffiche.year}',
                          style: TextStyle(color: context.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () => setState(() => _moisAffiche = DateTime(_moisAffiche.year, _moisAffiche.month + 1, 1)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      for (final j in _joursAbbr)
                        Expanded(child: Center(child: Text(j, style: TextStyle(color: context.textFaint, fontSize: 11, fontWeight: FontWeight.w600)))),
                    ],
                  ),
                  const SizedBox(height: 6),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisSpacing: 4, crossAxisSpacing: 4),
                    itemCount: decalage + joursDansMois,
                    itemBuilder: (ctx, i) {
                      if (i < decalage) return const SizedBox.shrink();
                      final jourNum = i - decalage + 1;
                      final jour = DateTime(_moisAffiche.year, _moisAffiche.month, jourNum);
                      final livraisons = _livraisonsLe(jour);
                      final essayages = _essayagesLe(jour);
                      final estAujourdhui = jour.year == aujourdHui.year && jour.month == aujourdHui.month && jour.day == aujourdHui.day;
                      return InkWell(
                        onTap: () => _ouvrirJour(jour, livraisons, essayages),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          decoration: BoxDecoration(
                            color: estAujourdhui ? AppColors.gold.withOpacity(0.15) : context.cardBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: estAujourdhui ? AppColors.gold : context.cardBorder),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('$jourNum', style: TextStyle(color: estAujourdhui ? AppColors.gold : context.textPrimary, fontSize: 12.5, fontWeight: estAujourdhui ? FontWeight.w700 : FontWeight.w400)),
                              if (livraisons.isNotEmpty || essayages.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (livraisons.isNotEmpty)
                                        Container(
                                          width: 5, height: 5, margin: const EdgeInsets.symmetric(horizontal: 1),
                                          decoration: BoxDecoration(color: _livraisonValideeLe(jour, livraisons) ? AppColors.deepGreen : AppColors.gold, shape: BoxShape.circle),
                                        ),
                                      if (essayages.isNotEmpty) Container(width: 5, height: 5, margin: const EdgeInsets.symmetric(horizontal: 1), decoration: const BoxDecoration(color: AppColors.purple, shape: BoxShape.circle)),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.gold, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Text('À livrer', style: TextStyle(color: context.textFaint, fontSize: 12)),
                      const SizedBox(width: 14),
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.deepGreen, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Text('Livrée', style: TextStyle(color: context.textFaint, fontSize: 12)),
                      const SizedBox(width: 14),
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.purple, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Text('Essayage', style: TextStyle(color: context.textFaint, fontSize: 12)),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}
