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
    return Scaffold(
      appBar: AppBar(title: const Text('Dépenses')),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
            : _depenses.isEmpty
                ? const EmptyState(icon: Icons.account_balance_wallet_outlined, text: 'Aucune dépense enregistrée.')
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _depenses.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (ctx, i) {
                      final d = _depenses[i];
                      return AppCard(
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
                      );
                    },
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
