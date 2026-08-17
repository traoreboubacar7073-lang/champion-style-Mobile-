import 'package:flutter/material.dart';
import '../data/repository.dart';
import '../models/fournisseur.dart';
import '../models/stock.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class FournisseursScreen extends StatefulWidget {
  const FournisseursScreen({super.key});

  @override
  State<FournisseursScreen> createState() => _FournisseursScreenState();
}

class _FournisseursScreenState extends State<FournisseursScreen> {
  final _repo = FournisseurRepository();
  List<Fournisseur> _fournisseurs = [];
  List<StockItem> _stock = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final fournisseurs = await _repo.all();
    final stock = await StockRepository().all();
    if (!mounted) return;
    setState(() {
      _fournisseurs = fournisseurs;
      _stock = stock;
      _loading = false;
    });
  }

  void _openAdd({Fournisseur? existing}) async {
    await showAppBottomSheet(
      context,
      title: existing != null ? 'Modifier le fournisseur' : 'Nouveau fournisseur',
      child: _FournisseurForm(existing: existing, onSaved: () { Navigator.of(context).pop(); _load(); }),
    );
  }

  void _openDetail(Fournisseur f) async {
    final articles = _stock.where((s) => s.fournisseur == f.nom).toList();
    await showAppBottomSheet(
      context,
      title: f.nom,
      child: _FournisseurDetail(
        fournisseur: f,
        articles: articles,
        onEdit: () {
          Navigator.of(context).pop();
          _openAdd(existing: f);
        },
        onDelete: () async {
          final confirme = await confirmDelete(context, nom: f.nom, typeElement: 'ce fournisseur');
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
      appBar: AppBar(title: const Text('Fournisseurs')),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
            : _fournisseurs.isEmpty
                ? const EmptyState(icon: Icons.local_shipping_outlined, text: 'Aucun fournisseur pour le moment.')
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _fournisseurs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (ctx, i) {
                      final f = _fournisseurs[i];
                      final nb = _stock.where((s) => s.fournisseur == f.nom).length;
                      return AppCard(
                        onTap: () => _openDetail(f),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(f.nom, style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w500, fontSize: 15)),
                            const SizedBox(height: 3),
                            Text('${f.contact}${f.ville.isNotEmpty ? " · ${f.ville}" : ""}', style: TextStyle(color: context.textFaint, fontSize: 12)),
                            const SizedBox(height: 8),
                            Text('$nb article${nb > 1 ? "s" : ""} en stock', style: const TextStyle(color: AppColors.gold, fontSize: 11.5, fontWeight: FontWeight.w600)),
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

class _FournisseurForm extends StatefulWidget {
  final Fournisseur? existing;
  final VoidCallback onSaved;
  const _FournisseurForm({this.existing, required this.onSaved});

  @override
  State<_FournisseurForm> createState() => _FournisseurFormState();
}

class _FournisseurFormState extends State<_FournisseurForm> {
  final _repo = FournisseurRepository();
  final _nomCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  final _villeCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final f = widget.existing;
    if (f != null) {
      _nomCtrl.text = f.nom;
      _contactCtrl.text = f.contact;
      _villeCtrl.text = f.ville;
    }
  }

  Future<void> _save() async {
    if (_nomCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    if (widget.existing != null) {
      final updated = Fournisseur(id: widget.existing!.id, nom: _nomCtrl.text.trim(), contact: _contactCtrl.text.trim(), ville: _villeCtrl.text.trim());
      await _repo.update(updated);
    } else {
      await _repo.create(nom: _nomCtrl.text.trim(), contact: _contactCtrl.text.trim(), ville: _villeCtrl.text.trim());
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
        Text('Nom *', style: TextStyle(color: context.textMuted, fontSize: 12)),
        const SizedBox(height: 6),
        TextField(controller: _nomCtrl, decoration: const InputDecoration()),
        const SizedBox(height: 14),
        Text('Contact', style: TextStyle(color: context.textMuted, fontSize: 12)),
        const SizedBox(height: 6),
        TextField(controller: _contactCtrl, decoration: const InputDecoration(hintText: '+223 …')),
        const SizedBox(height: 14),
        Text('Ville', style: TextStyle(color: context.textMuted, fontSize: 12)),
        const SizedBox(height: 6),
        TextField(controller: _villeCtrl, decoration: const InputDecoration()),
        const SizedBox(height: 20),
        GoldButton(label: _saving ? 'Enregistrement…' : (widget.existing != null ? 'Enregistrer les modifications' : 'Enregistrer'), onPressed: _saving ? () {} : _save),
      ],
    );
  }
}

class _FournisseurDetail extends StatelessWidget {
  final Fournisseur fournisseur;
  final List<StockItem> articles;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _FournisseurDetail({required this.fournisseur, required this.articles, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${fournisseur.contact}${fournisseur.ville.isNotEmpty ? " · ${fournisseur.ville}" : ""}', style: TextStyle(color: context.textFaint, fontSize: 12.5)),
        const SizedBox(height: 16),
        Text('ARTICLES FOURNIS', style: TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.6)),
        const SizedBox(height: 10),
        if (articles.isEmpty)
          Text('Aucun article de stock lié à ce fournisseur.', style: TextStyle(color: context.textFaint, fontSize: 13))
        else
          ...articles.map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(color: context.cardBg, borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(a.nom, style: TextStyle(color: context.textPrimary, fontSize: 13)),
                      Text('${a.qte.toStringAsFixed(0)} ${a.unite}', style: TextStyle(color: context.textFaint, fontSize: 12)),
                    ],
                  ),
                ),
              )),
        const SizedBox(height: 16),
        GhostButton(label: 'Modifier ce fournisseur', onPressed: onEdit),
        const SizedBox(height: 10),
        TextButton(
          onPressed: onDelete,
          style: TextButton.styleFrom(foregroundColor: AppColors.rose, padding: EdgeInsets.zero, alignment: Alignment.centerLeft),
          child: const Text('Supprimer ce fournisseur', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
