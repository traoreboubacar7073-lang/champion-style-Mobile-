import 'package:sqflite/sqflite.dart';

/// Génère le prochain identifiant lisible pour une table donnée
/// (ex : C-01, CMD-0001, FA-3301...) — même logique que sur les
/// versions ordinateur et web mobile.
class IdGenerator {
  static const Map<String, String> _prefixes = {
    'clients': 'C',
    'modeles': 'M',
    'commandes': 'CMD',
    'devis': 'DV',
    'factures': 'FA',
    'stock': 'ST',
    'depenses': 'DEP',
    'fournisseurs': 'FRS',
    'employes': 'E',
    'paiements_employes': 'PE',
    'paiements': 'PAY',
  };

  static Future<String> next(Database db, String table) async {
    final prefix = _prefixes[table] ?? 'ID';
    final rows = await db.query(table, columns: ['id']);
    int maxNum = 0;
    final regex = RegExp(r'(\d+)$');
    for (final row in rows) {
      final id = row['id'] as String? ?? '';
      final match = regex.firstMatch(id);
      if (match != null) {
        final n = int.tryParse(match.group(1) ?? '0') ?? 0;
        if (n > maxNum) maxNum = n;
      }
    }
    final next = maxNum + 1;
    if (table == 'commandes') return '$prefix-${next.toString().padLeft(4, '0')}';
    if (table == 'factures') return '$prefix-${3300 + next}';
    if (table == 'devis') return '$prefix-${220 + next}';
    return '$prefix-${next.toString().padLeft(2, '0')}';
  }
}
