import 'package:flutter/material.dart';
import '../data/repository.dart';
import '../models/client.dart';
import '../models/employe.dart';
import '../models/mesures.dart';
import '../models/modele.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  final _repo = ClientRepository();
  List<Client> _clients = [];
  List<Employe> _employes = [];
  List<Modele> _modeles = [];
  bool _loading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final clients = await _repo.all();
    final employes = await EmployeRepository().all();
    final modeles = await ModeleRepository().all();
    if (!mounted) return;
    setState(() {
      _clients = clients;
      _employes = employes;
      _modeles = modeles;
      _loading = false;
    });
  }

  List<Client> get _filtered {
    if (_search.isEmpty) return _clients;
    final q = _search.toLowerCase();
    return _clients.where((c) => c.nom.toLowerCase().contains(q) || c.tel.toLowerCase().contains(q)).toList();
  }

  void _openAddSheet({Client? editing}) async {
    await showAppBottomSheet(
      context,
      title: editing != null ? 'Modifier le client' : 'Nouveau client',
      child: _ClientForm(
        existing: editing,
        employes: _employes,
        modeles: _modeles,
        onSaved: () {
          Navigator.of(context).pop();
          _load();
        },
      ),
    );
  }

  void _openDetail(Client client) async {
    await showAppBottomSheet(
      context,
      title: client.nom,
      child: _ClientDetail(
        client: client,
        onEdit: () {
          Navigator.of(context).pop();
          _openAddSheet(editing: client);
        },
        onDelete: () async {
          await _repo.delete(client);
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
              ScreenHeader(
                eyebrow: "Carnet d'adresses",
                title: 'Clients',
                action: FabRound(onPressed: () => _openAddSheet()),
              ),
              TextField(
                decoration: const InputDecoration(hintText: 'Rechercher un client…', prefixIcon: Icon(Icons.search, size: 18)),
                onChanged: (v) => setState(() => _search = v),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
                    : _filtered.isEmpty
                        ? const EmptyState(icon: Icons.people_outline, text: 'Aucun client pour le moment.')
                        : ListView.separated(
                            itemCount: _filtered.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (ctx, i) {
                              final c = _filtered[i];
                              return AppCard(
                                onTap: () => _openDetail(c),
                                child: Row(
                                  children: [
                                    AppAvatar(name: c.nom),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(c.nom, style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w500, fontSize: 15), overflow: TextOverflow.ellipsis),
                                          Text(
                                            c.tel.isEmpty ? 'Sans téléphone' : c.tel,
                                            style: TextStyle(color: context.textFaint, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (c.sexe.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(999)),
                                        child: Text(c.sexe, style: TextStyle(color: context.textMuted, fontSize: 10)),
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

/// Formulaire d'ajout / modification d'un client, avec la grille de
/// mesures qui change automatiquement selon le sexe choisi.
class _ClientForm extends StatefulWidget {
  final Client? existing;
  final List<Employe> employes;
  final List<Modele> modeles;
  final VoidCallback onSaved;
  const _ClientForm({this.existing, required this.employes, required this.modeles, required this.onSaved});

  @override
  State<_ClientForm> createState() => _ClientFormState();
}

class _ClientFormState extends State<_ClientForm> {
  final _repo = ClientRepository();
  final _nomCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _villeCtrl = TextEditingController();
  String? _sexe;
  final Map<String, TextEditingController> _mesureCtrls = {};
  bool _saving = false;

  // Première commande (facultative), uniquement à la création d'un client.
  String? _cmdModele;
  String? _cmdCouturier;
  final _cmdMontantCtrl = TextEditingController();
  final _cmdAvanceCtrl = TextEditingController();
  String? _cmdPhoto;

  @override
  void initState() {
    super.initState();
    final c = widget.existing;
    if (c != null) {
      _nomCtrl.text = c.nom;
      _telCtrl.text = c.tel;
      _villeCtrl.text = c.ville;
      _sexe = c.sexe.isEmpty ? null : c.sexe;
      for (final entry in c.mesures.entries) {
        _mesureCtrls[entry.key] = TextEditingController(text: '${entry.value}');
      }
    }
    for (final field in [...MesuresGrilles.homme, ...MesuresGrilles.femme]) {
      _mesureCtrls.putIfAbsent(field.key, () => TextEditingController());
    }
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _telCtrl.dispose();
    _villeCtrl.dispose();
    _cmdMontantCtrl.dispose();
    _cmdAvanceCtrl.dispose();
    for (final ctrl in _mesureCtrls.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_nomCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);

    final grille = MesuresGrilles.forSexe(_sexe);
    final Map<String, dynamic> mesures = {};
    for (final field in grille) {
      final raw = _mesureCtrls[field.key]?.text.trim() ?? '';
      if (raw.isEmpty) continue;
      mesures[field.key] = field.isDash ? raw : (num.tryParse(raw) ?? 0);
    }

    if (widget.existing != null) {
      final updated = widget.existing!.copyWith(
        nom: _nomCtrl.text.trim(),
        tel: _telCtrl.text.trim(),
        ville: _villeCtrl.text.trim(),
        sexe: _sexe ?? '',
        mesures: mesures,
      );
      await _repo.update(updated);
    } else {
      final nouveauClient = await _repo.create(
        nom: _nomCtrl.text.trim(),
        tel: _telCtrl.text.trim(),
        ville: _villeCtrl.text.trim(),
        sexe: _sexe ?? '',
        mesures: mesures,
      );

      // Si une première commande a été renseignée, on la crée directement
      // (et sa facture automatiquement si une avance a été versée) — pas
      // besoin de ressaisir le client dans la section Commandes ensuite.
      if ((_cmdModele ?? '').trim().isNotEmpty) {
        final montant = double.tryParse(_cmdMontantCtrl.text) ?? 0;
        final avance = double.tryParse(_cmdAvanceCtrl.text) ?? 0;
        const mois = ['janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin', 'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'];
        final now = DateTime.now();
        final livraison = '${now.day.toString().padLeft(2, '0')} ${mois[now.month - 1]} ${now.year}';
        final commande = await CommandeRepository().create(
          client: nouveauClient.nom,
          modele: _cmdModele!.trim(),
          couturier: _cmdCouturier ?? '',
          livraison: livraison,
          montant: montant,
          avance: avance,
          photo: _cmdPhoto ?? '',
        );
        if (avance > 0) {
          await FactureRepository().creerDepuisCommande(commande);
        }
      }
    }
    if (!mounted) return;
    setState(() => _saving = false);
    widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    final grille = MesuresGrilles.forSexe(_sexe);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Nom complet *', style: TextStyle(color: context.textMuted, fontSize: 12)),
        const SizedBox(height: 6),
        TextField(controller: _nomCtrl, decoration: const InputDecoration(hintText: 'Ex : Awa Sangaré')),
        const SizedBox(height: 14),
        Text('Téléphone', style: TextStyle(color: context.textMuted, fontSize: 12)),
        const SizedBox(height: 6),
        TextField(controller: _telCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(hintText: '+223 …')),
        const SizedBox(height: 14),
        Text('Ville / Quartier', style: TextStyle(color: context.textMuted, fontSize: 12)),
        const SizedBox(height: 6),
        TextField(controller: _villeCtrl, decoration: const InputDecoration(hintText: 'Bamako, …')),
        const SizedBox(height: 14),
        Text('Sexe', style: TextStyle(color: context.textMuted, fontSize: 12)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _sexe,
          dropdownColor: AppColors.surface,
          decoration: const InputDecoration(),
          hint: Text('Choisir…', style: TextStyle(color: context.textFaint)),
          items: [
            DropdownMenuItem(value: 'Femme', child: Text('Femme', style: TextStyle(color: context.textPrimary))),
            DropdownMenuItem(value: 'Homme', child: Text('Homme', style: TextStyle(color: context.textPrimary))),
          ],
          onChanged: (v) => setState(() => _sexe = v),
        ),
        if (grille.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('MESURES ${_sexe?.toUpperCase() ?? ''} (CM) — FACULTATIF',
              style: TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.6)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final field in grille)
                SizedBox(
                  width: (MediaQuery.of(context).size.width - 40 - 16) / 3,
                  child: TextField(
                    controller: _mesureCtrls[field.key],
                    keyboardType: field.isDash ? TextInputType.text : const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(hintText: field.label),
                  ),
                ),
            ],
          ),
        ],
        if (widget.existing == null) ...[
          const SizedBox(height: 20),
          Text('PREMIÈRE COMMANDE — FACULTATIF',
              style: TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.6)),
          const SizedBox(height: 4),
          Text('Si renseigné, la commande (et sa facture si une avance est versée) sera créée automatiquement.',
              style: TextStyle(color: context.textFaint, fontSize: 11.5)),
          const SizedBox(height: 10),
          PhotoPickerField(initialBase64: _cmdPhoto, onChanged: (v) => setState(() => _cmdPhoto = v)),
          const SizedBox(height: 10),
          Text('Modèle', style: TextStyle(color: context.textMuted, fontSize: 12)),
          const SizedBox(height: 6),
          CatalogPickerField(
            options: [for (final m in widget.modeles) m.nom],
            initialValue: _cmdModele,
            hintText: 'Choisir un modèle du catalogue…',
            customHintText: 'Ex : Robe apportée par la cliente',
            onChanged: (v) => setState(() => _cmdModele = v),
          ),
          const SizedBox(height: 12),
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
                  value: _cmdCouturier,
                  dropdownColor: AppColors.surface,
                  isExpanded: true,
                  hint: Text('Choisir un couturier (facultatif)…', style: TextStyle(color: context.textFaint)),
                  items: [for (final e in widget.employes) DropdownMenuItem(value: e.nom, child: Text(e.nom, style: TextStyle(color: context.textPrimary)))],
                  onChanged: (v) => setState(() => _cmdCouturier = v),
                ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Montant total', style: TextStyle(color: context.textMuted, fontSize: 12)),
                    const SizedBox(height: 6),
                    TextField(controller: _cmdMontantCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration()),
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
                    TextField(controller: _cmdAvanceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration()),
                  ],
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 20),
        GoldButton(
          label: _saving ? 'Enregistrement…' : (widget.existing != null ? 'Enregistrer les modifications' : 'Enregistrer'),
          onPressed: _saving ? () {} : _save,
        ),
      ],
    );
  }
}

class _ClientDetail extends StatelessWidget {
  final Client client;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _ClientDetail({required this.client, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final mesuresRenseignees = client.mesures.entries.where((e) {
      final v = e.value;
      if (v is num) return v != 0;
      return v != null && v.toString().isNotEmpty;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (client.tel.isNotEmpty) ...[
              Icon(Icons.phone_outlined, size: 13, color: context.textFaint),
              const SizedBox(width: 4),
              Text(client.tel, style: TextStyle(color: context.textFaint, fontSize: 12)),
              const SizedBox(width: 14),
            ],
            if (client.ville.isNotEmpty) ...[
              Icon(Icons.location_on_outlined, size: 13, color: context.textFaint),
              const SizedBox(width: 4),
              Text(client.ville, style: TextStyle(color: context.textFaint, fontSize: 12)),
            ],
          ],
        ),
        const SizedBox(height: 14),
        GhostButton(label: 'Modifier ce client', onPressed: onEdit),
        const SizedBox(height: 18),
        Text('FICHE DE MESURES (CM)${client.sexe.isNotEmpty ? ' — ${client.sexe.toUpperCase()}' : ''}',
            style: TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.6)),
        const SizedBox(height: 10),
        if (mesuresRenseignees.isEmpty)
          Text('Aucune mesure enregistrée pour ce client.', style: TextStyle(color: context.textFaint, fontSize: 13))
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final entry in mesuresRenseignees)
                Container(
                  width: (MediaQuery.of(context).size.width - 40 - 16) / 3,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(color: context.cardBg, borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: [
                      Text('${entry.value}', style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w700, fontSize: 15)),
                      const SizedBox(height: 2),
                      Text(MesuresGrilles.labels[entry.key] ?? entry.key,
                          style: TextStyle(color: context.textFaint, fontSize: 9)),
                    ],
                  ),
                ),
            ],
          ),
        const SizedBox(height: 20),
        TextButton(
          onPressed: onDelete,
          style: TextButton.styleFrom(foregroundColor: AppColors.rose, padding: EdgeInsets.zero, alignment: Alignment.centerLeft),
          child: Text('Supprimer ce client', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
