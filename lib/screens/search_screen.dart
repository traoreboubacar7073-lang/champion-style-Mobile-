import 'package:flutter/material.dart';
import '../data/repository.dart';
import '../models/client.dart';
import '../models/commande.dart';
import '../models/facture.dart';
import '../models/devis.dart';
import '../models/employe.dart';
import '../models/fournisseur.dart';
import '../models/modele.dart';
import '../models/stock.dart';
import '../models/paiement.dart';
import '../models/depense.dart';
import '../models/boutique.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

/// Recherche globale — cherche en même temps parmi les clients, les
/// commandes, les factures, les devis, les employés, les fournisseurs,
/// les produits et le stock. Même principe que la barre de recherche des
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
  List<Devis> _allDevis = [];
  List<Employe> _allEmployes = [];
  List<Fournisseur> _allFournisseurs = [];
  List<Modele> _allModeles = [];
  List<StockItem> _allStock = [];
  List<Paiement> _allPaiements = [];
  List<Depense> _allDepenses = [];
  List<ArticleBoutique> _allArticlesBoutique = [];
  List<VenteBoutique> _allVentesBoutique = [];
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
    final devis = await DevisRepository().all();
    final employes = await EmployeRepository().all();
    final fournisseurs = await FournisseurRepository().all();
    final modeles = await ModeleRepository().all();
    final stock = await StockRepository().all();
    final paiements = await PaiementRepository().all();
    final depenses = await DepenseRepository().all();
    final articlesBoutique = await ArticleBoutiqueRepository().all();
    final ventesBoutique = await VenteBoutiqueRepository().all();
    if (!mounted) return;
    setState(() {
      _allClients = clients;
      _allCommandes = commandes;
      _allFactures = factures;
      _allDevis = devis;
      _allEmployes = employes;
      _allFournisseurs = fournisseurs;
      _allModeles = modeles;
      _allStock = stock;
      _allPaiements = paiements;
      _allDepenses = depenses;
      _allArticlesBoutique = articlesBoutique;
      _allVentesBoutique = ventesBoutique;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String get _q => _query.toLowerCase();

  List<Client> get _clientResults =>
      _q.isEmpty ? [] : _allClients.where((c) => c.nom.toLowerCase().contains(_q) || c.tel.toLowerCase().contains(_q)).take(5).toList();

  List<Commande> get _commandeResults => _q.isEmpty
      ? []
      : _allCommandes.where((c) => c.id.toLowerCase().contains(_q) || c.client.toLowerCase().contains(_q) || c.modele.toLowerCase().contains(_q)).take(5).toList();

  List<Facture> get _factureResults =>
      _q.isEmpty ? [] : _allFactures.where((f) => f.id.toLowerCase().contains(_q) || f.client.toLowerCase().contains(_q)).take(5).toList();

  List<Devis> get _devisResults =>
      _q.isEmpty ? [] : _allDevis.where((d) => d.id.toLowerCase().contains(_q) || d.client.toLowerCase().contains(_q)).take(5).toList();

  List<Employe> get _employeResults =>
      _q.isEmpty ? [] : _allEmployes.where((e) => e.nom.toLowerCase().contains(_q) || e.poste.toLowerCase().contains(_q)).take(5).toList();

  List<Fournisseur> get _fournisseurResults =>
      _q.isEmpty ? [] : _allFournisseurs.where((f) => f.nom.toLowerCase().contains(_q) || f.ville.toLowerCase().contains(_q)).take(5).toList();

  List<Modele> get _modeleResults =>
      _q.isEmpty ? [] : _allModeles.where((m) => m.nom.toLowerCase().contains(_q) || m.categorie.toLowerCase().contains(_q)).take(5).toList();

  List<StockItem> get _stockResults =>
      _q.isEmpty ? [] : _allStock.where((s) => s.nom.toLowerCase().contains(_q) || s.type.toLowerCase().contains(_q)).take(5).toList();

  List<Paiement> get _paiementResults =>
      _q.isEmpty ? [] : _allPaiements.where((p) => p.client.toLowerCase().contains(_q) || p.reference.toLowerCase().contains(_q)).take(5).toList();

  List<Depense> get _depenseResults =>
      _q.isEmpty ? [] : _allDepenses.where((d) => d.categorie.toLowerCase().contains(_q) || d.fournisseur.toLowerCase().contains(_q)).take(5).toList();

  List<ArticleBoutique> get _articleBoutiqueResults =>
      _q.isEmpty ? [] : _allArticlesBoutique.where((a) => a.nom.toLowerCase().contains(_q) || a.categorie.toLowerCase().contains(_q)).take(5).toList();

  List<VenteBoutique> get _venteBoutiqueResults =>
      _q.isEmpty ? [] : _allVentesBoutique.where((v) => v.article.toLowerCase().contains(_q) || v.categorie.toLowerCase().contains(_q)).take(5).toList();

  @override
  Widget build(BuildContext context) {
    final totalResults = _clientResults.length + _commandeResults.length + _factureResults.length + _devisResults.length +
        _employeResults.length + _fournisseurResults.length + _modeleResults.length + _stockResults.length +
        _paiementResults.length + _depenseResults.length + _articleBoutiqueResults.length + _venteBoutiqueResults.length;

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
              hintText: 'Client, commande, produit, stock…',
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
              ? const EmptyState(icon: Icons.search, text: 'Recherche dans tous les modules :\nclients, commandes, produits, stock…')
              : totalResults == 0
                  ? EmptyState(icon: Icons.search_off, text: 'Aucun résultat pour « $_query ».')
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (_clientResults.isNotEmpty) ..._section(context, 'Clients', Icons.people_outline, [
                          for (final c in _clientResults)
                            _ResultTile(title: c.nom, subtitle: c.tel.isEmpty ? 'Sans téléphone' : c.tel, onTap: () => Navigator.pop(context)),
                        ]),
                        if (_commandeResults.isNotEmpty) ..._section(context, 'Commandes', Icons.shopping_bag_outlined, [
                          for (final c in _commandeResults)
                            _ResultTile(title: '${c.id} — ${c.client}', subtitle: c.modele, trailing: StatutBadge(statut: c.statut), onTap: () => Navigator.pop(context)),
                        ]),
                        if (_factureResults.isNotEmpty) ..._section(context, 'Factures', Icons.receipt_long_outlined, [
                          for (final f in _factureResults)
                            _ResultTile(title: '${f.id} — ${f.client}', subtitle: fmtFcfa(f.montant), trailing: StatutBadge(statut: f.statut), onTap: () => Navigator.pop(context)),
                        ]),
                        if (_devisResults.isNotEmpty) ..._section(context, 'Devis', Icons.description_outlined, [
                          for (final d in _devisResults)
                            _ResultTile(title: '${d.id} — ${d.client}', subtitle: fmtFcfa(d.montant), trailing: StatutBadge(statut: d.statut), onTap: () => Navigator.pop(context)),
                        ]),
                        if (_employeResults.isNotEmpty) ..._section(context, 'Employés', Icons.manage_accounts_outlined, [
                          for (final e in _employeResults) _ResultTile(title: e.nom, subtitle: e.poste, onTap: () => Navigator.pop(context)),
                        ]),
                        if (_fournisseurResults.isNotEmpty) ..._section(context, 'Fournisseurs', Icons.local_shipping_outlined, [
                          for (final f in _fournisseurResults) _ResultTile(title: f.nom, subtitle: f.ville, onTap: () => Navigator.pop(context)),
                        ]),
                        if (_modeleResults.isNotEmpty) ..._section(context, 'Produits & Services', Icons.checkroom_outlined, [
                          for (final m in _modeleResults) _ResultTile(title: m.nom, subtitle: '${m.categorie} · ${fmtFcfa(m.prix)}', onTap: () => Navigator.pop(context)),
                        ]),
                        if (_stockResults.isNotEmpty) ..._section(context, 'Stock & Matières', Icons.inventory_2_outlined, [
                          for (final s in _stockResults)
                            _ResultTile(title: s.nom, subtitle: '${s.qte.toStringAsFixed(0)} ${s.unite}', trailing: s.bas ? const Icon(Icons.warning_amber_rounded, color: AppColors.rose, size: 16) : null, onTap: () => Navigator.pop(context)),
                        ]),
                        if (_paiementResults.isNotEmpty) ..._section(context, 'Paiements', Icons.credit_card_outlined, [
                          for (final p in _paiementResults)
                            _ResultTile(title: p.client, subtitle: '${p.mode} · ${p.date}', trailing: Text(fmtFcfa(p.montant), style: const TextStyle(color: AppColors.deepGreen, fontWeight: FontWeight.w700, fontSize: 12.5)), onTap: () => Navigator.pop(context)),
                        ]),
                        if (_depenseResults.isNotEmpty) ..._section(context, 'Dépenses', Icons.account_balance_wallet_outlined, [
                          for (final d in _depenseResults)
                            _ResultTile(title: d.categorie, subtitle: d.fournisseur.isEmpty ? d.date : '${d.fournisseur} · ${d.date}', trailing: Text(fmtFcfa(d.montant), style: const TextStyle(color: AppColors.rose, fontWeight: FontWeight.w700, fontSize: 12.5)), onTap: () => Navigator.pop(context)),
                        ]),
                        if (_articleBoutiqueResults.isNotEmpty) ..._section(context, 'Boutique — Catalogue', Icons.storefront_outlined, [
                          for (final a in _articleBoutiqueResults)
                            _ResultTile(title: a.nom, subtitle: a.categorie, trailing: Text(fmtFcfa(a.prix), style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w700, fontSize: 12.5)), onTap: () => Navigator.pop(context)),
                        ]),
                        if (_venteBoutiqueResults.isNotEmpty) ..._section(context, 'Boutique — Ventes', Icons.point_of_sale_outlined, [
                          for (final v in _venteBoutiqueResults)
                            _ResultTile(title: '${v.article} × ${v.quantite.toStringAsFixed(0)}', subtitle: '${v.categorie} · ${v.date}', trailing: Text('+${fmtFcfa(v.montant)}', style: const TextStyle(color: AppColors.deepGreen, fontWeight: FontWeight.w700, fontSize: 12.5)), onTap: () => Navigator.pop(context)),
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
