import 'package:flutter/material.dart';
import '../data/repository.dart';
import '../models/client.dart';
import '../models/commande.dart';
import '../models/facture.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

/// Recherche globale — cherche en même temps parmi les clients, les
/// commandes et les factures, et permet d'aller directement au bon
/// endroit en un tap. Même principe que la barre de recherche des
/// versions ordinateur et web mobile.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  List<Client> _allClients = [];
  List<Commande> _allCommandes = [];
  List<Facture> _allFactures = [];
  bool _loading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadAll();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  Future<void> _loadAll() async {
    final clients = await ClientRepository().all();
    final commandes = await CommandeRepository().all();
    final factures = await FactureRepository().all();
    if (!mounted) return;
    setState(() {
      _allClients = clients;
      _allCommandes = commandes;
      _allFactures = factures;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  List<Client> get _clientResults {
    final q = _query.toLowerCase();
    if (q.isEmpty) return [];
    return _allClients.where((c) => c.nom.toLowerCase().contains(q) || c.tel.toLowerCase().contains(q)).take(6).toList();
  }

  List<Commande> get _commandeResults {
    final q = _query.toLowerCase();
    if (q.isEmpty) return [];
    return _allCommandes
        .where((c) => c.id.toLowerCase().contains(q) || c.client.toLowerCase().contains(q) || c.modele.toLowerCase().contains(q))
        .take(6)
        .toList();
  }

  List<Facture> get _factureResults {
    final q = _query.toLowerCase();
    if (q.isEmpty) return [];
    return _allFactures.where((f) => f.id.toLowerCase().contains(q) || f.client.toLowerCase().contains(q)).take(6).toList();
  }

  @override
  Widget build(BuildContext context) {
    final totalResults = _clientResults.length + _commandeResults.length + _factureResults.length;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 12),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            style: TextStyle(color: context.textPrimary, fontSize: 15),
            decoration: const InputDecoration(
              hintText: 'Client, commande, facture…',
              prefixIcon: Icon(Icons.search, size: 20),
              contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 14),
            ),
            onChanged: (v) => setState(() => _query = v.trim()),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
          : _query.isEmpty
              ? const EmptyState(icon: Icons.search, text: 'Tape un nom, un numéro de commande\nou de facture pour commencer.')
              : totalResults == 0
                  ? EmptyState(icon: Icons.search_off, text: 'Aucun résultat pour « $_query ».')
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (_clientResults.isNotEmpty) ..._section(context, 'Clients', Icons.people_outline, [
                          for (final c in _clientResults)
                            _ResultTile(
                              title: c.nom,
                              subtitle: c.tel.isEmpty ? 'Sans téléphone' : c.tel,
                              onTap: () => Navigator.pop(context),
                            ),
                        ]),
                        if (_commandeResults.isNotEmpty) ..._section(context, 'Commandes', Icons.shopping_bag_outlined, [
                          for (final c in _commandeResults)
                            _ResultTile(
                              title: '${c.id} — ${c.client}',
                              subtitle: c.modele,
                              trailing: StatutBadge(statut: c.statut),
                              onTap: () => Navigator.pop(context),
                            ),
                        ]),
                        if (_factureResults.isNotEmpty) ..._section(context, 'Factures', Icons.receipt_long_outlined, [
                          for (final f in _factureResults)
                            _ResultTile(
                              title: '${f.id} — ${f.client}',
                              subtitle: fmtFcfa(f.montant),
                              trailing: StatutBadge(statut: f.statut),
                              onTap: () => Navigator.pop(context),
                            ),
                        ]),
                      ],
                    ),
    );
  }

  List<Widget> _section(BuildContext context, String label, IconData icon, List<Widget> tiles) {
    return [
      Row(
        children: [
          Icon(icon, size: 14, color: AppColors.gold),
          const SizedBox(width: 6),
          Text(label.toUpperCase(), style: const TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.1)),
        ],
      ),
      const SizedBox(height: 8),
      ...tiles.map((t) => Padding(padding: const EdgeInsets.only(bottom: 8), child: t)),
      const SizedBox(height: 12),
    ];
  }
}

class _ResultTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback onTap;
  const _ResultTile({required this.title, required this.subtitle, this.trailing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w500, fontSize: 14), overflow: TextOverflow.ellipsis),
                Text(subtitle, style: TextStyle(color: context.textFaint, fontSize: 12), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
