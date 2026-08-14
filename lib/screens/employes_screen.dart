import 'package:flutter/material.dart';
import '../data/repository.dart';
import '../models/employe.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

const List<String> frequencesPaiement = ['Journalier', 'Hebdomadaire', 'Mensuel'];
const List<String> modesPaiementEmploye = ['Espèces', 'Orange Money', 'Moov Money', 'Virement bancaire', 'Mobicash'];

const List<String> _moisAbbr = ['janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin', 'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'];

DateTime? _parseFrDate(String s) {
  final parts = s.trim().split(RegExp(r'\s+'));
  if (parts.length != 3) return null;
  final day = int.tryParse(parts[0]);
  final monthIdx = _moisAbbr.indexOf(parts[1]);
  final year = int.tryParse(parts[2]);
  if (day == null || monthIdx == -1 || year == null) return null;
  return DateTime(year, monthIdx + 1, day);
}

class _Totaux {
  final double semaine;
  final double mois;
  final double annee;
  const _Totaux(this.semaine, this.mois, this.annee);
}

_Totaux _computeTotaux(List<PaiementEmploye> paiements) {
  final now = DateTime.now();
  final startOfWeek = DateTime(now.year, now.month, now.day).subtract(Duration(days: (now.weekday - 1)));
  final startOfMonth = DateTime(now.year, now.month, 1);
  final startOfYear = DateTime(now.year, 1, 1);
  double semaine = 0, mois = 0, annee = 0;
  for (final p in paiements) {
    final d = _parseFrDate(p.date);
    if (d == null) continue;
    if (!d.isBefore(startOfYear)) annee += p.montant;
    if (!d.isBefore(startOfMonth)) mois += p.montant;
    if (!d.isBefore(startOfWeek)) semaine += p.montant;
  }
  return _Totaux(semaine, mois, annee);
}

class EmployesScreen extends StatefulWidget {
  const EmployesScreen({super.key});

  @override
  State<EmployesScreen> createState() => _EmployesScreenState();
}

class _EmployesScreenState extends State<EmployesScreen> {
  final _repo = EmployeRepository();
  List<Employe> _employes = [];
  List<PaiementEmploye> _paiementsEmployes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final employes = await _repo.all();
    final paiements = await PaiementEmployeRepository().all();
    if (!mounted) return;
    setState(() {
      _employes = employes;
      _paiementsEmployes = paiements;
      _loading = false;
    });
  }

  void _openAdd() async {
    await showAppBottomSheet(
      context,
      title: 'Nouvel employé',
      child: _EmployeForm(onSaved: () { Navigator.of(context).pop(); _load(); }),
    );
  }

  void _openDetail(Employe e) async {
    final historique = _paiementsEmployes.where((p) => p.employe == e.nom).toList();
    await showAppBottomSheet(
      context,
      title: e.nom,
      child: _EmployeDetail(
        employe: e,
        historique: historique,
        onAjouterPaiement: () async {
          Navigator.of(context).pop();
          await showAppBottomSheet(
            context,
            title: 'Enregistrer un paiement',
            child: _PaiementEmployeForm(employe: e, onSaved: () { Navigator.of(context).pop(); _load(); }),
          );
        },
        onDelete: () async {
          await _repo.delete(e);
          if (!mounted) return;
          Navigator.of(context).pop();
          _load();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totauxGlobaux = _computeTotaux(_paiementsEmployes);
    return Scaffold(
      appBar: AppBar(title: const Text('Employés')),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      Expanded(child: _MiniTotal(label: 'Payé / semaine', value: fmtFcfa(totauxGlobaux.semaine))),
                      const SizedBox(width: 8),
                      Expanded(child: _MiniTotal(label: 'Payé / mois', value: fmtFcfa(totauxGlobaux.mois))),
                      const SizedBox(width: 8),
                      Expanded(child: _MiniTotal(label: 'Payé / année', value: fmtFcfa(totauxGlobaux.annee))),
                    ],
                  ),
                  const SizedBox(height: 18),
                  if (_employes.isEmpty)
                    const EmptyState(icon: Icons.manage_accounts_outlined, text: 'Aucun employé pour le moment.')
                  else
                    ..._employes.map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: AppCard(
                            onTap: () => _openDetail(e),
                            child: Row(
                              children: [
                                AppAvatar(name: e.nom, size: 40),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(child: Text(e.nom, style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w500, fontSize: 14.5), overflow: TextOverflow.ellipsis)),
                                          if (e.specialite.isNotEmpty) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(color: AppColors.gold.withOpacity(0.15), borderRadius: BorderRadius.circular(999)),
                                              child: const Text('Couturier', style: TextStyle(color: AppColors.gold, fontSize: 9, fontWeight: FontWeight.w700)),
                                            ),
                                          ],
                                        ],
                                      ),
                                      Text(e.poste, style: TextStyle(color: context.textFaint, fontSize: 12)),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(fmtFcfa(e.tauxPaiement), style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w600, fontSize: 13)),
                                    Text(e.frequencePaiement, style: TextStyle(color: context.textFaint, fontSize: 10.5)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        )),
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

class _MiniTotal extends StatelessWidget {
  final String label;
  final String value;
  const _MiniTotal({required this.label, required this.value});

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

class _EmployeForm extends StatefulWidget {
  final VoidCallback onSaved;
  const _EmployeForm({required this.onSaved});

  @override
  State<_EmployeForm> createState() => _EmployeFormState();
}

class _EmployeFormState extends State<_EmployeForm> {
  final _repo = EmployeRepository();
  final _nomCtrl = TextEditingController();
  final _posteCtrl = TextEditingController();
  final _tauxCtrl = TextEditingController();
  final _specialiteCtrl = TextEditingController();
  String _frequence = 'Mensuel';
  bool _saving = false;

  Future<void> _save() async {
    if (_nomCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    await _repo.create(
      nom: _nomCtrl.text.trim(),
      poste: _posteCtrl.text.trim(),
      specialite: _specialiteCtrl.text.trim(),
      frequencePaiement: _frequence,
      tauxPaiement: double.tryParse(_tauxCtrl.text) ?? 0,
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
        Text('Nom complet *', style: TextStyle(color: context.textMuted, fontSize: 12)),
        const SizedBox(height: 6),
        TextField(controller: _nomCtrl, decoration: const InputDecoration()),
        const SizedBox(height: 14),
        Text('Poste', style: TextStyle(color: context.textMuted, fontSize: 12)),
        const SizedBox(height: 6),
        TextField(controller: _posteCtrl, decoration: const InputDecoration(hintText: 'Ex : Couturière')),
        const SizedBox(height: 14),
        Text('Fréquence de paiement', style: TextStyle(color: context.textMuted, fontSize: 12)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _frequence,
          dropdownColor: AppColors.surface,
          items: [for (final f in frequencesPaiement) DropdownMenuItem(value: f, child: Text(f, style: TextStyle(color: context.textPrimary)))],
          onChanged: (v) => setState(() => _frequence = v ?? 'Mensuel'),
        ),
        const SizedBox(height: 14),
        Text('Montant par période', style: TextStyle(color: context.textMuted, fontSize: 12)),
        const SizedBox(height: 6),
        TextField(controller: _tauxCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration()),
        const SizedBox(height: 14),
        Text('Spécialité couture (facultatif)', style: TextStyle(color: context.textMuted, fontSize: 12)),
        const SizedBox(height: 6),
        TextField(controller: _specialiteCtrl, decoration: const InputDecoration(hintText: 'Ex : Robes de soirée — laisser vide si non couturier')),
        const SizedBox(height: 20),
        GoldButton(label: _saving ? 'Enregistrement…' : 'Enregistrer', onPressed: _saving ? () {} : _save),
      ],
    );
  }
}

class _EmployeDetail extends StatelessWidget {
  final Employe employe;
  final List<PaiementEmploye> historique;
  final VoidCallback onAjouterPaiement;
  final VoidCallback onDelete;
  const _EmployeDetail({required this.employe, required this.historique, required this.onAjouterPaiement, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final totaux = _computeTotaux(historique);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _MiniTotal(label: 'Semaine', value: fmtFcfa(totaux.semaine))),
            const SizedBox(width: 8),
            Expanded(child: _MiniTotal(label: 'Mois', value: fmtFcfa(totaux.mois))),
            const SizedBox(width: 8),
            Expanded(child: _MiniTotal(label: 'Année', value: fmtFcfa(totaux.annee))),
          ],
        ),
        const SizedBox(height: 16),
        GoldButton(label: 'Enregistrer un paiement', onPressed: onAjouterPaiement),
        const SizedBox(height: 16),
        Text('HISTORIQUE', style: TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.6)),
        const SizedBox(height: 10),
        if (historique.isEmpty)
          Text('Aucun paiement enregistré.', style: TextStyle(color: context.textFaint, fontSize: 13))
        else
          SizedBox(
            height: 180,
            child: ListView.separated(
              itemCount: historique.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) {
                final p = historique[i];
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(color: context.cardBg, borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${p.date} · ${p.mode}', style: TextStyle(color: context.textFaint, fontSize: 11.5)),
                      Text('+${fmtFcfa(p.montant)}', style: const TextStyle(color: AppColors.deepGreen, fontWeight: FontWeight.w700, fontSize: 13)),
                    ],
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: onDelete,
          style: TextButton.styleFrom(foregroundColor: AppColors.rose, padding: EdgeInsets.zero, alignment: Alignment.centerLeft),
          child: const Text('Supprimer cet employé', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

class _PaiementEmployeForm extends StatefulWidget {
  final Employe employe;
  final VoidCallback onSaved;
  const _PaiementEmployeForm({required this.employe, required this.onSaved});

  @override
  State<_PaiementEmployeForm> createState() => _PaiementEmployeFormState();
}

class _PaiementEmployeFormState extends State<_PaiementEmployeForm> {
  final _montantCtrl = TextEditingController();
  final _periodeCtrl = TextEditingController();
  String _mode = 'Espèces';
  bool _saving = false;

  Future<void> _save() async {
    final montant = double.tryParse(_montantCtrl.text) ?? 0;
    if (montant <= 0) return;
    setState(() => _saving = true);
    await PaiementEmployeRepository().create(employe: widget.employe.nom, montant: montant, mode: _mode, periode: _periodeCtrl.text.trim());
    // Chaque paiement à un employé est automatiquement compté comme une
    // dépense de l'atelier — même logique que sur les autres versions.
    await DepenseRepository().create(categorie: 'Salaires & paiements employés', montant: montant, montantVerse: montant);
    if (!mounted) return;
    setState(() => _saving = false);
    widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.employe.nom, style: TextStyle(color: context.textFaint, fontSize: 13)),
        const SizedBox(height: 14),
        Text('Montant versé *', style: TextStyle(color: context.textMuted, fontSize: 12)),
        const SizedBox(height: 6),
        TextField(controller: _montantCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration()),
        const SizedBox(height: 14),
        Text('Mode de paiement', style: TextStyle(color: context.textMuted, fontSize: 12)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _mode,
          dropdownColor: AppColors.surface,
          items: [for (final m in modesPaiementEmploye) DropdownMenuItem(value: m, child: Text(m, style: TextStyle(color: context.textPrimary)))],
          onChanged: (v) => setState(() => _mode = v ?? 'Espèces'),
        ),
        const SizedBox(height: 14),
        Text('Période couverte (facultatif)', style: TextStyle(color: context.textMuted, fontSize: 12)),
        const SizedBox(height: 6),
        TextField(controller: _periodeCtrl, decoration: const InputDecoration(hintText: 'Ex : Semaine du 10 au 16')),
        const SizedBox(height: 20),
        GoldButton(label: _saving ? 'Enregistrement…' : 'Confirmer', onPressed: _saving ? () {} : _save),
      ],
    );
  }
}
