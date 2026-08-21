import 'package:flutter/material.dart';
import 'dart:convert';
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
const List<String> taillesPretAPorter = ['XS', 'S', 'M', 'L', 'XL', 'XXL', 'XXXL'];

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

  /// Regroupe les articles du catalogue par catégorie — chaque catégorie
  /// devient un "tiroir" dépliable, avec ses propres articles rangés en
  /// grille (2 colonnes), pour une présentation professionnelle.
  Map<String, List<ArticleBoutique>> get _articlesParCategorie {
    final Map<String, List<ArticleBoutique>> groupes = {};
    for (final a in _articles) {
      groupes.putIfAbsent(a.categorie, () => []).add(a);
    }
    return groupes;
  }

  List<String> get _categoriesTriees => _articlesParCategorie.keys.toList()..sort();

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

  void _ouvrirAjoutArticle({ArticleBoutique? existing}) async {
    await showAppBottomSheet(
      context,
      title: existing != null ? 'Modifier l\'article' : 'Nouvel article de boutique',
      child: _ArticleForm(categoriesDisponibles: _categoriesDisponibles, existing: existing, onSaved: () { Navigator.of(context).pop(); _load(); }),
    );
  }

  /// Fiche détail d'un article — photo affichée en grand, dans ses vraies
  /// proportions (BoxFit.contain : jamais recadrée ni déformée), avec les
  /// actions Modifier / Réapprovisionner / Supprimer.
  void _ouvrirDetailArticle(ArticleBoutique a) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Dialog(
        backgroundColor: context.isDark ? AppColors.surface : AppColors.surfaceLightMode,
        insetPadding: const EdgeInsets.all(18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (a.photo.isNotEmpty)
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.42),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    // BoxFit.contain : la photo garde exactement ses
                    // proportions d'origine — jamais étirée ni rognée.
                    child: Image.memory(base64Decode(a.photo), fit: BoxFit.contain),
                  ),
                )
              else
                Container(
                  height: 140, width: double.infinity,
                  decoration: BoxDecoration(color: context.cardBg, borderRadius: BorderRadius.circular(12)),
                  child: Icon(Icons.storefront_outlined, size: 40, color: context.textFaint),
                ),
              const SizedBox(height: 16),
              Text(a.nom, style: TextStyle(color: context.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(a.taille.isNotEmpty ? '${a.categorie} · Taille ${a.taille}' : a.categorie, style: TextStyle(color: context.textFaint, fontSize: 13)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(fmtFcfa(a.prix), style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w700, fontSize: 20)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: (a.qte <= 0 ? AppColors.rose : AppColors.deepGreen).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${a.qte.toStringAsFixed(a.qte == a.qte.roundToDouble() ? 0 : 1)} en stock',
                      style: TextStyle(color: a.qte <= 0 ? AppColors.rose : AppColors.deepGreen, fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: GhostButton(label: 'Réapprovisionner', onPressed: () {
                      Navigator.of(ctx).pop();
                      _ouvrirReappro(a);
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: GoldButton(label: 'Modifier', onPressed: () {
                      Navigator.of(ctx).pop();
                      _ouvrirAjoutArticle(existing: a);
                    }),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    onPressed: () async {
                      final confirme = await confirmDelete(context, nom: a.nom, typeElement: 'cet article');
                      if (!confirme) return;
                      if (!ctx.mounted) return;
                      Navigator.of(ctx).pop();
                      await ArticleBoutiqueRepository().delete(a);
                      _load();
                    },
                    icon: const Icon(Icons.delete_outline, color: AppColors.rose),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _ouvrirReappro(ArticleBoutique a) async {
    await showAppBottomSheet(
      context,
      title: 'Réapprovisionner',
      child: _ReapproArticleForm(article: a, onDone: () { Navigator.of(context).pop(); _load(); }),
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
                  GoldButton(label: 'Vendre un article', icon: Icons.point_of_sale_outlined, onPressed: _ouvrirVente),
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
                    const SizedBox(height: 14),
                  ],
                  if (_articles.isEmpty)
                    const EmptyState(icon: Icons.storefront_outlined, text: "Aucun article enregistré — ajoute ceux que tu vends en boutique (montres, parfums, tissus...).")
                  else
                    ..._categoriesTriees.map((cat) {
                      final articlesCat = _articlesParCategorie[cat]!;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Theme(
                          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            initiallyExpanded: true,
                            tilePadding: EdgeInsets.zero,
                            childrenPadding: const EdgeInsets.only(top: 10, bottom: 4),
                            collapsedBackgroundColor: Colors.transparent,
                            backgroundColor: Colors.transparent,
                            iconColor: AppColors.gold,
                            collapsedIconColor: AppColors.gold,
                            title: Row(
                              children: [
                                Icon(Icons.folder_open_outlined, size: 16, color: AppColors.gold),
                                const SizedBox(width: 8),
                                Expanded(child: Text(cat, style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w700, fontSize: 14.5))),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(color: AppColors.gold.withOpacity(0.15), borderRadius: BorderRadius.circular(999)),
                                  child: Text('${articlesCat.length}', style: const TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.w700)),
                                ),
                              ],
                            ),
                            children: [
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 0.78,
                                ),
                                itemCount: articlesCat.length,
                                itemBuilder: (ctx, i) {
                                  final a = articlesCat[i];
                                  final stockBas = a.qte <= 0;
                                  return InkWell(
                                    onTap: () => _ouvrirDetailArticle(a),
                                    borderRadius: BorderRadius.circular(14),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: context.cardBg,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: context.cardBorder),
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Stack(
                                              fit: StackFit.expand,
                                              children: [
                                                a.photo.isNotEmpty
                                                    ? Image.memory(base64Decode(a.photo), fit: BoxFit.cover)
                                                    : Container(
                                                        color: context.cardBorder.withOpacity(0.3),
                                                        child: Icon(Icons.storefront_outlined, size: 30, color: context.textFaint),
                                                      ),
                                                Positioned(
                                                  top: 6, right: 6,
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                                    decoration: BoxDecoration(
                                                      color: (stockBas ? AppColors.rose : Colors.black).withOpacity(0.75),
                                                      borderRadius: BorderRadius.circular(999),
                                                    ),
                                                    child: Text(
                                                      stockBas ? 'Rupture' : '${a.qte.toStringAsFixed(a.qte == a.qte.roundToDouble() ? 0 : 1)} en stock',
                                                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(a.nom, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w600, fontSize: 12.5)),
                                                if (a.taille.isNotEmpty)
                                                  Text('Taille ${a.taille}', style: TextStyle(color: context.textFaint, fontSize: 10)),
                                                const SizedBox(height: 2),
                                                Text(fmtFcfa(a.prix), style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w700, fontSize: 12.5)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
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
  final ArticleBoutique? existing;
  final VoidCallback onSaved;
  const _ArticleForm({required this.categoriesDisponibles, this.existing, required this.onSaved});

  @override
  State<_ArticleForm> createState() => _ArticleFormState();
}

class _ArticleFormState extends State<_ArticleForm> {
  final _nomCtrl = TextEditingController();
  final _prixCtrl = TextEditingController();
  final _qteCtrl = TextEditingController();
  String? _categorie;
  String? _taille;
  String? _photo;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final a = widget.existing;
    if (a != null) {
      _nomCtrl.text = a.nom;
      _prixCtrl.text = a.prix == a.prix.roundToDouble() ? a.prix.toStringAsFixed(0) : a.prix.toString();
      _qteCtrl.text = a.qte == a.qte.roundToDouble() ? a.qte.toStringAsFixed(0) : a.qte.toString();
      _categorie = a.categorie;
      _taille = a.taille.isEmpty ? null : a.taille;
      _photo = a.photo.isEmpty ? null : a.photo;
    } else {
      _qteCtrl.text = '0';
    }
  }

  Future<void> _save() async {
    if (_nomCtrl.text.trim().isEmpty || (_categorie ?? '').trim().isEmpty) return;
    setState(() => _saving = true);
    if (widget.existing != null) {
      final updated = ArticleBoutique(
        id: widget.existing!.id,
        nom: _nomCtrl.text.trim(), categorie: _categorie!.trim(),
        prix: double.tryParse(_prixCtrl.text) ?? 0,
        photo: _photo ?? '', taille: _taille ?? '',
        qte: double.tryParse(_qteCtrl.text) ?? 0,
      );
      await ArticleBoutiqueRepository().update(updated);
    } else {
      await ArticleBoutiqueRepository().create(
        nom: _nomCtrl.text.trim(), categorie: _categorie!.trim(),
        prix: double.tryParse(_prixCtrl.text) ?? 0,
        photo: _photo ?? '', taille: _taille ?? '',
        qte: double.tryParse(_qteCtrl.text) ?? 0,
      );
    }
    if (!mounted) return;
    setState(() => _saving = false);
    widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    final estPretAPorter = _categorie == 'Prêt-à-porter';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Photo', style: TextStyle(color: context.textMuted, fontSize: 12)),
        const SizedBox(height: 6),
        PhotoPickerField(initialBase64: _photo, onChanged: (v) => setState(() => _photo = v)),
        const SizedBox(height: 14),
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
        if (estPretAPorter) ...[
          const SizedBox(height: 14),
          Text('Taille', style: TextStyle(color: context.textMuted, fontSize: 12)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _taille,
            dropdownColor: AppColors.surface,
            hint: Text('Choisir une taille…', style: TextStyle(color: context.textFaint)),
            items: [for (final t in taillesPretAPorter) DropdownMenuItem(value: t, child: Text(t, style: TextStyle(color: context.textPrimary)))],
            onChanged: (v) => setState(() => _taille = v),
          ),
        ],
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Prix de vente (FCFA)', style: TextStyle(color: context.textMuted, fontSize: 12)),
                  const SizedBox(height: 6),
                  TextField(controller: _prixCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration()),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Quantité en stock', style: TextStyle(color: context.textMuted, fontSize: 12)),
                  const SizedBox(height: 6),
                  TextField(controller: _qteCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration()),
                ],
              ),
            ),
          ],
        ),
        if (widget.existing != null) ...[
          const SizedBox(height: 6),
          Text('Pour ajouter une livraison reçue sans écraser ce chiffre, utilisez plutôt « Réapprovisionner » depuis la fiche de l\'article.',
              style: TextStyle(color: context.textFaint, fontSize: 11, fontStyle: FontStyle.italic)),
        ],
        const SizedBox(height: 20),
        GoldButton(label: _saving ? 'Enregistrement…' : (widget.existing != null ? 'Enregistrer les modifications' : 'Enregistrer'), onPressed: _saving ? () {} : _save),
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
  String? _taille;
  double? _stockDisponible;
  bool _depuisCatalogue = false;
  final _prixCtrl = TextEditingController(text: '0');
  final _quantiteCtrl = TextEditingController(text: '1');
  String _mode = 'Espèces';
  bool _saving = false;

  void _selectionnerArticleCatalogue(String? nom) {
    setState(() {
      _article = nom;
      final trouve = nom == null ? <ArticleBoutique>[] : widget.articles.where((a) => a.nom == nom).toList();
      if (trouve.isNotEmpty) {
        _depuisCatalogue = true;
        _categorie = trouve.first.categorie;
        _taille = trouve.first.taille.isEmpty ? null : trouve.first.taille;
        _prixCtrl.text = trouve.first.prix.toStringAsFixed(0);
        _stockDisponible = trouve.first.qte;
      } else {
        // Article tapé librement (pas dans le catalogue) — la catégorie
        // (et la taille, le cas échéant) redevient à choisir à la main.
        _depuisCatalogue = false;
        _categorie = null;
        _taille = null;
        _stockDisponible = null;
      }
    });
  }

  Future<void> _save() async {
    final nom = (_article ?? '').trim();
    final prix = double.tryParse(_prixCtrl.text) ?? 0;
    final quantite = double.tryParse(_quantiteCtrl.text) ?? 1;
    if (nom.isEmpty || (_categorie ?? '').trim().isEmpty || prix <= 0 || quantite <= 0) return;
    setState(() => _saving = true);
    await VenteBoutiqueRepository().create(
      article: nom, categorie: _categorie!.trim(), taille: _taille ?? '',
      prixUnitaire: prix, quantite: quantite, mode: _mode,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    final montant = (double.tryParse(_prixCtrl.text) ?? 0) * (double.tryParse(_quantiteCtrl.text) ?? 0);
    final estPretAPorter = _categorie == 'Prêt-à-porter';
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
        if (_stockDisponible != null) ...[
          const SizedBox(height: 6),
          Text(
            _stockDisponible! > 0
                ? '${_stockDisponible!.toStringAsFixed(_stockDisponible! == _stockDisponible!.roundToDouble() ? 0 : 1)} en stock'
                : 'Rupture de stock pour cet article',
            style: TextStyle(color: _stockDisponible! > 0 ? AppColors.deepGreen : AppColors.rose, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
        const SizedBox(height: 14),
        if (_depuisCatalogue) ...[
          // L'article vient du catalogue : sa catégorie (et sa taille, le
          // cas échéant) sont déjà connues — juste affichées, pas la peine
          // de les resaisir.
          Text('Catégorie', style: TextStyle(color: context.textMuted, fontSize: 12)),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(color: context.cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: context.cardBorder)),
            child: Text(_categorie ?? '', style: TextStyle(color: context.textPrimary, fontSize: 13.5)),
          ),
          if (_taille != null) ...[
            const SizedBox(height: 14),
            Text('Taille', style: TextStyle(color: context.textMuted, fontSize: 12)),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(color: context.cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: context.cardBorder)),
              child: Text(_taille!, style: TextStyle(color: context.textPrimary, fontSize: 13.5)),
            ),
          ],
        ] else ...[
          // Article libre (pas dans le catalogue) — la catégorie doit être
          // précisée à la main, et une taille peut être choisie si besoin.
          Text('Catégorie *', style: TextStyle(color: context.textMuted, fontSize: 12)),
          const SizedBox(height: 6),
          CatalogPickerField(
            options: widget.categoriesDisponibles,
            initialValue: _categorie,
            hintText: 'Choisir une catégorie…',
            customHintText: 'Nom de la nouvelle catégorie',
            onChanged: (v) => setState(() => _categorie = v),
          ),
          if (estPretAPorter) ...[
            const SizedBox(height: 14),
            Text('Taille', style: TextStyle(color: context.textMuted, fontSize: 12)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _taille,
              dropdownColor: AppColors.surface,
              hint: Text('Choisir une taille…', style: TextStyle(color: context.textFaint)),
              items: [for (final t in taillesPretAPorter) DropdownMenuItem(value: t, child: Text(t, style: TextStyle(color: context.textPrimary)))],
              onChanged: (v) => setState(() => _taille = v),
            ),
          ],
        ],
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

/// Réapprovisionnement d'un article de boutique — ajoute une quantité au
/// stock existant (sans écraser le chiffre actuel), avec possibilité de
/// créer directement la dépense d'achat correspondante.
class _ReapproArticleForm extends StatefulWidget {
  final ArticleBoutique article;
  final VoidCallback onDone;
  const _ReapproArticleForm({required this.article, required this.onDone});

  @override
  State<_ReapproArticleForm> createState() => _ReapproArticleFormState();
}

class _ReapproArticleFormState extends State<_ReapproArticleForm> {
  final _qteCtrl = TextEditingController();
  final _coutCtrl = TextEditingController();
  final _verseCtrl = TextEditingController();
  bool _saving = false;

  Future<void> _confirm() async {
    final qteAjoutee = double.tryParse(_qteCtrl.text) ?? 0;
    if (qteAjoutee <= 0) return;
    setState(() => _saving = true);
    await ArticleBoutiqueRepository().ajusterStock(widget.article.nom, qteAjoutee);
    final cout = double.tryParse(_coutCtrl.text) ?? 0;
    if (cout > 0) {
      final saisieVerse = double.tryParse(_verseCtrl.text);
      final verse = (saisieVerse ?? cout).clamp(0, cout).toDouble();
      await DepenseRepository().create(
        categorie: 'Achat marchandise boutique (${widget.article.categorie})',
        montant: cout,
        montantVerse: verse,
      );
    }
    if (!mounted) return;
    setState(() => _saving = false);
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${widget.article.nom} · actuellement ${widget.article.qte.toStringAsFixed(widget.article.qte == widget.article.qte.roundToDouble() ? 0 : 1)} en stock',
            style: TextStyle(color: context.textFaint, fontSize: 12)),
        const SizedBox(height: 14),
        Text('Quantité ajoutée *', style: TextStyle(color: context.textMuted, fontSize: 12)),
        const SizedBox(height: 6),
        TextField(controller: _qteCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration()),
        const SizedBox(height: 14),
        Text('Coût total (FCFA)', style: TextStyle(color: context.textMuted, fontSize: 12)),
        const SizedBox(height: 6),
        TextField(controller: _coutCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'Facultatif')),
        const SizedBox(height: 14),
        Text('Montant déjà versé', style: TextStyle(color: context.textMuted, fontSize: 12)),
        const SizedBox(height: 6),
        TextField(controller: _verseCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'Laisser vide si payé en totalité')),
        const SizedBox(height: 20),
        GoldButton(label: _saving ? 'Enregistrement…' : 'Confirmer', onPressed: _saving ? () {} : _confirm),
      ],
    );
  }
}
