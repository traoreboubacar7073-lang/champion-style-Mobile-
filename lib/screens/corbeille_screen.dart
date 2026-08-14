import 'package:flutter/material.dart';
import '../data/repository.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

const Map<String, String> _labelsTable = {
  'clients': 'Client',
  'commandes': 'Commande',
  'modeles': 'Produit',
  'devis': 'Devis',
  'factures': 'Facture',
  'stock': 'Article de stock',
  'depenses': 'Dépense',
  'fournisseurs': 'Fournisseur',
  'employes': 'Employé',
  'paiements_employes': 'Paiement employé',
  'paiements': 'Paiement',
};

String _itemLabel(TrashEntry entry) {
  final item = entry.itemJson;
  return (item['nom'] ?? item['client'] ?? item['categorie'] ?? entry.trashId).toString();
}

class CorbeilleScreen extends StatefulWidget {
  const CorbeilleScreen({super.key});

  @override
  State<CorbeilleScreen> createState() => _CorbeilleScreenState();
}

class _CorbeilleScreenState extends State<CorbeilleScreen> {
  final _repo = TrashRepository();
  List<TrashEntry> _entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final entries = await _repo.all();
    if (!mounted) return;
    setState(() {
      _entries = entries;
      _loading = false;
    });
  }

  Future<void> _restore(TrashEntry e) async {
    await _repo.restore(e.trashId);
    _load();
  }

  Future<void> _deletePermanently(TrashEntry e) async {
    await _repo.deletePermanently(e.trashId);
    _load();
  }

  Future<void> _confirmEmptyAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.isDark ? AppColors.surface : AppColors.surfaceLightMode,
        title: Text('Vider la corbeille ?', style: TextStyle(color: context.textPrimary, fontSize: 16)),
        content: Text('Tous les éléments seront supprimés définitivement, sans possibilité de retour.', style: TextStyle(color: context.textMuted, fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Annuler', style: TextStyle(color: context.textMuted))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Vider', style: TextStyle(color: AppColors.rose))),
        ],
      ),
    );
    if (confirmed == true) {
      await _repo.emptyAll();
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Corbeille'),
        actions: [
          if (_entries.isNotEmpty)
            TextButton(
              onPressed: _confirmEmptyAll,
              child: const Text('Tout vider', style: TextStyle(color: AppColors.rose, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
            : _entries.isEmpty
                ? const EmptyState(icon: Icons.delete_outline, text: 'La corbeille est vide.')
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _entries.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (ctx, i) {
                      final e = _entries[i];
                      final joursRestants = 30 - (DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(e.trashedAt)).inDays);
                      return AppCard(
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text((_labelsTable[e.tableName] ?? e.tableName).toUpperCase(),
                                      style: const TextStyle(color: AppColors.gold, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                                  const SizedBox(height: 2),
                                  Text(_itemLabel(e), style: TextStyle(color: context.textPrimary, fontSize: 14, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 2),
                                  Text(joursRestants > 0 ? 'Purge dans $joursRestants j' : 'Purge imminente', style: TextStyle(color: context.textFaint, fontSize: 11)),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () => _restore(e),
                              child: const Text('Restaurer', style: TextStyle(color: AppColors.deepGreen, fontWeight: FontWeight.w600, fontSize: 12.5)),
                            ),
                            TextButton(
                              onPressed: () => _deletePermanently(e),
                              child: const Text('Supprimer', style: TextStyle(color: AppColors.rose, fontWeight: FontWeight.w600, fontSize: 12.5)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
