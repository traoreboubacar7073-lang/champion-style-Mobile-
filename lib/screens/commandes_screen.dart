import 'package:flutter/material.dart';
import '../data/repository.dart';
import '../models/client.dart';
import '../models/commande.dart';
import '../models/employe.dart';
import '../models/modele.dart';
import '../theme/app_theme.dart';
import '../theme/business_info.dart';
import '../widgets/shared_widgets.dart';
import '../services/whatsapp_service.dart';
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
  List<Employe> _employes = [];
  List<Modele> _modeles = [];
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
    final employes = await EmployeRepository().all();
    final modeles = await ModeleRepository().all();
    if (!mounted) return;
    setState(() {
      _commandes = commandes;
      _clients = clients;
      _employes = employes;
      _modeles = modeles;
      _loading = false;
    });
  }

  List<Commande> get _filtered =>
      _filtre == 'Toutes' ? _commandes : _commandes.where((c) => c.statut == _filtre).toList();

  void _openAdd({Commande? existing}) async {
    await showAppBottomSheet(
      context,
      title: existing != null ? 'Modifier la commande' : 'Nouvelle commande',
      child: _CommandeForm(clients: _clients, employes: _employes, modeles: _modeles, existing: existing, onSaved: () { Navigator.of(context).pop(); _load(); }),
    );
  }

  void _openDetail(Commande c) async {
    await showAppBottomSheet(
      context,
      title: c.id,
      child: _CommandeDetail(
        commande: c,
        onEdit: () {
          Navigator.of(context).pop();
          _openAdd(existing: c);
        },
        onStatutChange: (s) async {
          await _repo.updateStatut(c.id, s);
          _load();
          if (s == 'Prête') _proposerMessageWhatsapp(c);
        },
        onFacturer: () async {
          final facture = await FactureRepository().creerDepuisCommande(c);
          if (!mounted) return;
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Facture ${facture.id} créée.'), backgroundColor: AppColors.deepGreen),
          );
        },
        onDelete: () async {
          final confirme = await confirmDelete(context, nom: '${c.id} — ${c.client}', typeElement: 'cette commande');
          if (!confirme) return;
          await _repo.delete(c);
          if (!mounted) return;
          Navigator.of(context).pop();
          _load();
        },
      ),
    );
  }

  /// Propose d'ouvrir WhatsApp avec un message déjà rédigé, dès qu'une
  /// commande passe au statut "Prête" — à condition que le client ait un
  /// numéro de téléphone enregistré.
  void _proposerMessageWhatsapp(Commande c) async {
    final client = _clients.where((cl) => cl.nom == c.client).toList();
    final telephone = client.isNotEmpty ? client.first.tel : '';
    if (!WhatsappService.numeroValide(telephone)) return;

    final messageParDefaut =
        'Bonjour ${c.client}, votre commande (${c.modele}) chez ${BusinessInfo.nom} est prête ! '
        'Vous pouvez venir la récupérer quand vous le souhaitez. Merci de votre confiance 🙏';

    if (!mounted) return;
    await showAppBottomSheet(
      context,
      title: 'Prévenir le client',
      child: _MessageWhatsappForm(telephone: telephone, messageInitial: messageParDefaut),
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
                          backgroundColor: context.cardBg,
                          labelStyle: TextStyle(color: _filtre == s ? Colors.black : context.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                          side: BorderSide(color: context.cardBorder),
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
                                              Text(c.client, style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w500, fontSize: 15), overflow: TextOverflow.ellipsis),
                                              Text('${c.id} · ${c.modele}', style: TextStyle(color: context.textFaint, fontSize: 11)),
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
                                        Text('Livraison ${c.livraison}', style: TextStyle(color: context.textFaint, fontSize: 11)),
                                        Text(fmtFcfa(c.montant), style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w700, fontSize: 13)),
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

const List<String> _moisAbbrCmd = ['janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin', 'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'];

DateTime? _parseFrDateCmd(String s) {
  final parts = s.trim().split(RegExp(r'\s+'));
  if (parts.length != 3) return null;
  final day = int.tryParse(parts[0]);
  final monthIdx = _moisAbbrCmd.indexOf(parts[1]);
  final year = int.tryParse(parts[2]);
  if (day == null || monthIdx == -1 || year == null) return null;
  return DateTime(year, monthIdx + 1, day);
}

class _CommandeForm extends StatefulWidget {
  final List<Client> clients;
  final List<Employe> employes;
  final List<Modele> modeles;
  final Commande? existing;
  final VoidCallback onSaved;
  const _CommandeForm({required this.clients, required this.employes, required this.modeles, this.existing, required this.onSaved});

  @override
  State<_CommandeForm> createState() => _CommandeFormState();
}

class _CommandeFormState extends State<_CommandeForm> {
  final _repo = CommandeRepository();
  String? _modele;
  String? _couturier;
  final _montantCtrl = TextEditingController();
  final _avanceCtrl = TextEditingController();
  String? _client;
  String _statut = 'Nouvelle';
  DateTime? _livraison;
  DateTime? _essayage;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final c = widget.existing;
    if (c != null) {
      _client = c.client;
      _modele = c.modele;
      _couturier = c.couturier.isEmpty ? null : c.couturier;
      _statut = c.statut;
      _livraison = _parseFrDateCmd(c.livraison);
      _essayage = c.dateEssayage.isEmpty ? null : _parseFrDateCmd(c.dateEssayage);
      _montantCtrl.text = c.montant == c.montant.roundToDouble() ? c.montant.toStringAsFixed(0) : c.montant.toString();
      _avanceCtrl.text = c.avance == c.avance.roundToDouble() ? c.avance.toStringAsFixed(0) : c.avance.toString();
    }
  }

  @override
  void dispose() {
    _montantCtrl.dispose();
    _avanceCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _livraison ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) setState(() => _livraison = picked);
  }

  Future<void> _pickEssayage() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _essayage ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) setState(() => _essayage = picked);
  }

  String _fmtDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')} ${_moisAbbrCmd[d.month - 1]} ${d.year}';
  }

  Future<void> _save() async {
    if (_client == null || (_modele == null || _modele!.trim().isEmpty)) return;
    setState(() => _saving = true);
    final montant = double.tryParse(_montantCtrl.text) ?? 0;
    final avance = double.tryParse(_avanceCtrl.text) ?? 0;
    final livraisonTexte = _livraison != null ? _fmtDate(_livraison!) : _fmtDate(DateTime.now());
    final essayageTexte = _essayage != null ? _fmtDate(_essayage!) : '';

    if (widget.existing != null) {
      final ancienneAvance = widget.existing!.avance;
      final updated = widget.existing!.copyWith(
        client: _client!, modele: _modele!.trim(), couturier: _couturier ?? '',
        statut: _statut, livraison: livraisonTexte, dateEssayage: essayageTexte, montant: montant, avance: avance,
      );
      await _repo.update(updated);
      // Si l'avance a augmenté par rapport à ce qu'elle était, la différence
      // est un vrai nouveau versement du client — on l'enregistre comme
      // paiement réel, pour que "Total versé" et les rapports restent exacts.
      if (avance > ancienneAvance) {
        await PaiementRepository().create(
          client: _client!, montant: avance - ancienneAvance, mode: 'Espèces', reference: widget.existing!.id,
        );
      }
    } else {
      final commande = await _repo.create(
        client: _client!,
        modele: _modele!.trim(),
        couturier: _couturier ?? '',
        statut: _statut,
        livraison: livraisonTexte,
        dateEssayage: essayageTexte,
        montant: montant,
        avance: avance,
      );
      // Une avance versée à la création est un vrai paiement du client —
      // on l'enregistre comme tel, pour que le total réellement versé et
      // les rapports financiers restent exacts, et la facture correspondante
      // est générée automatiquement dans la foulée.
      if (avance > 0) {
        await PaiementRepository().create(client: _client!, montant: avance, mode: 'Espèces', reference: commande.id);
        await FactureRepository().creerDepuisCommande(commande);
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
        Text('Modèle *', style: TextStyle(color: context.textMuted, fontSize: 12)),
        const SizedBox(height: 6),
        CatalogPickerField(
          options: [for (final m in widget.modeles) m.nom],
          initialValue: _modele,
          hintText: 'Choisir un modèle du catalogue…',
          customHintText: 'Ex : Robe apportée par la cliente',
          onChanged: (v) => setState(() => _modele = v),
        ),
        const SizedBox(height: 14),
        Text('Couturier assigné', style: TextStyle(color: context.textMuted, fontSize: 12)),
        const SizedBox(height: 6),
        widget.employes.isEmpty
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(color: context.cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: context.cardBorder)),
                child: Text('Aucun employé enregistré — ajoute-en un dans "Employés" pour pouvoir en assigner un ici.',
                    style: TextStyle(color: context.textFaint, fontSize: 12)),
              )
            : DropdownButtonFormField<String>(
                value: _couturier,
                dropdownColor: AppColors.surface,
                isExpanded: true,
                hint: Text('Choisir un couturier (facultatif)…', style: TextStyle(color: context.textFaint)),
                items: [for (final e in widget.employes) DropdownMenuItem(value: e.nom, child: Text(e.nom, style: TextStyle(color: context.textPrimary)))],
                onChanged: (v) => setState(() => _couturier = v),
              ),
        const SizedBox(height: 14),
        Text('Statut', style: TextStyle(color: context.textMuted, fontSize: 12)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _statut,
          dropdownColor: AppColors.surface,
          items: [for (final s in statutsCommande) DropdownMenuItem(value: s, child: Text(s, style: TextStyle(color: context.textPrimary)))],
          onChanged: (v) => setState(() => _statut = v ?? 'Nouvelle'),
        ),
        const SizedBox(height: 14),
        Text('Date de livraison', style: TextStyle(color: context.textMuted, fontSize: 12)),
        const SizedBox(height: 6),
        InkWell(
          onTap: _pickDate,
          child: InputDecorator(
            decoration: InputDecoration(suffixIcon: Icon(Icons.calendar_today_outlined, size: 16, color: context.textFaint)),
            child: Text(_livraison != null ? _fmtDate(_livraison!) : 'Choisir une date', style: TextStyle(color: _livraison != null ? context.textPrimary : context.textFaint)),
          ),
        ),
        const SizedBox(height: 14),
        Text('Date d\'essayage (facultatif)', style: TextStyle(color: context.textMuted, fontSize: 12)),
        const SizedBox(height: 6),
        InkWell(
          onTap: _pickEssayage,
          child: InputDecorator(
            decoration: InputDecoration(suffixIcon: Icon(Icons.event_outlined, size: 16, color: context.textFaint)),
            child: Text(_essayage != null ? _fmtDate(_essayage!) : 'Choisir une date', style: TextStyle(color: _essayage != null ? context.textPrimary : context.textFaint)),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Montant total', style: TextStyle(color: context.textMuted, fontSize: 12)),
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
                  Text('Avance versée', style: TextStyle(color: context.textMuted, fontSize: 12)),
                  const SizedBox(height: 6),
                  TextField(controller: _avanceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration()),
                ],
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            "Si une avance est indiquée, la facture correspondante sera créée automatiquement.",
            style: TextStyle(color: context.textFaint, fontSize: 11.5, fontStyle: FontStyle.italic),
          ),
        ),
        const SizedBox(height: 20),
        GoldButton(label: _saving ? 'Enregistrement…' : 'Enregistrer', onPressed: _saving ? () {} : _save),
      ],
    );
  }
}

class _CommandeDetail extends StatefulWidget {
  final Commande commande;
  final VoidCallback onEdit;
  final void Function(String) onStatutChange;
  final VoidCallback onFacturer;
  final VoidCallback onDelete;
  const _CommandeDetail({required this.commande, required this.onEdit, required this.onStatutChange, required this.onFacturer, required this.onDelete});

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
        Text(c.client, style: TextStyle(color: context.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
        Text(c.modele, style: TextStyle(color: context.textMuted, fontSize: 13)),
        if (c.couturier.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Icon(Icons.content_cut, size: 13, color: context.textFaint),
                const SizedBox(width: 5),
                Text(c.couturier, style: TextStyle(color: context.textFaint, fontSize: 12.5)),
              ],
            ),
          ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(color: context.cardBg, borderRadius: BorderRadius.circular(12)),
                child: Column(children: [
                  Text(fmtFcfa(c.montant), style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w700)),
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
                  Text(fmtFcfa(c.avance), style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w700)),
                  Text('AVANCE VERSÉE', style: TextStyle(color: context.textFaint, fontSize: 9)),
                ]),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text('Changer le statut', style: TextStyle(color: context.textMuted, fontSize: 12)),
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
                backgroundColor: context.cardBg,
                labelStyle: TextStyle(color: _statut == s ? Colors.black : context.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                side: BorderSide(color: context.cardBorder),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text('Livraison prévue : ${c.livraison}', style: TextStyle(color: context.textFaint, fontSize: 12)),
        const SizedBox(height: 18),
        GoldButton(label: 'Facturer cette commande', onPressed: widget.onFacturer),
        const SizedBox(height: 10),
        GhostButton(label: 'Modifier cette commande', onPressed: widget.onEdit),
        const SizedBox(height: 10),
        TextButton(
          onPressed: widget.onDelete,
          style: TextButton.styleFrom(foregroundColor: AppColors.rose, padding: EdgeInsets.zero, alignment: Alignment.centerLeft),
          child: Text('Supprimer cette commande', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

/// Aperçu du message avant envoi — modifiable, puis ouvre WhatsApp direct
/// sur la conversation du client avec ce texte déjà rempli.
class _MessageWhatsappForm extends StatefulWidget {
  final String telephone;
  final String messageInitial;
  const _MessageWhatsappForm({required this.telephone, required this.messageInitial});

  @override
  State<_MessageWhatsappForm> createState() => _MessageWhatsappFormState();
}

class _MessageWhatsappFormState extends State<_MessageWhatsappForm> {
  late final TextEditingController _messageCtrl;
  bool _envoi = false;

  @override
  void initState() {
    super.initState();
    _messageCtrl = TextEditingController(text: widget.messageInitial);
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _ouvrir() async {
    setState(() => _envoi = true);
    final ok = await WhatsappService.ouvrirConversation(numero: widget.telephone, message: _messageCtrl.text.trim());
    if (!mounted) return;
    setState(() => _envoi = false);
    if (ok) {
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Impossible d'ouvrir WhatsApp — vérifiez que l'application est installée.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('La commande est marquée "Prête" — un message peut être envoyé au client sur WhatsApp (${widget.telephone}).',
            style: TextStyle(color: context.textFaint, fontSize: 12.5)),
        const SizedBox(height: 14),
        Text('Message', style: TextStyle(color: context.textMuted, fontSize: 12)),
        const SizedBox(height: 6),
        TextField(controller: _messageCtrl, maxLines: 5, decoration: const InputDecoration()),
        const SizedBox(height: 18),
        GoldButton(label: _envoi ? 'Ouverture…' : 'Ouvrir WhatsApp', icon: Icons.chat_bubble_outline, onPressed: _envoi ? () {} : _ouvrir),
        const SizedBox(height: 10),
        GhostButton(label: 'Ne pas envoyer maintenant', onPressed: () => Navigator.of(context).pop()),
      ],
    );
  }
}
