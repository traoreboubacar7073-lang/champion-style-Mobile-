import 'package:flutter/material.dart';
import 'dart:convert';
import '../data/repository.dart';
import '../models/modele.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

const List<String> categoriesProduit = ['Robe', 'Boubou', 'Costume', 'Chemise', 'Autre'];

class ProduitsScreen extends StatefulWidget {
  const ProduitsScreen({super.key});

  @override
  State<ProduitsScreen> createState() => _ProduitsScreenState();
}

class _ProduitsScreenState extends State<ProduitsScreen> {
  final _repo = ModeleRepository();
  List<Modele> _modeles = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final modeles = await _repo.all();
    if (!mounted) return;
    setState(() {
      _modeles = modeles;
      _loading = false;
    });
  }

  void _openAdd() async {
    await showAppBottomSheet(
      context,
      title: 'Nouveau produit',
      child: _ModeleForm(onSaved: () { Navigator.of(context).pop(); _load(); }),
    );
  }

  void _openLightbox(Modele m) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (m.photo.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.memory(base64Decode(m.photo), fit: BoxFit.contain),
              ),
            const SizedBox(height: 14),
            Text(m.nom, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600)),
            Text('${m.categorie} · ${fmtFcfa(m.prix)}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(Modele m) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.isDark ? AppColors.surface : AppColors.surfaceLightMode,
        title: Text('Supprimer ce produit ?', style: TextStyle(color: context.textPrimary, fontSize: 16)),
        content: Text('« ${m.nom} » sera déplacé dans la corbeille.', style: TextStyle(color: context.textMuted, fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Annuler', style: TextStyle(color: context.textMuted))),
          TextButton(
            onPressed: () async { await _repo.delete(m); if (!mounted) return; Navigator.pop(ctx); _load(); },
            child: const Text('Supprimer', style: TextStyle(color: AppColors.rose)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Produits & Services')),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
            : _modeles.isEmpty
                ? const EmptyState(icon: Icons.checkroom_outlined, text: 'Aucun produit pour le moment.')
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.72,
                    ),
                    itemCount: _modeles.length,
                    itemBuilder: (ctx, i) {
                      final m = _modeles[i];
                      return InkWell(
                        onTap: () => m.photo.isNotEmpty ? _openLightbox(m) : null,
                        onLongPress: () => _confirmDelete(m),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          decoration: BoxDecoration(
                            color: context.cardBg,
                            borderRadius: BorderRadius.circular(16),
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
                                    m.photo.isNotEmpty
                                        ? Image.memory(base64Decode(m.photo), fit: BoxFit.cover)
                                        : Container(
                                            color: context.cardBg,
                                            child: Icon(Icons.checkroom_outlined, size: 30, color: context.textFaint),
                                          ),
                                    Positioned(
                                      top: 8, left: 8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(999)),
                                        child: Text(m.categorie.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(m.nom, style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 3),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('${m.jours} j', style: TextStyle(color: context.textFaint, fontSize: 11)),
                                        Text(fmtFcfa(m.prix), style: const TextStyle(color: AppColors.gold, fontSize: 12, fontWeight: FontWeight.w700)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
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

class _ModeleForm extends StatefulWidget {
  final VoidCallback onSaved;
  const _ModeleForm({required this.onSaved});

  @override
  State<_ModeleForm> createState() => _ModeleFormState();
}

class _ModeleFormState extends State<_ModeleForm> {
  final _repo = ModeleRepository();
  final _nomCtrl = TextEditingController();
  final _prixCtrl = TextEditingController();
  final _joursCtrl = TextEditingController(text: '1');
  String _categorie = 'Robe';
  String? _photo;
  bool _saving = false;

  Future<void> _save() async {
    if (_nomCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    await _repo.create(
      nom: _nomCtrl.text.trim(),
      categorie: _categorie,
      prix: double.tryParse(_prixCtrl.text) ?? 0,
      jours: int.tryParse(_joursCtrl.text) ?? 1,
      photo: _photo ?? '',
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
        Text('Photo', style: TextStyle(color: context.textMuted, fontSize: 12)),
        const SizedBox(height: 6),
        PhotoPickerField(initialBase64: _photo, onChanged: (v) => setState(() => _photo = v)),
        const SizedBox(height: 14),
        Text('Nom du modèle *', style: TextStyle(color: context.textMuted, fontSize: 12)),
        const SizedBox(height: 6),
        TextField(controller: _nomCtrl, decoration: const InputDecoration(hintText: 'Ex : Robe Bogolan')),
        const SizedBox(height: 14),
        Text('Catégorie', style: TextStyle(color: context.textMuted, fontSize: 12)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _categorie,
          dropdownColor: AppColors.surface,
          items: [for (final c in categoriesProduit) DropdownMenuItem(value: c, child: Text(c, style: TextStyle(color: context.textPrimary)))],
          onChanged: (v) => setState(() => _categorie = v ?? 'Robe'),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Prix (FCFA)', style: TextStyle(color: context.textMuted, fontSize: 12)),
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
                  Text('Délai (jours)', style: TextStyle(color: context.textMuted, fontSize: 12)),
                  const SizedBox(height: 6),
                  TextField(controller: _joursCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration()),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        GoldButton(label: _saving ? 'Enregistrement…' : 'Enregistrer', onPressed: _saving ? () {} : _save),
      ],
    );
  }
}
