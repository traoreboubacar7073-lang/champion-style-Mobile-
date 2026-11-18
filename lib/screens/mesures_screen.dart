import 'package:flutter/material.dart';
import '../data/repository.dart';
import '../models/client.dart';
import '../models/mesures.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import '../services/pdf_service.dart';

/// Accès direct aux mesures d'un client — distinct de l'écran Clients
/// (qui gère fiche complète, ajout, modification) : ici on va droit au
/// but pour consulter ou partager une fiche de mesures déjà enregistrée.
class MesuresScreen extends StatefulWidget {
  const MesuresScreen({super.key});

  @override
  State<MesuresScreen> createState() => _MesuresScreenState();
}

class _MesuresScreenState extends State<MesuresScreen> {
  List<Client> _clients = [];
  bool _loading = true;
  String _recherche = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final clients = await ClientRepository().all();
    if (!mounted) return;
    setState(() {
      _clients = clients;
      _loading = false;
    });
  }

  bool _aDesMesures(Client c) => c.mesures.entries.any((e) {
        final v = e.value;
        if (v is num) return v != 0;
        return v != null && v.toString().isNotEmpty;
      });

  void _ouvrir(Client c) {
    showAppBottomSheet(
      context,
      title: c.nom,
      child: _FicheMesures(client: c),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppColors.gold));

    final recherche = _recherche.trim().toLowerCase();
    final filtres = _clients.where((client) {
      return _aDesMesures(client) &&
          [client.nom, client.tel, client.id]
              .any((champ) => champ.toLowerCase().contains(recherche));
    }).toList();

    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, scrolledUnderElevation: 0),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ScreenHeader(eyebrow: 'Clients', title: 'Mesures enregistrées'),
              TextField(
                decoration: const InputDecoration(hintText: 'Rechercher un client…', prefixIcon: Icon(Icons.search, size: 18)),
                onChanged: (v) => setState(() => _recherche = v),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: filtres.isEmpty
                    ? const EmptyState(icon: Icons.straighten_outlined, text: 'Aucune fiche de mesures trouvée.')
                    : ListView.separated(
                        itemCount: filtres.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (ctx, i) {
                          final c = filtres[i];
                          return AppCard(
                            onTap: () => _ouvrir(c),
                            child: Row(
                              children: [
                                AppAvatar(name: c.nom),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(c.nom, style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w500, fontSize: 14.5)),
                                      const SizedBox(height: 2),
                                      Text(
                                        c.tel.isEmpty ? c.id : c.tel,
                                        style: TextStyle(color: context.textFaint, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.chevron_right, color: context.textFaint, size: 20),
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

class _FicheMesures extends StatefulWidget {
  final Client client;
  const _FicheMesures({required this.client});

  @override
  State<_FicheMesures> createState() => _FicheMesuresState();
}

class _FicheMesuresState extends State<_FicheMesures> {
  bool _partageEnCours = false;

  Future<void> _partager() async {
    setState(() => _partageEnCours = true);
    try {
      final bytes = await PdfService.buildFicheMesuresPdf(
        client: widget.client.nom, sexe: widget.client.sexe,
        mesures: widget.client.mesures, labels: MesuresGrilles.labels,
      );
      await PdfService.shareOrDownload(bytes, 'Mesures_${widget.client.nom.replaceAll(' ', '_')}.pdf');
    } finally {
      if (mounted) setState(() => _partageEnCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mesuresRenseignees = widget.client.mesures.entries.where((e) {
      final v = e.value;
      if (v is num) return v != 0;
      return v != null && v.toString().isNotEmpty;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.client.sexe.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(widget.client.sexe.toUpperCase(), style: const TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.1)),
          ),
        if (mesuresRenseignees.isEmpty)
          Text('Aucune mesure enregistrée pour ce client — à ajouter depuis sa fiche dans Clients.', style: TextStyle(color: context.textFaint, fontSize: 13))
        else
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final entry in mesuresRenseignees)
                Container(
                  width: 96,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  decoration: BoxDecoration(color: context.cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: context.cardBorder)),
                  child: Column(
                    children: [
                      Text('${entry.value}', style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w700, fontSize: 15)),
                      const SizedBox(height: 3),
                      Text((MesuresGrilles.labels[entry.key] ?? entry.key).toUpperCase(), style: TextStyle(color: context.textFaint, fontSize: 9.5)),
                    ],
                  ),
                ),
            ],
          ),
        const SizedBox(height: 20),
        if (mesuresRenseignees.isNotEmpty)
          GoldButton(
            label: _partageEnCours ? 'Préparation…' : 'Partager la fiche de mesures (PDF)',
            icon: Icons.share_outlined,
            onPressed: _partageEnCours ? () {} : _partager,
          ),
      ],
    );
  }
}
