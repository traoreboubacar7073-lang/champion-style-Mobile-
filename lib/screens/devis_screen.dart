import 'package:flutter/material.dart';
import '../data/repository.dart';
import '../models/client.dart';
import '../models/devis.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import '../services/pdf_service.dart';

class DevisScreen extends StatefulWidget {
  const DevisScreen({super.key});

  @override
  State<DevisScreen> createState() => _DevisScreenState();
}

class _DevisScreenState extends State<DevisScreen> {
  final _repo = DevisRepository();
  final _clientRepo = ClientRepository();
  List<Devis> _devis = [];
  List<Client> _clients = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final devis = await _repo.all();
    final clients = await _clientRepo.all();
    if (!mounted) return;
    setState(() {
      _devis = devis;
      _clients = clients;
      _loading = false;
    });
  }

  void _openAdd({Devis? existing}) async {
    await showAppBottomSheet(
      context,
      title: existing != null ? 'Modifier le devis' : 'Nouveau devis',
      child: _DevisForm(clients: _clients, existing: existing, onSaved: () { Navigator.of(context).pop(); _load(); }),
    );
  }

  void _openDetail(Devis d) async {
    await showAppBottomSheet(
      context,
      title: d.id,
      child: _DevisDetail(
        devis: d,
        onEdit: () {
          Navigator.of(context).pop();
          _openAdd(existing: d);
        },
        onConvertCommande: () async {
          await CommandeRepository().create(
            client: d.client, modele: '(à préciser)', livraison: d.date, montant: d.montant,
          );
          if (!mounted) return;
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Commande créée à partir du devis.'), backgroundColor: AppColors.deepGreen),
          );
          _load();
        },
        onConvertFacture: () async {
          await FactureRepository().create(client: d.client, montant: d.montant, statut: 'Impayée', solde: d.montant);
          if (!mounted) return;
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Facture créée à partir du devis.'), backgroundColor: AppColors.deepGreen),
          );
          _load();
        },
        onDelete: () async {
          final confirme = await confirmDelete(context, nom: '${d.id} — ${d.client}', typeElement: 'ce devis');
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
    return Scaffold(
      appBar: AppBar(title: const Text('Devis')),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
            : _devis.isEmpty
                ? const EmptyState(icon: Icons.description_outlined, text: 'Aucun devis pour le moment.')
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _devis.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (ctx, i) {
                      final d = _devis[i];
                      return AppCard(
                        onTap: () => _openDetail(d),
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
                                      Text(d.client, style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w500, fontSize: 15), overflow: TextOverflow.ellipsis),
                                      Text('${d.id} · ${d.date}', style: TextStyle(color: context.textFaint, fontSize: 11.5)),
                                    ],
                                  ),
                                ),
                                StatutBadge(statut: d.statut),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(fmtFcfa(d.montant), style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w700, fontSize: 14)),
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

class _DevisForm extends StatefulWidget {
  final List<Client> clients;
  final Devis? existing;
  final VoidCallback onSaved;
  const _DevisForm({required this.clients, this.existing, required this.onSaved});

  @override
  State<_DevisForm> createState() => _DevisFormState();
}

class _DevisFormState extends State<_DevisForm> {
  final _repo = DevisRepository();
  final _montantCtrl = TextEditingController();
  String? _client;
  String _statut = 'En attente';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final d = widget.existing;
    if (d != null) {
      _client = d.client;
      _montantCtrl.text = d.montant == d.montant.roundToDouble() ? d.montant.toStringAsFixed(0) : d.montant.toString();
      _statut = d.statut;
    }
  }

  Future<void> _save() async {
    if (_client == null || _montantCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    if (widget.existing != null) {
      final updated = Devis(id: widget.existing!.id, client: _client!, montant: double.tryParse(_montantCtrl.text) ?? 0, statut: _statut, date: widget.existing!.date);
      await _repo.update(updated);
    } else {
      await _repo.create(client: _client!, montant: double.tryParse(_montantCtrl.text) ?? 0, statut: _statut);
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
        Text('Montant *', style: TextStyle(color: context.textMuted, fontSize: 12)),
        const SizedBox(height: 6),
        TextField(controller: _montantCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration()),
        const SizedBox(height: 14),
        Text('Statut', style: TextStyle(color: context.textMuted, fontSize: 12)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _statut,
          dropdownColor: AppColors.surface,
          items: const [
            DropdownMenuItem(value: 'En attente', child: Text('En attente', style: TextStyle(color: Colors.white))),
            DropdownMenuItem(value: 'Accepté', child: Text('Accepté', style: TextStyle(color: Colors.white))),
            DropdownMenuItem(value: 'Refusé', child: Text('Refusé', style: TextStyle(color: Colors.white))),
          ],
          onChanged: (v) => setState(() => _statut = v ?? 'En attente'),
        ),
        const SizedBox(height: 20),
        GoldButton(label: _saving ? 'Enregistrement…' : (widget.existing != null ? 'Enregistrer les modifications' : 'Enregistrer'), onPressed: _saving ? () {} : _save),
      ],
    );
  }
}

class _DevisDetail extends StatefulWidget {
  final Devis devis;
  final VoidCallback onEdit;
  final VoidCallback onConvertCommande;
  final VoidCallback onConvertFacture;
  final VoidCallback onDelete;
  const _DevisDetail({required this.devis, required this.onEdit, required this.onConvertCommande, required this.onConvertFacture, required this.onDelete});

  @override
  State<_DevisDetail> createState() => _DevisDetailState();
}

class _DevisDetailState extends State<_DevisDetail> {
  bool _generating = false;

  Future<void> _partagerPdf() async {
    setState(() => _generating = true);
    try {
      final d = widget.devis;
      final bytes = await PdfService.buildDevisPdf(id: d.id, client: d.client, montant: d.montant, statut: d.statut, date: d.date);
      await PdfService.shareOrDownload(bytes, 'Devis_${d.id}.pdf');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Une erreur est survenue lors de la génération du document.')));
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final devis = widget.devis;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(devis.client, style: TextStyle(color: context.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text(fmtFcfa(devis.montant), style: const TextStyle(color: AppColors.gold, fontSize: 24, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        if (_generating)
          const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Center(child: CircularProgressIndicator(color: AppColors.gold)))
        else
          GoldButton(label: 'Partager / PDF', onPressed: _partagerPdf),
        const SizedBox(height: 10),
        GhostButton(label: 'Modifier ce devis', onPressed: widget.onEdit),
        const SizedBox(height: 14),
        if (devis.statut == 'Accepté') ...[
          GoldButton(label: 'Convertir en commande', onPressed: widget.onConvertCommande),
          const SizedBox(height: 10),
          GhostButton(label: 'Convertir en facture', onPressed: widget.onConvertFacture),
          const SizedBox(height: 14),
        ],
        TextButton(
          onPressed: widget.onDelete,
          style: TextButton.styleFrom(foregroundColor: AppColors.rose, padding: EdgeInsets.zero, alignment: Alignment.centerLeft),
          child: const Text('Supprimer ce devis', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
