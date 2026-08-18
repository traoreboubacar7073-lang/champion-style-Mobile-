import 'package:flutter/material.dart';
import '../data/repository.dart';
import '../models/depense.dart';
import '../models/fournisseur.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

const List<String> categoriesDepense = [
  'Loyer atelier', 'Électricité', 'Eau', 'Achat de tissus',
  'Fournitures (fils, boutons, fermetures...)', 'Entretien / réparation machines',
  'Transport / carburant', 'Salaires & paiements employés', 'Internet / téléphone',
  'Publicité / marketing', 'Emballages / étiquettes', 'Taxes / impôts', 'Autre',
];

const List<String> _moisAbbrDepenses = ['janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin', 'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'];

DateTime? _parseFrDateDepenses(String s) {
  final parts = s.trim().split(RegExp(r'\s+'));
  if (parts.length != 3) return null;
  final day = int.tryParse(parts[0]);
  final monthIdx = _moisAbbrDepenses.indexOf(parts[1]);
  final year = int.tryParse(parts[2]);
  if (day == null || monthIdx == -1 || year == null) return null;
  return DateTime(year, monthIdx + 1, day);
}

class _TotauxDepenses {
  final double semaine;
  final double mois;
  final double annee;
  const _TotauxDepenses(this.semaine, this.mois, this.annee);
}

_TotauxDepenses _computeTotauxDepenses(List<Depense> depenses) {
  final now = DateTime.now();
  final startOfWeek = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
  final startOfMonth = DateTime(now.year, now.month, 1);
  final startOfYear = DateTime(now.year, 1, 1);
  double semaine = 0, mois = 0, annee = 0;
  for (final d in depenses) {
    final date = _parseFrDateDepenses(d.date);
    if (date == null) continue;
    if (!date.isBefore(startOfYear)) annee += d.montantVerse;
    if (!date.isBefore(startOfMonth)) mois += d.montantVerse;
    if (!date.isBefore(startOfWeek)) semaine += d.montantVerse;
  }
  return _TotauxDepenses(semaine, mois, annee);
}

class DepensesScreen extends StatefulWidget {
  const DepensesScreen({super.key});

  @override
  State<DepensesScreen> createState() => _DepensesScreenState();
}

class _DepensesScreenState extends State<DepensesScreen> {
  final _repo = DepenseRepository();
  List<Depense> _depenses = [];
  List<Fournisseur> _fournisseurs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final depenses = await _repo.all();
    final fournisseurs = await FournisseurRepository().all();
    if (!mounted) return;
    setState(() {
      _depenses = depenses;
      _fournisseurs = fournisseurs;
      _loading = false;
    });
  }

  void _openAdd() async {
    await showAppBottomSheet(
      context,
      title: 'Nouvelle dépense',
      child: _DepenseForm(fournisseurs: _fournisseurs, onSaved: () { Navigator.of(context).pop(); _load(); }),
    );
  }

  void _openDetail(Depense d) async {
    await showAppBottomSheet(
      context,
      title: d.categorie,
      child: _DepenseDetail(
        depense: d,
        onRegler: () async {
          await _repo.reglerReliquat(d, d.reliquat);
          if (!mounted) return;
          Navigator.of(context).pop();
          _load();
        },
        onDelete: () async {
          final confirme = await confirmDelete(context, nom: d.categorie, typeElement: 'cette dépense');
          if (!confirme) return;
          await _repo.delete(d);
          if (!mounted) return;
          Navigator.of(context).pop();
          _load();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totaux = _computeTotauxDepenses(_depenses);
    return Scaffold(
      appBar: AppBar(title: const Text('Dépenses')),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      Expanded(child: _MiniTotalDepense(label: 'Semaine', value: fmtFcfa(totaux.semaine))),
                      const SizedBox(width: 8),
                      Expanded(child: _MiniTotalDepense(label: 'Mois', value: fmtFcfa(totaux.mois))),
                      const SizedBox(width: 8),
                      Expanded(child: _MiniTotalDepense(label: 'Année', value: fmtFcfa(totaux.annee))),
                    ],
                  ),
                  const SizedBox(height: 18),
                  if (_depenses.isEmpty)
                    const EmptyState(icon: Icons.account_balance_wallet_outlined, text: 'Aucune dépense enregistrée.')
                  else
                    ..._depenses.map((d) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: AppCard(
                        onTap: () => _openDetail(d),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(d.categorie, style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w500, fontSize: 15), overflow: TextOverflow.ellipsis),
                                      Text('${d.fournisseur.isNotEmpty ? "${d.fournisseur} · " : ""}${d.date}', style: TextStyle(color: context.textFaint, fontSize: 12)),
                                    ],
                                  ),
                                ),
                                Text('-${fmtFcfa(d.montant)}', style: const TextStyle(color: AppColors.rose, fontWeight: FontWeight.w700, fontSize: 13.5)),
                              ],
                            ),
                            if (d.reliquat > 0) ...[
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Reliquat', style: TextStyle(color: context.textFaint, fontSize: 11)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(color: AppColors.rose.withOpacity(0.15), borderRadius: BorderRadius.circular(999), border: Border.all(color: AppColors.rose.withOpacity(0.35))),
                                    child: Text(fmtFcfa(d.reliquat), style: const TextStyle(color: AppColors.rose, fontSize: 11, fontWeight: FontWeight.w700)),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAdd,
        backgroundColor: AppColors.gold,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }
}

class _DepenseForm extends StatefulWidget {
  final List<Fournisseur> fournisseurs;
  final VoidCallback onSaved;
  const _DepenseForm({required this.fournisseurs, required this.onSaved});

  @override
  State<_DepenseForm> createState() => _DepenseFormState();
}

class _DepenseFormState extends State<_DepenseForm> {
  final _repo = DepenseRepository();
  final _montantCtrl = TextEditingController();
  final _verseCtrl = TextEditingController();
  String? _fournisseur;
  String _categorie = 'Autre';
  bool _saving = false;

  Future<void> _save() async {
    final montant = double.tryParse(_montantCtrl.text) ?? 0;
    if (montant <= 0) return;
    setState(() => _saving = true);
    final saisieVerse = double.tryParse(_verseCtrl.text);
    await _repo.create(
      categorie: _categorie,
      fournisseur: _fournisseur ?? '',
      montant: montant,
      montantVerse: saisieVerse,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Catégorie *', style: TextStyle(color: context.textMuted, fontSize: 12)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _categorie,
          dropdownColor: AppColors.surface,
          isExpanded: true,
          items: [for (final c in categoriesDepense) DropdownMenuItem(value: c, child: Text(c, style: TextStyle(color: context.textPrimary), overflow: TextOverflow.ellipsis))],
          onChanged: (v) => setState(() => _categorie = v ?? 'Autre'),
        ),
        const SizedBox(height: 14),
        Text('Fournisseur (facultatif)', style: TextStyle(color: context.textMuted, fontSize: 12)),
        const SizedBox(height: 6),
        CatalogPickerField(
          options: [for (final f in widget.fournisseurs) f.nom],
          initialValue: _fournisseur,
          hintText: 'Choisir un fournisseur…',
          customHintText: 'Nom du fournisseur',
          onChanged: (v) => setState(() => _fournisseur = v),
        ),
        const SizedBox(height: 14),
        Text('Montant total *', style: TextStyle(color: context.textMuted, fontSize: 12)),
        const SizedBox(height: 6),
        TextField(controller: _montantCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration()),
        const SizedBox(height: 14),
        Text('Montant déjà versé', style: TextStyle(color: context.textMuted, fontSize: 12)),
        const SizedBox(height: 6),
        TextField(controller: _verseCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'Laisser vide si payé en totalité')),
        const SizedBox(height: 20),
        GoldButton(label: _saving ? 'Enregistrement…' : 'Enregistrer', onPressed: _saving ? () {} : _save),
      ],
    );
  }
}

class _DepenseDetail extends StatelessWidget {
  final Depense depense;
  final VoidCallback onRegler;
  final VoidCallback onDelete;
  const _DepenseDetail({required this.depense, required this.onRegler, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(color: context.cardBg, borderRadius: BorderRadius.circular(12)),
                child: Column(children: [
                  Text(fmtFcfa(depense.montant), style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w700)),
                  Text('TOTAL', style: TextStyle(color: context.textFaint, fontSize: 9)),
                ]),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(color: context.cardBg, borderRadius: BorderRadius.circular(12)),
                child: Column(children: [
                  Text(fmtFcfa(depense.montantVerse), style: const TextStyle(color: AppColors.deepGreen, fontWeight: FontWeight.w700)),
                  Text('VERSÉ', style: TextStyle(color: context.textFaint, fontSize: 9)),
                ]),
              ),
            ),
          ],
        ),
        if (depense.reliquat > 0) ...[
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.rose.withOpacity(0.1), border: Border.all(color: AppColors.rose.withOpacity(0.25)), borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                Text(fmtFcfa(depense.reliquat), style: const TextStyle(color: AppColors.rose, fontWeight: FontWeight.w700, fontSize: 16)),
                const Text('RELIQUAT RESTANT', style: TextStyle(color: AppColors.rose, fontSize: 9)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          GoldButton(label: 'Régler le reliquat en entier', onPressed: onRegler),
        ],
        const SizedBox(height: 14),
        TextButton(
          onPressed: onDelete,
          style: TextButton.styleFrom(foregroundColor: AppColors.rose, padding: EdgeInsets.zero, alignment: Alignment.centerLeft),
          child: const Text('Supprimer cette dépense', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

class _MiniTotalDepense extends StatelessWidget {
  final String label;
  final String value;
  const _MiniTotalDepense({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(color: context.cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: context.cardBorder)),
      child: Column(
        children: [
          Text(value, style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w700, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(color: context.textFaint, fontSize: 9.5), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
