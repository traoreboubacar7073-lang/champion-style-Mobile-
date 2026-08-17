import 'package:flutter/material.dart';
import '../data/repository.dart';
import '../models/client.dart';
import '../models/facture.dart';
import '../theme/app_theme.dart';
import '../theme/business_info.dart';
import '../widgets/shared_widgets.dart';
import '../services/pdf_service.dart';
import '../services/whatsapp_service.dart';

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
        clients: _clients,
        onDelete: () async {
          final confirme = await confirmDelete(context, nom: '${f.id} — ${f.client}', typeElement: 'cette facture');
          if (!confirme) return;
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
                                              Text(f.client, style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w500, fontSize: 15), overflow: TextOverflow.ellipsis),
                                              Text('${f.id} · ${f.date}', style: TextStyle(color: context.textFaint, fontSize: 11)),
                                            ],
                                          ),
                                        ),
                                        StatutBadge(statut: f.statut),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(fmtFcfa(f.montant), style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w700, fontSize: 14)),
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
          items: [
            DropdownMenuItem(value: 'Payée', child: Text('Payée', style: TextStyle(color: context.textPrimary))),
            DropdownMenuItem(value: 'Partielle', child: Text('Partielle', style: TextStyle(color: context.textPrimary))),
            DropdownMenuItem(value: 'Impayée', child: Text('Impayée', style: TextStyle(color: context.textPrimary))),
          ],
          onChanged: (v) => setState(() => _statut = v ?? 'Payée'),
        ),
        const SizedBox(height: 20),
        GoldButton(label: _saving ? 'Enregistrement…' : 'Enregistrer', onPressed: _saving ? () {} : _save),
      ],
    );
  }
}

class _FactureDetail extends StatefulWidget {
  final Facture facture;
  final List<Client> clients;
  final VoidCallback onDelete;
  const _FactureDetail({required this.facture, required this.clients, required this.onDelete});

  @override
  State<_FactureDetail> createState() => _FactureDetailState();
}

class _FactureDetailState extends State<_FactureDetail> {
  bool _generating = false;

  Future<void> _action(Future<void> Function() task) async {
    setState(() => _generating = true);
    try {
      await task();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Une erreur est survenue lors de la génération du document.")),
        );
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  /// Après avoir partagé le reçu, propose d'envoyer directement un message
  /// WhatsApp au client (numéro retrouvé dans sa fiche) — même principe
  /// que pour prévenir qu'une commande est prête.
  void _proposerMessageWhatsapp(double montant, String? referenceFacture) {
    final trouve = widget.clients.where((c) => c.nom == widget.facture.client);
    final telephone = trouve.isEmpty ? '' : trouve.first.tel;
    if (!WhatsappService.numeroValide(telephone)) return;

    final message = 'Bonjour ${widget.facture.client}, voici la confirmation de votre versement de ${fmtFcfa(montant)}'
        '${referenceFacture != null ? ' (réf. $referenceFacture)' : ''} chez ${BusinessInfo.nom}. '
        'Merci de votre confiance 🙏';

    showAppBottomSheet(
      context,
      title: 'Prévenir le client',
      child: WhatsappMessageSheet(
        telephone: telephone,
        messageInitial: message,
        introTexte: 'Un message peut être envoyé au client sur WhatsApp pour accompagner le reçu',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final facture = widget.facture;
    final montantPaye = facture.montant - facture.solde;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(facture.client, style: TextStyle(color: context.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(color: context.cardBg, borderRadius: BorderRadius.circular(12)),
                child: Column(children: [
                  Text(fmtFcfa(facture.montant), style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w700)),
                  Text('MONTANT', style: TextStyle(color: context.textFaint, fontSize: 9)),
                ]),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(color: context.cardBg, borderRadius: BorderRadius.circular(12)),
                child: Column(children: [
                  Text(fmtFcfa(facture.solde), style: const TextStyle(color: AppColors.rose, fontWeight: FontWeight.w700)),
                  Text('SOLDE RESTANT', style: TextStyle(color: context.textFaint, fontSize: 9)),
                ]),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (_generating)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Center(child: CircularProgressIndicator(color: AppColors.gold)),
          )
        else ...[
          Row(
            children: [
              Expanded(
                child: GhostButton(
                  label: 'Imprimer',
                  onPressed: () => _action(() async {
                    final bytes = await PdfService.buildFacturePdf(facture);
                    await PdfService.printDocument(bytes);
                  }),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GoldButton(
                  label: 'Partager / PDF',
                  onPressed: () => _action(() async {
                    final bytes = await PdfService.buildFacturePdf(facture);
                    await PdfService.shareOrDownload(bytes, 'Facture_${facture.id}.pdf');
                  }),
                ),
              ),
            ],
          ),
          if (montantPaye > 0) ...[
            const SizedBox(height: 10),
            GhostButton(
              label: 'Générer un reçu de paiement',
              onPressed: () => _action(() async {
                final bytes = await PdfService.buildRecuPdf(
                  client: facture.client,
                  montant: montantPaye,
                  date: facture.date,
                  referenceFacture: facture.id,
                  soldeRestant: facture.solde,
                );
                await PdfService.shareOrDownload(bytes, 'Recu_${facture.id}.pdf');
                if (!mounted) return;
                _proposerMessageWhatsapp(montantPaye, facture.id);
              }),
            ),
          ],
        ],
        const SizedBox(height: 16),
        TextButton(
          onPressed: widget.onDelete,
          style: TextButton.styleFrom(foregroundColor: AppColors.rose, padding: EdgeInsets.zero, alignment: Alignment.centerLeft),
          child: Text('Supprimer cette facture', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
