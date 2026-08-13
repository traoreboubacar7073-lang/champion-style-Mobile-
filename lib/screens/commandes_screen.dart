import 'package:flutter/material.dart';
import '../data/repository.dart';
import '../models/client.dart';
import '../models/commande.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import 'factures_screen.dart';

const List<String> statutsCommande = ['Nouvelle', 'En cours', 'Essayage', 'Prête', 'Livrée'];

class CommandesScreen extends StatefulWidget {
  const CommandesScreen({super.key});

  @override
  State<CommandesScreen> createState() => _CommandesScreenState();
}

class _CommandesScreenState extends State<CommandesScreen> {
  final _repo = CommandeRepository();
  final _clientRepo = ClientRepository();
  List<Commande> _commandes = [];
  List<Client> _clients = [];
  bool _loading = true;
  String _filtre = 'Toutes';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final commandes = await _repo.all();
    final clients = await _clientRepo.all();
    if (!mounted) return;
    setState(() {
      _commandes = commandes;
      _clients = clients;
      _loading = false;
    });
  }

  List<Commande> get _filtered =>
      _filtre == 'Toutes' ? _commandes : _commandes.where((c) => c.statut == _filtre).toList();

  void _openAdd() async {
    await showAppBottomSheet(
      context,
      title: 'Nouvelle commande',
      child: _CommandeForm(clients: _clients, onSaved: () { Navigator.of(context).pop(); _load(); }),
    );
  }

  void _openDetail(Commande c) async {
    await showAppBottomSheet(
      context,
      title: c.id,
      child: _CommandeDetail(
        commande: c,
        onStatutChange: (s) async { await _repo.updateStatut(c.id, s); _load(); },
        onFacturer: () async {
          final facture = await FactureRepository().creerDepuisCommande(c);
          if (!mounted) return;
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Facture ${facture.id} créée.'), backgroundColor: AppColors.deepGreen),
          );
        },
        onDelete: () async {
          await _repo.delete(c);
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ScreenHeader(eyebrow: 'Suivi de production', title: 'Commandes', action: FabRound(onPressed: _openAdd)),
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final s in ['Toutes', ...statutsCommande])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(s),
                          selected: _filtre == s,
                          onSelected: (_) => setState(() => _filtre = s),
                          selectedColor: AppColors.gold,
                          backgroundColor: AppColors.surfaceLight,
                          labelStyle: TextStyle(color: _filtre == s ? Colors.black : Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                          side: const BorderSide(color: AppColors.border),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
                    : _filtered.isEmpty
                        ? const EmptyState(icon: Icons.shopping_bag_outlined, text: 'Aucune commande dans cette catégorie.')
                        : ListView.separated(
                            itemCount: _filtered.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (ctx, i) {
                              final c = _filtered[i];
                              return AppCard(
                                onTap: () => _openDetail(c),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(c.client, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 15), overflow: TextOverflow.ellipsis),
                                              Text('${c.id} · ${c.modele}', style: const TextStyle(color: AppColors.textFaint, fontSize: 11)),
                                            ],
                                          ),
                                        ),
                                        StatutBadge(statut: c.statut),
                                      ],
                                    ),
                                    const Divider(height: 20),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Livraison ${c.livraison}', style: const TextStyle(color: AppColors.textFaint, fontSize: 11)),
                                        Text(fmtFcfa(c.montant), style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w700, fontSize: 13)),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommandeForm extends StatefulWidget {
  final List<Client> clients;
  final VoidCallback onSaved;
  const _CommandeForm({required this.clients, required this.onSaved});

  @override
  State<_CommandeForm> createState() => _CommandeFormState();
}

class _CommandeFormState extends State<_CommandeForm> {
  final _repo = CommandeRepository();
  final _modeleCtrl = TextEditingController();
  final _montantCtrl = TextEditingController();
  final _avanceCtrl = TextEditingController();
  String? _client;
  String _statut = 'Nouvelle';
  DateTime? _livraison;
  bool _saving = false;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) setState(() => _livraison = picked);
  }

  String _fmtDate(DateTime d) {
    const mois = ['janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin', 'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'];
    return '${d.day.toString().padLeft(2, '0')} ${mois[d.month - 1]} ${d.year}';
  }

  Future<void> _save() async {
    if (_client == null || _modeleCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    await _repo.create(
      client: _client!,
      modele: _modeleCtrl.text.trim(),
      statut: _statut,
      livraison: _livraison != null ? _fmtDate(_livraison!) : _fmtDate(DateTime.now()),
      montant: double.tryParse(_montantCtrl.text) ?? 0,
      avance: double.tryParse(_avanceCtrl.text) ?? 0,
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
        const Text('Client *', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _client,
          dropdownColor: AppColors.surface,
          isExpanded: true,
          hint: const Text('Choisir…', style: TextStyle(color: AppColors.textFaint)),
          items: [for (final c in widget.clients) DropdownMenuItem(value: c.nom, child: Text(c.nom, style: const TextStyle(color: Colors.white)))],
          onChanged: (v) => setState(() => _client = v),
        ),
        const SizedBox(height: 14),
        const Text('Modèle *', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
        const SizedBox(height: 6),
        TextField(controller: _modeleCtrl, decoration: const InputDecoration(hintText: 'Ex : Robe Sirène Wax')),
        const SizedBox(height: 14),
        const Text('Statut', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _statut,
          dropdownColor: AppColors.surface,
          items: [for (final s in statutsCommande) DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(color: Colors.white)))],
          onChanged: (v) => setState(() => _statut = v ?? 'Nouvelle'),
        ),
        const SizedBox(height: 14),
        const Text('Date de livraison', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
        const SizedBox(height: 6),
        InkWell(
          onTap: _pickDate,
          child: InputDecorator(
            decoration: const InputDecoration(suffixIcon: Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.textFaint)),
            child: Text(_livraison != null ? _fmtDate(_livraison!) : 'Choisir une date', style: TextStyle(color: _livraison != null ? Colors.white : AppColors.textFaint)),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Montant total', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  const SizedBox(height: 6),
                  TextField(controller: _montantCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration()),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Avance versée', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  const SizedBox(height: 6),
                  TextField(controller: _avanceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration()),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        GoldButton(label: _saving ? 'Enregistrement…' : 'Enregistrer', onPressed: _saving ? () {} : _save),
      ],
    );
  }
}

class _CommandeDetail extends StatefulWidget {
  final Commande commande;
  final void Function(String) onStatutChange;
  final VoidCallback onFacturer;
  final VoidCallback onDelete;
  const _CommandeDetail({required this.commande, required this.onStatutChange, required this.onFacturer, required this.onDelete});

  @override
  State<_CommandeDetail> createState() => _CommandeDetailState();
}

class _CommandeDetailState extends State<_CommandeDetail> {
  late String _statut;

  @override
  void initState() {
    super.initState();
    _statut = widget.commande.statut;
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.commande;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(c.client, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
        Text(c.modele, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(12)),
                child: Column(children: [
                  Text(fmtFcfa(c.montant), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  const Text('MONTANT', style: TextStyle(color: AppColors.textFaint, fontSize: 9)),
                ]),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(12)),
                child: Column(children: [
                  Text(fmtFcfa(c.avance), style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w700)),
                  const Text('AVANCE VERSÉE', style: TextStyle(color: AppColors.textFaint, fontSize: 9)),
                ]),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        const Text('Changer le statut', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: [
            for (final s in statutsCommande)
              ChoiceChip(
                label: Text(s),
                selected: _statut == s,
                onSelected: (_) { setState(() => _statut = s); widget.onStatutChange(s); },
                selectedColor: AppColors.gold,
                backgroundColor: AppColors.surfaceLight,
                labelStyle: TextStyle(color: _statut == s ? Colors.black : Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                side: const BorderSide(color: AppColors.border),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text('Livraison prévue : ${c.livraison}', style: const TextStyle(color: AppColors.textFaint, fontSize: 12)),
        const SizedBox(height: 18),
        GoldButton(label: 'Facturer cette commande', onPressed: widget.onFacturer),
        const SizedBox(height: 10),
        TextButton(
          onPressed: widget.onDelete,
          style: TextButton.styleFrom(foregroundColor: AppColors.rose, padding: EdgeInsets.zero, alignment: Alignment.centerLeft),
          child: const Text('Supprimer cette commande', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
