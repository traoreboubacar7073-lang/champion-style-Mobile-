import 'package:flutter/material.dart';
import '../data/repository.dart';
import '../models/client.dart';
import '../models/facture.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class FacturesScreen extends StatefulWidget {
  const FacturesScreen({super.key});

  @override
  State<FacturesScreen> createState() => _FacturesScreenState();
}

class _FacturesScreenState extends State<FacturesScreen> {
  final _repo = FactureRepository();
  final _clientRepo = ClientRepository();
  List<Facture> _factures = [];
  List<Client> _clients = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final factures = await _repo.all();
    final clients = await _clientRepo.all();
    if (!mounted) return;
    setState(() {
      _factures = factures;
      _clients = clients;
      _loading = false;
    });
  }

  void _openAdd() async {
    await showAppBottomSheet(
      context,
      title: 'Nouvelle facture',
      child: _FactureForm(clients: _clients, onSaved: () { Navigator.of(context).pop(); _load(); }),
    );
  }

  void _openDetail(Facture f) async {
    await showAppBottomSheet(
      context,
      title: f.id,
      child: _FactureDetail(
        facture: f,
        onDelete: () async {
          await _repo.delete(f);
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
              ScreenHeader(eyebrow: 'Commercial', title: 'Factures', action: FabRound(onPressed: _openAdd)),
              const SizedBox(height: 6),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
                    : _factures.isEmpty
                        ? const EmptyState(icon: Icons.receipt_long_outlined, text: 'Aucune facture pour le moment.')
                        : ListView.separated(
                            itemCount: _factures.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (ctx, i) {
                              final f = _factures[i];
                              return AppCard(
                                onTap: () => _openDetail(f),
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
                                              Text(f.client, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 15), overflow: TextOverflow.ellipsis),
                                              Text('${f.id} · ${f.date}', style: const TextStyle(color: AppColors.textFaint, fontSize: 11)),
                                            ],
                                          ),
                                        ),
                                        StatutBadge(statut: f.statut),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(fmtFcfa(f.montant), style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w700, fontSize: 14)),
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

class _FactureForm extends StatefulWidget {
  final List<Client> clients;
  final VoidCallback onSaved;
  const _FactureForm({required this.clients, required this.onSaved});

  @override
  State<_FactureForm> createState() => _FactureFormState();
}

class _FactureFormState extends State<_FactureForm> {
  final _repo = FactureRepository();
  final _montantCtrl = TextEditingController();
  String? _client;
  String _statut = 'Payée';
  bool _saving = false;

  Future<void> _save() async {
    if (_client == null || _montantCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    final montant = double.tryParse(_montantCtrl.text) ?? 0;
    await _repo.create(
      client: _client!,
      montant: montant,
      statut: _statut,
      solde: _statut == 'Payée' ? 0 : montant,
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
        const Text('Montant *', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
        const SizedBox(height: 6),
        TextField(controller: _montantCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration()),
        const SizedBox(height: 14),
        const Text('Statut', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _statut,
          dropdownColor: AppColors.surface,
          items: const [
            DropdownMenuItem(value: 'Payée', child: Text('Payée', style: TextStyle(color: Colors.white))),
            DropdownMenuItem(value: 'Partielle', child: Text('Partielle', style: TextStyle(color: Colors.white))),
            DropdownMenuItem(value: 'Impayée', child: Text('Impayée', style: TextStyle(color: Colors.white))),
          ],
          onChanged: (v) => setState(() => _statut = v ?? 'Payée'),
        ),
        const SizedBox(height: 20),
        GoldButton(label: _saving ? 'Enregistrement…' : 'Enregistrer', onPressed: _saving ? () {} : _save),
      ],
    );
  }
}

class _FactureDetail extends StatelessWidget {
  final Facture facture;
  final VoidCallback onDelete;
  const _FactureDetail({required this.facture, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(facture.client, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(12)),
                child: Column(children: [
                  Text(fmtFcfa(facture.montant), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
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
                  Text(fmtFcfa(facture.solde), style: const TextStyle(color: AppColors.rose, fontWeight: FontWeight.w700)),
                  const Text('SOLDE RESTANT', style: TextStyle(color: AppColors.textFaint, fontSize: 9)),
                ]),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        TextButton(
          onPressed: onDelete,
          style: TextButton.styleFrom(foregroundColor: AppColors.rose, padding: EdgeInsets.zero, alignment: Alignment.centerLeft),
          child: const Text('Supprimer cette facture', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
