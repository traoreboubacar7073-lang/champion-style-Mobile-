import 'package:flutter/material.dart';
import '../data/repository.dart';
import '../models/client.dart';
import '../models/paiement.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import '../services/pdf_service.dart';

const List<String> modesPaiement = ['Espèces', 'Orange Money', 'Moov Money', 'Virement bancaire', 'Mobicash', 'Autre'];

class PaiementsScreen extends StatefulWidget {
  const PaiementsScreen({super.key});

  @override
  State<PaiementsScreen> createState() => _PaiementsScreenState();
}

class _PaiementsScreenState extends State<PaiementsScreen> {
  final _repo = PaiementRepository();
  final _clientRepo = ClientRepository();
  List<Paiement> _paiements = [];
  List<Client> _clients = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final paiements = await _repo.all();
    final clients = await _clientRepo.all();
    if (!mounted) return;
    setState(() {
      _paiements = paiements;
      _clients = clients;
      _loading = false;
    });
  }

  void _openAdd() async {
    final result = await showAppBottomSheet<bool>(
      context,
      title: 'Enregistrer un paiement',
      child: _PaiementForm(clients: _clients, onSaved: () => Navigator.of(context).pop(true)),
    );
    if (result == true) _load();
  }

  Future<void> _genererRecu(Paiement p) async {
    try {
      final bytes = await PdfService.buildRecuPdf(client: p.client, montant: p.montant, date: p.date, referenceFacture: p.reference.isEmpty ? null : p.reference);
      await PdfService.shareOrDownload(bytes, 'Recu_${p.id}.pdf');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Impossible de générer le reçu.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paiements')),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
            : _paiements.isEmpty
                ? const EmptyState(icon: Icons.credit_card_outlined, text: 'Aucun paiement enregistré.')
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _paiements.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (ctx, i) {
                      final p = _paiements[i];
                      return AppCard(
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p.client, style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w500, fontSize: 15), overflow: TextOverflow.ellipsis),
                                  Text('${p.mode} · ${p.date}', style: TextStyle(color: context.textFaint, fontSize: 12)),
                                ],
                              ),
                            ),
                            Text('+${fmtFcfa(p.montant)}', style: const TextStyle(color: AppColors.deepGreen, fontWeight: FontWeight.w700, fontSize: 13.5)),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () => _genererRecu(p),
                              icon: const Icon(Icons.receipt_long_outlined, size: 19, color: AppColors.gold),
                              tooltip: 'Générer un reçu',
                            ),
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

class _PaiementForm extends StatefulWidget {
  final List<Client> clients;
  final VoidCallback onSaved;
  const _PaiementForm({required this.clients, required this.onSaved});

  @override
  State<_PaiementForm> createState() => _PaiementFormState();
}

class _PaiementFormState extends State<_PaiementForm> {
  final _repo = PaiementRepository();
  final _montantCtrl = TextEditingController();
  final _referenceCtrl = TextEditingController();
  String? _client;
  String _mode = 'Espèces';
  bool _saving = false;
  bool _genererRecuApres = true;

  Future<void> _save() async {
    if (_client == null || _montantCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    final p = await _repo.create(
      client: _client!,
      montant: double.tryParse(_montantCtrl.text) ?? 0,
      mode: _mode,
      reference: _referenceCtrl.text.trim(),
    );
    if (_genererRecuApres) {
      try {
        final bytes = await PdfService.buildRecuPdf(client: p.client, montant: p.montant, date: p.date, referenceFacture: p.reference.isEmpty ? null : p.reference);
        await PdfService.shareOrDownload(bytes, 'Recu_${p.id}.pdf');
      } catch (_) {
        // Le paiement reste enregistré même si le partage du reçu échoue.
      }
    }
    if (!mounted) return;
    setState(() => _saving = false);
    widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Client *', style: TextStyle(color: context.textMuted, fontSize: 12)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _client,
          dropdownColor: AppColors.surface,
          isExpanded: true,
          hint: Text('Choisir…', style: TextStyle(color: context.textFaint)),
          items: [for (final c in widget.clients) DropdownMenuItem(value: c.nom, child: Text(c.nom, style: TextStyle(color: context.textPrimary)))],
          onChanged: (v) => setState(() => _client = v),
        ),
        const SizedBox(height: 14),
        Text('Montant reçu *', style: TextStyle(color: context.textMuted, fontSize: 12)),
        const SizedBox(height: 6),
        TextField(controller: _montantCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration()),
        const SizedBox(height: 14),
        Text('Mode de paiement', style: TextStyle(color: context.textMuted, fontSize: 12)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _mode,
          dropdownColor: AppColors.surface,
          items: [for (final m in modesPaiement) DropdownMenuItem(value: m, child: Text(m, style: TextStyle(color: context.textPrimary)))],
          onChanged: (v) => setState(() => _mode = v ?? 'Espèces'),
        ),
        const SizedBox(height: 14),
        Text('Référence (facultatif)', style: TextStyle(color: context.textMuted, fontSize: 12)),
        const SizedBox(height: 6),
        TextField(controller: _referenceCtrl, decoration: const InputDecoration(hintText: 'Ex : FA-3301')),
        const SizedBox(height: 12),
        Row(
          children: [
            Checkbox(
              value: _genererRecuApres,
              onChanged: (v) => setState(() => _genererRecuApres = v ?? true),
              activeColor: AppColors.gold,
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _genererRecuApres = !_genererRecuApres),
                child: Text('Générer et partager un reçu après enregistrement', style: TextStyle(color: context.textMuted, fontSize: 12.5)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        GoldButton(label: _saving ? 'Enregistrement…' : 'Enregistrer', onPressed: _saving ? () {} : _save),
      ],
    );
  }
}
