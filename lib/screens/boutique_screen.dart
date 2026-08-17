import 'package:flutter/material.dart';
import '../data/repository.dart';
import '../models/boutique.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import '../services/pdf_service.dart';

const List<String> categoriesBoutique = [
  'Tissu', 'Montre', 'Gel de douche', 'Prêt-à-porter', 'Parfum',
  'Bijoux', 'Chaussures', 'Accessoire', 'Autre',
];
const List<String> modesPaiementBoutique = ['Espèces', 'Orange Money', 'Moov Money', 'Virement bancaire', 'Mobicash'];

const List<String> _moisAbbrBoutique = ['janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin', 'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'];

DateTime? _parseFrDateBoutique(String s) {
  final parts = s.trim().split(RegExp(r'\s+'));
  if (parts.length != 3) return null;
  final day = int.tryParse(parts[0]);
  final monthIdx = _moisAbbrBoutique.indexOf(parts[1]);
  final year = int.tryParse(parts[2]);
  if (day == null || monthIdx == -1 || year == null) return null;
  return DateTime(year, monthIdx + 1, day);
}

class _TotauxPeriode {
  final double semaine;
  final double mois;
  final double annee;
  const _TotauxPeriode(this.semaine, this.mois, this.annee);
}

_TotauxPeriode _computeTotauxVentes(List<VenteBoutique> ventes) {
  final now = DateTime.now();
  final startOfWeek = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
  final startOfMonth = DateTime(now.year, now.month, 1);
  final startOfYear = DateTime(now.year, 1, 1);
  double semaine = 0, mois = 0, annee = 0;
  for (final v in ventes) {
    final d = _parseFrDateBoutique(v.date);
    if (d == null) continue;
    if (!d.isBefore(startOfYear)) annee += v.montant;
    if (!d.isBefore(startOfMonth)) mois += v.montant;
    if (!d.isBefore(startOfWeek)) semaine += v.montant;
  }
  return _TotauxPeriode(semaine, mois, annee);
}

class BoutiqueScreen extends StatefulWidget {
  const BoutiqueScreen({super.key});

  @override
  State<BoutiqueScreen> createState() => _BoutiqueScreenState();
}

class _BoutiqueScreenState extends State<BoutiqueScreen> {
  List<ArticleBoutique> _articles = [];
  List<VenteBoutique> _ventes = [];
  bool _loading = true;
  bool _generatingPdf = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final articles = await ArticleBoutiqueRepository().all();
    final ventes = await VenteBoutiqueRepository().all();
    if (!mounted) return;
    setState(() {
      _articles = articles;
      _ventes = ventes;
      _loading = false;
    });
  }

  /// Catégories proposées à la saisie — la liste de base, complétée par
  /// toutes celles déjà utilisées dans le catalogue ou l'historique des
  /// ventes, pour qu'une catégorie ajoutée une fois reste disponible
  /// ensuite sans avoir à la retaper.
  List<String> get _categoriesDisponibles {
    final set = <String>{...categoriesBoutique};
    for (final a in _articles) {
      if (a.categorie.trim().isNotEmpty) set.add(a.categorie.trim());
    }
    for (final v in _ventes) {
      if (v.categorie.trim().isNotEmpty) set.add(v.categorie.trim());
    }
    final liste = set.toList()..sort();
    return liste;
  }

  Future<void> _partagerCataloguePdf() async {
    setState(() => _generatingPdf = true);
    try {
      final bytes = await PdfService.buildCatalogueBoutiquePdf(_articles);
      await PdfService.shareOrDownload(bytes, 'Catalogue_Boutique.pdf');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Une erreur est survenue lors de la génération du document.')));
      }
    } finally {
      if (mounted) setState(() => _generatingPdf = false);
    }
  }

  void _ouvrirVente() async {
    await showAppBottomSheet(
      context,
      title: 'Vendre un article',
      child: _VenteForm(articles: _articles, categoriesDisponibles: _categoriesDisponibles, onSaved: () { Navigator.of(context).pop(); _load(); }),
    );
  }

  void _ouvrirAjoutArticle() async {
    await showAppBottomSheet(
      context,
      title: 'Nouvel article de boutique',
      child: _ArticleForm(categoriesDisponibles: _categoriesDisponibles, onSaved: () { Navigator.of(context).pop(); _load(); }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totaux = _computeTotauxVentes(_ventes);

    // Regroupement par catégorie : nombre d'articles vendus et somme
    // gagnée pour chacune — exactement ce qui a été demandé (combien de
    // montres vendues et la somme globale, combien de parfums, etc.).
    final Map<String, double> montantParCategorie = {};
    final Map<String, double> quantiteParCategorie = {};
    for (final v in _ventes) {
      montantParCategorie[v.categorie] = (montantParCategorie[v.categorie] ?? 0) + v.montant;
      quantiteParCategorie[v.categorie] = (quantiteParCategorie[v.categorie] ?? 0) + v.quantite;
    }
    final categoriesTriees = montantParCategorie.keys.toList()..sort((a, b) => montantParCategorie[b]!.compareTo(montantParCategorie[a]!));

    return Scaffold(
      appBar: AppBar(title: const Text('Boutique')),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    "Vente rapide au comptoir — sans enregistrer de client. Les clients ne sont enregistrés que pour la couture.",
                    style: TextStyle(color: context.textFaint, fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 14),
                  GoldButton(label: '💰  Vendre un article', onPressed: _ouvrirVente),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(child: _MiniTotalBoutique(label: 'Semaine', value: fmtFcfa(totaux.semaine))),
                      const SizedBox(width: 8),
                      Expanded(child: _MiniTotalBoutique(label: 'Mois', value: fmtFcfa(totaux.mois))),
                      const SizedBox(width: 8),
                      Expanded(child: _MiniTotalBoutique(label: 'Année', value: fmtFcfa(totaux.annee))),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text('REVENUS PAR CATÉGORIE', style: TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.1)),
                  const SizedBox(height: 10),
                  if (categoriesTriees.isEmpty)
                    AppCard(child: Text('Aucune vente enregistrée pour le moment.', style: TextStyle(color: context.textFaint, fontSize: 13)))
                  else
                    ...categoriesTriees.map((cat) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: AppCard(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(cat, style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                                      Text('${quantiteParCategorie[cat]!.toStringAsFixed(quantiteParCategorie[cat]! == quantiteParCategorie[cat]!.roundToDouble() ? 0 : 1)} vendu(s)',
                                          style: TextStyle(color: context.textFaint, fontSize: 11.5)),
                                    ],
                                  ),
                                ),
                                Text(fmtFcfa(montantParCategorie[cat]!), style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w700, fontSize: 14)),
                              ],
                            ),
                          ),
                        )),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('CATALOGUE D\'ARTICLES', style: TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.1)),
                      GestureDetector(
                        onTap: _ouvrirAjoutArticle,
                        child: const Text('+ Ajouter', style: TextStyle(color: AppColors.gold, fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (_articles.isNotEmpty) ...[
                    GhostButton(
                      label: _generatingPdf ? 'Génération…' : 'Partager le catalogue (PDF)',
                      onPressed: _generatingPdf ? () {} : _partagerCataloguePdf,
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (_articles.isEmpty)
                    const EmptyState(icon: Icons.storefront_outlined, text: "Aucun article enregistré — ajoute ceux que tu vends en boutique (montres, parfums, tissus...).")
                  else
                    ..._articles.map((a) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: AppCard(
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(a.nom, style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w500, fontSize: 14)),
                                      Text(a.categorie, style: TextStyle(color: context.textFaint, fontSize: 11.5)),
                                    ],
                                  ),
                                ),
                                Text(fmtFcfa(a.prix), style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w600, fontSize: 13)),
                                IconButton(
                                  onPressed: () async {
                                    final confirme = await confirmDelete(context, nom: a.nom, typeElement: 'cet article');
                                    if (!confirme) return;
                                    await ArticleBoutiqueRepository().delete(a);
                                    _load();
                                  },
                                  icon: const Icon(Icons.delete_outline, color: AppColors.rose, size: 18),
                                ),
                              ],
                            ),
                          ),
                        )),
                  const SizedBox(height: 24),
                  Text('VENTES RÉCENTES', style: TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.1)),
                  const SizedBox(height: 10),
                  if (_ventes.isEmpty)
                    const EmptyState(icon: Icons.point_of_sale_outlined, text: 'Aucune vente pour le moment.')
                  else
                    ..._ventes.take(10).map((v) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: AppCard(
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('${v.article} × ${v.quantite.toStringAsFixed(v.quantite == v.quantite.roundToDouble() ? 0 : 1)}',
                                          style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w500, fontSize: 13.5)),
                                      Text('${v.categorie} · ${v.date}', style: TextStyle(color: context.textFaint, fontSize: 11.5)),
                                    ],
                                  ),
                                ),
                                Text('+${fmtFcfa(v.montant)}', style: const TextStyle(color: AppColors.deepGreen, fontWeight: FontWeight.w700, fontSize: 13)),
                                IconButton(
                                  onPressed: () async {
                                    final confirme = await confirmDelete(context, nom: '${v.article} × ${v.quantite.toStringAsFixed(0)}', typeElement: 'cette vente');
                                    if (!confirme) return;
                                    await VenteBoutiqueRepository().delete(v);
                                    _load();
                                  },
                                  icon: const Icon(Icons.delete_outline, color: AppColors.rose, size: 18),
                                ),
                              ],
                            ),
                          ),
                        )),
                ],
              ),
      ),
    );
  }
}

class _MiniTotalBoutique extends StatelessWidget {
  final String label;
  final String value;
  const _MiniTotalBoutique({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(color: context.cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: context.cardBorder)),
      child: Column(
        children: [
          Text(value, style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w700, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(color: context.textFaint, fontSize: 9.5), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _ArticleForm extends StatefulWidget {
  final List<String> categoriesDisponibles;
  final VoidCallback onSaved;
  const _ArticleForm({required this.categoriesDisponibles, required this.onSaved});

  @override
  State<_ArticleForm> createState() => _ArticleFormState();
}

class _ArticleFormState extends State<_ArticleForm> {
  final _nomCtrl = TextEditingController();
  final _prixCtrl = TextEditingController();
  String? _categorie;
  bool _saving = false;

  Future<void> _save() async {
    if (_nomCtrl.text.trim().isEmpty || (_categorie ?? '').trim().isEmpty) return;
    setState(() => _saving = true);
    await ArticleBoutiqueRepository().create(nom: _nomCtrl.text.trim(), categorie: _categorie!.trim(), prix: double.tryParse(_prixCtrl.text) ?? 0);
    if (!mounted) return;
    setState(() => _saving = false);
    widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Nom de l\'article *', style: TextStyle(color: context.textMuted, fontSize: 12)),
        const SizedBox(height: 6),
        TextField(controller: _nomCtrl, decoration: const InputDecoration(hintText: 'Ex : Montre Casio noire')),
        const SizedBox(height: 14),
        Text('Catégorie *', style: TextStyle(color: context.textMuted, fontSize: 12)),
        const SizedBox(height: 6),
        CatalogPickerField(
          options: widget.categoriesDisponibles,
          initialValue: _categorie,
          hintText: 'Choisir une catégorie…',
          customHintText: 'Nom de la nouvelle catégorie',
          onChanged: (v) => setState(() => _categorie = v),
        ),
        const SizedBox(height: 14),
        Text('Prix de vente (FCFA)', style: TextStyle(color: context.textMuted, fontSize: 12)),
        const SizedBox(height: 6),
        TextField(controller: _prixCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration()),
        const SizedBox(height: 20),
        GoldButton(label: _saving ? 'Enregistrement…' : 'Enregistrer', onPressed: _saving ? () {} : _save),
      ],
    );
  }
}

class _VenteForm extends StatefulWidget {
  final List<ArticleBoutique> articles;
  final List<String> categoriesDisponibles;
  final VoidCallback onSaved;
  const _VenteForm({required this.articles, required this.categoriesDisponibles, required this.onSaved});

  @override
  State<_VenteForm> createState() => _VenteFormState();
}

class _VenteFormState extends State<_VenteForm> {
  String? _article;
  String? _categorie;
  final _prixCtrl = TextEditingController(text: '0');
  final _quantiteCtrl = TextEditingController(text: '1');
  String _mode = 'Espèces';
  bool _saving = false;

  void _selectionnerArticleCatalogue(String? nom) {
    setState(() {
      _article = nom;
      if (nom != null) {
        final trouve = widget.articles.where((a) => a.nom == nom);
        if (trouve.isNotEmpty) {
          _categorie = trouve.first.categorie;
          _prixCtrl.text = trouve.first.prix.toStringAsFixed(0);
        }
      }
    });
  }

  Future<void> _save() async {
    final nom = (_article ?? '').trim();
    final prix = double.tryParse(_prixCtrl.text) ?? 0;
    final quantite = double.tryParse(_quantiteCtrl.text) ?? 1;
    if (nom.isEmpty || (_categorie ?? '').trim().isEmpty || prix <= 0 || quantite <= 0) return;
    setState(() => _saving = true);
    await VenteBoutiqueRepository().create(article: nom, categorie: _categorie!.trim(), prixUnitaire: prix, quantite: quantite, mode: _mode);
    if (!mounted) return;
    setState(() => _saving = false);
    widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    final montant = (double.tryParse(_prixCtrl.text) ?? 0) * (double.tryParse(_quantiteCtrl.text) ?? 0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Article *', style: TextStyle(color: context.textMuted, fontSize: 12)),
        const SizedBox(height: 6),
        CatalogPickerField(
          options: [for (final a in widget.articles) a.nom],
          initialValue: _article,
          hintText: 'Choisir dans le catalogue…',
          customHintText: "Nom de l'article",
          onChanged: _selectionnerArticleCatalogue,
        ),
        const SizedBox(height: 14),
        Text('Catégorie *', style: TextStyle(color: context.textMuted, fontSize: 12)),
        const SizedBox(height: 6),
        CatalogPickerField(
          options: widget.categoriesDisponibles,
          initialValue: _categorie,
          hintText: 'Choisir une catégorie…',
          customHintText: 'Nom de la nouvelle catégorie',
          onChanged: (v) => setState(() => _categorie = v),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Prix unitaire *', style: TextStyle(color: context.textMuted, fontSize: 12)),
                  const SizedBox(height: 6),
                  TextField(controller: _prixCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(), onChanged: (_) => setState(() {})),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Quantité', style: TextStyle(color: context.textMuted, fontSize: 12)),
                  const SizedBox(height: 6),
                  TextField(controller: _quantiteCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(), onChanged: (_) => setState(() {})),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text('Mode de paiement', style: TextStyle(color: context.textMuted, fontSize: 12)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _mode,
          dropdownColor: AppColors.surface,
          items: [for (final m in modesPaiementBoutique) DropdownMenuItem(value: m, child: Text(m, style: TextStyle(color: context.textPrimary)))],
          onChanged: (v) => setState(() => _mode = v ?? 'Espèces'),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.gold.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              Text('Montant total', style: TextStyle(color: context.textFaint, fontSize: 11)),
              Text(fmtFcfa(montant), style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w700, fontSize: 20)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GoldButton(label: _saving ? 'Enregistrement…' : 'Confirmer la vente', onPressed: _saving ? () {} : _save),
      ],
    );
  }
}
