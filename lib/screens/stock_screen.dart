import 'package:flutter/material.dart';
import '../data/repository.dart';
import '../models/stock.dart';
import '../models/fournisseur.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

const List<String> typesStock = ['Tissu', 'Fourniture', 'Accessoire'];

class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  final _repo = StockRepository();
  List<StockItem> _items = [];
  List<Fournisseur> _fournisseurs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await _repo.all();
    final fournisseurs = await FournisseurRepository().all();
    if (!mounted) return;
    setState(() {
      _items = items;
      _fournisseurs = fournisseurs;
      _loading = false;
    });
  }

  void _openAdd() async {
    await showAppBottomSheet(
      context,
      title: 'Nouvel article',
      child: _StockForm(fournisseurs: _fournisseurs, onSaved: () { Navigator.of(context).pop(); _load(); }),
    );
  }

  void _openDetail(StockItem item) async {
    await showAppBottomSheet(
      context,
      title: item.nom,
      child: _StockDetail(
        item: item,
        onReappro: () async {
          Navigator.of(context).pop();
          await showAppBottomSheet(
            context,
            title: 'Réapprovisionner',
            child: _ReapproForm(item: item, onDone: () { Navigator.of(context).pop(); _load(); }),
          );
        },
        onDelete: () async {
          await _repo.delete(item);
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
      appBar: AppBar(title: const Text('Stock & Matières')),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
            : _items.isEmpty
                ? const EmptyState(icon: Icons.inventory_2_outlined, text: 'Aucun article en stock.')
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (ctx, i) {
                      final item = _items[i];
                      return AppCard(
                        onTap: () => _openDetail(item),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.nom, style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w500, fontSize: 15)),
                                  Text('${item.type} · ${item.qte.toStringAsFixed(item.qte.truncateToDouble() == item.qte ? 0 : 1)} ${item.unite}',
                                      style: TextStyle(color: context.textFaint, fontSize: 12)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                              decoration: BoxDecoration(
                                color: (item.bas ? AppColors.rose : AppColors.deepGreen).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: (item.bas ? AppColors.rose : AppColors.deepGreen).withOpacity(0.35)),
                              ),
                              child: Text(item.bas ? 'Stock bas' : 'Suffisant',
                                  style: TextStyle(color: item.bas ? AppColors.rose : AppColors.deepGreen, fontSize: 11, fontWeight: FontWeight.w600)),
                            ),
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

class _StockForm extends StatefulWidget {
  final List<Fournisseur> fournisseurs;
  final VoidCallback onSaved;
  const _StockForm({required this.fournisseurs, required this.onSaved});

  @override
  State<_StockForm> createState() => _StockFormState();
}

class _StockFormState extends State<_StockForm> {
  final _repo = StockRepository();
  final _nomCtrl = TextEditingController();
  final _qteCtrl = TextEditingController();
  final _uniteCtrl = TextEditingController(text: 'unités');
  final _seuilCtrl = TextEditingController();
  String? _fournisseur;
  String _type = 'Tissu';
  bool _saving = false;

  Future<void> _save() async {
    if (_nomCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    await _repo.create(
      nom: _nomCtrl.text.trim(),
      type: _type,
      qte: double.tryParse(_qteCtrl.text) ?? 0,
      unite: _uniteCtrl.text.trim().isEmpty ? 'unités' : _uniteCtrl.text.trim(),
      seuil: double.tryParse(_seuilCtrl.text) ?? 0,
      fournisseur: _fournisseur ?? '',
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
        Text('Nom *', style: TextStyle(color: context.textMuted, fontSize: 12)),
        const SizedBox(height: 6),
        TextField(controller: _nomCtrl, decoration: const InputDecoration(hintText: 'Ex : Wax Hollandais')),
        const SizedBox(height: 14),
        Text('Type', style: TextStyle(color: context.textMuted, fontSize: 12)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _type,
          dropdownColor: AppColors.surface,
          items: [for (final t in typesStock) DropdownMenuItem(value: t, child: Text(t, style: TextStyle(color: context.textPrimary)))],
          onChanged: (v) => setState(() => _type = v ?? 'Tissu'),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Quantité', style: TextStyle(color: context.textMuted, fontSize: 12)),
                  const SizedBox(height: 6),
                  TextField(controller: _qteCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration()),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Unité', style: TextStyle(color: context.textMuted, fontSize: 12)),
                  const SizedBox(height: 6),
                  TextField(controller: _uniteCtrl, decoration: const InputDecoration(hintText: 'coupons')),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text("Seuil d'alerte", style: TextStyle(color: context.textMuted, fontSize: 12)),
        const SizedBox(height: 6),
        TextField(controller: _seuilCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration()),
        const SizedBox(height: 14),
        Text('Fournisseur', style: TextStyle(color: context.textMuted, fontSize: 12)),
        const SizedBox(height: 6),
        CatalogPickerField(
          options: [for (final f in widget.fournisseurs) f.nom],
          initialValue: _fournisseur,
          hintText: 'Choisir un fournisseur…',
          customHintText: 'Nom du fournisseur',
          onChanged: (v) => setState(() => _fournisseur = v),
        ),
        const SizedBox(height: 20),
        GoldButton(label: _saving ? 'Enregistrement…' : 'Enregistrer', onPressed: _saving ? () {} : _save),
      ],
    );
  }
}

class _StockDetail extends StatelessWidget {
  final StockItem item;
  final VoidCallback onReappro;
  final VoidCallback onDelete;
  const _StockDetail({required this.item, required this.onReappro, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${item.qte.toStringAsFixed(item.qte.truncateToDouble() == item.qte ? 0 : 1)} ${item.unite} en stock · seuil ${item.seuil.toStringAsFixed(0)}',
            style: TextStyle(color: context.textMuted, fontSize: 13)),
        if (item.fournisseur.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text('Fournisseur : ${item.fournisseur}', style: TextStyle(color: context.textFaint, fontSize: 12)),
        ],
        const SizedBox(height: 16),
        GoldButton(label: 'Réapprovisionner', onPressed: onReappro),
        const SizedBox(height: 10),
        TextButton(
          onPressed: onDelete,
          style: TextButton.styleFrom(foregroundColor: AppColors.rose, padding: EdgeInsets.zero, alignment: Alignment.centerLeft),
          child: const Text('Supprimer cet article', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

class _ReapproForm extends StatefulWidget {
  final StockItem item;
  final VoidCallback onDone;
  const _ReapproForm({required this.item, required this.onDone});

  @override
  State<_ReapproForm> createState() => _ReapproFormState();
}

class _ReapproFormState extends State<_ReapproForm> {
  final _qteCtrl = TextEditingController();
  final _coutCtrl = TextEditingController();
  final _verseCtrl = TextEditingController();
  bool _saving = false;

  Future<void> _confirm() async {
    final qteAjoutee = double.tryParse(_qteCtrl.text) ?? 0;
    if (qteAjoutee <= 0) return;
    setState(() => _saving = true);
    await StockRepository().updateQte(widget.item.id, widget.item.qte + qteAjoutee);
    final cout = double.tryParse(_coutCtrl.text) ?? 0;
    if (cout > 0) {
      final saisieVerse = double.tryParse(_verseCtrl.text);
      final verse = (saisieVerse ?? cout).clamp(0, cout).toDouble();
      await DepenseRepository().create(
        categorie: widget.item.type == 'Tissu' ? 'Achat de tissus' : 'Fournitures (fils, boutons, fermetures...)',
        fournisseur: widget.item.fournisseur,
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
        Text('${widget.item.nom} · actuellement ${widget.item.qte.toStringAsFixed(0)} ${widget.item.unite}',
            style: TextStyle(color: context.textFaint, fontSize: 12)),
        const SizedBox(height: 14),
        Text('Quantité ajoutée *', style: TextStyle(color: context.textMuted, fontSize: 12)),
        const SizedBox(height: 6),
        TextField(controller: _qteCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration()),
        const SizedBox(height: 14),
        Text('Coût total (FCFA)', style: TextStyle(color: context.textMuted, fontSize: 12)),
        const SizedBox(height: 6),
        TextField(controller: _coutCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration()),
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
