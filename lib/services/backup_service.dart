import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:sqflite/sqflite.dart';
import '../data/database.dart';

/// Sauvegarde et restauration complètes des données de l'application —
/// toutes les tables sont exportées dans un seul fichier JSON lisible,
/// que l'on peut partager (WhatsApp, email, Google Drive, clé USB via
/// un gestionnaire de fichiers...) et réimporter plus tard, y compris
/// sur un autre téléphone. C'est le filet de sécurité si le téléphone
/// est perdu, cassé, ou si l'application est supprimée par erreur.
class BackupService {
  BackupService._();

  static const List<String> _tables = [
    'clients', 'modeles', 'commandes', 'devis', 'factures', 'paiements',
    'depenses', 'fournisseurs', 'employes', 'paiements_employes', 'stock',
    'utilisateurs', 'articles_boutique', 'ventes_boutique', 'corbeille', 'parametres',
  ];

  static Future<Map<String, dynamic>> _exportData() async {
    final db = await AppDatabase.instance.database;
    final Map<String, dynamic> data = {
      'application': 'Champions Style',
      'dateExport': DateTime.now().toIso8601String(),
    };
    for (final table in _tables) {
      try {
        data[table] = await db.query(table);
      } catch (_) {
        data[table] = [];
      }
    }
    return data;
  }

  /// Génère le fichier de sauvegarde et ouvre le sélecteur de partage
  /// natif du téléphone pour l'envoyer où l'utilisateur le souhaite.
  static Future<void> partagerSauvegarde() async {
    final data = await _exportData();
    final jsonStr = const JsonEncoder.withIndent('  ').convert(data);
    final dir = await getTemporaryDirectory();
    final horodatage = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
    final file = File('${dir.path}/champions-style-sauvegarde-$horodatage.json');
    await file.writeAsString(jsonStr);
    await Share.shareXFiles([XFile(file.path)], text: 'Sauvegarde Champions Style du $horodatage');
  }

  /// Ouvre le sélecteur de fichier pour choisir une sauvegarde .json à
  /// restaurer. Remplace complètement les données actuelles — à utiliser
  /// avec prudence (une confirmation est demandée côté interface avant).
  static Future<bool> choisirEtRestaurer() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json']);
    if (result == null || result.files.single.path == null) return false;
    final file = File(result.files.single.path!);
    final content = await file.readAsString();
    final Map<String, dynamic> data = jsonDecode(content) as Map<String, dynamic>;
    await _restaurerDonnees(data);
    return true;
  }

  static Future<void> _restaurerDonnees(Map<String, dynamic> data) async {
    final db = await AppDatabase.instance.database;
    await db.transaction((txn) async {
      for (final table in _tables) {
        if (!data.containsKey(table)) continue;
        final rows = data[table];
        if (rows is! List) continue;
        await txn.delete(table);
        for (final row in rows) {
          if (row is Map) {
            await txn.insert(table, Map<String, dynamic>.from(row), conflictAlgorithm: ConflictAlgorithm.replace);
          }
        }
      }
    });
  }
}
