import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'database.dart';
import 'id_generator.dart';
import '../models/client.dart';
import '../models/commande.dart';
import '../models/facture.dart';
import '../models/paiement.dart';
import '../models/depense.dart';
import '../models/utilisateur.dart';
import '../models/modele.dart';
import '../models/stock.dart';
import '../models/devis.dart';
import '../models/fournisseur.dart';
import '../models/employe.dart';

/// Un élément dans la corbeille — garde le nom de la table d'origine et
/// le contenu complet de la ligne, pour pouvoir la restaurer telle quelle.
class TrashEntry {
  final String trashId;
  final String tableName;
  final Map<String, dynamic> itemJson;
  final int trashedAt;

  TrashEntry({
    required this.trashId,
    required this.tableName,
    required this.itemJson,
    required this.trashedAt,
  });

  factory TrashEntry.fromMap(Map<String, dynamic> map) => TrashEntry(
        trashId: map['trashId'] as String,
        tableName: map['tableName'] as String,
        itemJson: Map<String, dynamic>.from(jsonDecode(map['itemJson'] as String) as Map),
        trashedAt: map['trashedAt'] as int,
      );
}

class TrashRepository {
  Future<Database> get _db async => AppDatabase.instance.database;

  Future<void> moveToTrash(String tableName, Map<String, dynamic> item) async {
    final db = await _db;
    final trashId = 'TR-${DateTime.now().millisecondsSinceEpoch}';
    await db.insert('corbeille', {
      'trashId': trashId,
      'tableName': tableName,
      'itemJson': jsonEncode(item),
      'trashedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<List<TrashEntry>> all() async {
    final db = await _db;
    final rows = await db.query('corbeille', orderBy: 'trashedAt DESC');
    return rows.map((r) => TrashEntry.fromMap(r)).toList();
  }

  Future<void> restore(String trashId) async {
    final db = await _db;
    final rows = await db.query('corbeille', where: 'trashId = ?', whereArgs: [trashId]);
    if (rows.isEmpty) return;
    final entry = TrashEntry.fromMap(rows.first);
    await db.insert(entry.tableName, entry.itemJson, conflictAlgorithm: ConflictAlgorithm.replace);
    await db.delete('corbeille', where: 'trashId = ?', whereArgs: [trashId]);
  }

  Future<void> deletePermanently(String trashId) async {
    final db = await _db;
    await db.delete('corbeille', where: 'trashId = ?', whereArgs: [trashId]);
  }

  Future<void> emptyAll() async {
    final db = await _db;
    await db.delete('corbeille');
  }

  /// Supprime les éléments de plus de 30 jours — à appeler au démarrage
  /// de l'application, comme sur les autres versions.
  Future<void> purgeExpired() async {
    final db = await _db;
    final cutoff = DateTime.now().subtract(const Duration(days: 30)).millisecondsSinceEpoch;
    await db.delete('corbeille', where: 'trashedAt < ?', whereArgs: [cutoff]);
  }
}

class ClientRepository {
  final _trash = TrashRepository();
  Future<Database> get _db async => AppDatabase.instance.database;

  Future<List<Client>> all() async {
    final db = await _db;
    final rows = await db.query('clients', orderBy: 'rowid DESC');
    return rows.map((r) => Client.fromMap(r)).toList();
  }

  Future<Client> create({
    required String nom,
    String tel = '',
    String ville = '',
    String sexe = '',
    Map<String, dynamic>? mesures,
  }) async {
    final db = await _db;
    final id = await IdGenerator.next(db, 'clients');
    final depuis = _todayFr();
    final client = Client(id: id, nom: nom, tel: tel, ville: ville, sexe: sexe, depuis: depuis, mesures: mesures);
    await db.insert('clients', client.toMap());
    return client;
  }

  Future<void> update(Client client) async {
    final db = await _db;
    await db.update('clients', client.toMap(), where: 'id = ?', whereArgs: [client.id]);
  }

  Future<void> delete(Client client) async {
    final db = await _db;
    await _trash.moveToTrash('clients', client.toMap());
    await db.delete('clients', where: 'id = ?', whereArgs: [client.id]);
  }
}

class CommandeRepository {
  final _trash = TrashRepository();
  Future<Database> get _db async => AppDatabase.instance.database;

  Future<List<Commande>> all() async {
    final db = await _db;
    final rows = await db.query('commandes', orderBy: 'rowid DESC');
    return rows.map((r) => Commande.fromMap(r)).toList();
  }

  Future<Commande> create({
    required String client,
    required String modele,
    String couturier = '',
    String statut = 'Nouvelle',
    String dateEssayage = '',
    required String livraison,
    double montant = 0,
    double avance = 0,
    String photo = '',
  }) async {
    final db = await _db;
    final id = await IdGenerator.next(db, 'commandes');
    final commande = Commande(
      id: id, client: client, modele: modele, couturier: couturier, statut: statut,
      dateEssayage: dateEssayage, livraison: livraison, montant: montant, avance: avance, photo: photo,
    );
    await db.insert('commandes', commande.toMap());
    return commande;
  }

  Future<void> update(Commande commande) async {
    final db = await _db;
    await db.update('commandes', commande.toMap(), where: 'id = ?', whereArgs: [commande.id]);
  }

  Future<void> updateStatut(String id, String statut) async {
    final db = await _db;
    await db.update('commandes', {'statut': statut}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> delete(Commande commande) async {
    final db = await _db;
    await _trash.moveToTrash('commandes', commande.toMap());
    await db.delete('commandes', where: 'id = ?', whereArgs: [commande.id]);
  }
}

class FactureRepository {
  Future<Database> get _db async => AppDatabase.instance.database;
  final _trash = TrashRepository();

  Future<List<Facture>> all() async {
    final db = await _db;
    final rows = await db.query('factures', orderBy: 'rowid DESC');
    return rows.map((r) => Facture.fromMap(r)).toList();
  }

  Future<Facture> create({
    required String client,
    double montant = 0,
    String statut = 'Impayée',
    double solde = 0,
    String? commandeId,
    String? devisId,
  }) async {
    final db = await _db;
    final id = await IdGenerator.next(db, 'factures');
    final facture = Facture(
      id: id, client: client, montant: montant, statut: statut, solde: solde,
      date: _todayFr(), commandeId: commandeId, devisId: devisId,
    );
    await db.insert('factures', facture.toMap());
    return facture;
  }

  Future<void> delete(Facture facture) async {
    final db = await _db;
    await _trash.moveToTrash('factures', facture.toMap());
    await db.delete('factures', where: 'id = ?', whereArgs: [facture.id]);
  }

  /// Crée automatiquement une facture à partir d'une commande — même
  /// logique que le bouton "Facturer" sur les autres versions.
  Future<Facture> creerDepuisCommande(Commande commande) async {
    final solde = commande.solde;
    final statut = solde == 0 && commande.montant > 0
        ? 'Payée'
        : commande.avance > 0
            ? 'Partielle'
            : 'Impayée';
    return create(client: commande.client, montant: commande.montant, statut: statut, solde: solde, commandeId: commande.id);
  }
}

String _todayFr() {
  const mois = ['janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin', 'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'];
  final d = DateTime.now();
  return '${d.day.toString().padLeft(2, '0')} ${mois[d.month - 1]} ${d.year}';
}

class PaiementRepository {
  Future<Database> get _db async => AppDatabase.instance.database;
  final _trash = TrashRepository();

  Future<List<Paiement>> all() async {
    final db = await _db;
    final rows = await db.query('paiements', orderBy: 'rowid DESC');
    return rows.map((r) => Paiement.fromMap(r)).toList();
  }

  Future<Paiement> create({required String client, double montant = 0, String mode = 'Espèces', String reference = ''}) async {
    final db = await _db;
    final id = await IdGenerator.next(db, 'paiements');
    final p = Paiement(id: id, client: client, montant: montant, mode: mode, reference: reference, date: _todayFr());
    await db.insert('paiements', p.toMap());
    return p;
  }

  Future<void> delete(Paiement p) async {
    final db = await _db;
    await _trash.moveToTrash('paiements', p.toMap());
    await db.delete('paiements', where: 'id = ?', whereArgs: [p.id]);
  }
}

class DepenseRepository {
  Future<Database> get _db async => AppDatabase.instance.database;
  final _trash = TrashRepository();

  Future<List<Depense>> all() async {
    final db = await _db;
    final rows = await db.query('depenses', orderBy: 'rowid DESC');
    return rows.map((r) => Depense.fromMap(r)).toList();
  }

  Future<Depense> create({
    required String categorie,
    String fournisseur = '',
    double montant = 0,
    double? montantVerse,
  }) async {
    final db = await _db;
    final id = await IdGenerator.next(db, 'depenses');
    final verse = montantVerse ?? montant;
    final d = Depense(
      id: id, categorie: categorie, fournisseur: fournisseur,
      montant: montant, montantVerse: verse, reliquat: (montant - verse) < 0 ? 0 : (montant - verse),
      date: _todayFr(),
    );
    await db.insert('depenses', d.toMap());
    return d;
  }

  Future<void> reglerReliquat(Depense d, double montantAjoute) async {
    final db = await _db;
    final nouveauVerse = d.montantVerse + montantAjoute;
    final nouveauReliquat = (d.montant - nouveauVerse) < 0 ? 0.0 : (d.montant - nouveauVerse);
    await db.update('depenses', {'montantVerse': nouveauVerse, 'reliquat': nouveauReliquat}, where: 'id = ?', whereArgs: [d.id]);
  }

  Future<void> delete(Depense d) async {
    final db = await _db;
    await _trash.moveToTrash('depenses', d.toMap());
    await db.delete('depenses', where: 'id = ?', whereArgs: [d.id]);
  }
}

class StockRepository {
  Future<Database> get _db async => AppDatabase.instance.database;
  final _trash = TrashRepository();

  Future<List<StockItem>> all() async {
    final db = await _db;
    final rows = await db.query('stock', orderBy: 'rowid DESC');
    return rows.map((r) => StockItem.fromMap(r)).toList();
  }

  Future<StockItem> create({
    required String nom,
    String type = 'Tissu',
    double qte = 0,
    String unite = 'unités',
    double seuil = 0,
    String fournisseur = '',
  }) async {
    final db = await _db;
    final id = await IdGenerator.next(db, 'stock');
    final item = StockItem(id: id, nom: nom, type: type, qte: qte, unite: unite, seuil: seuil, fournisseur: fournisseur);
    await db.insert('stock', item.toMap());
    return item;
  }

  Future<void> updateQte(String id, double nouvelleQte) async {
    final db = await _db;
    await db.update('stock', {'qte': nouvelleQte}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> delete(StockItem item) async {
    final db = await _db;
    await _trash.moveToTrash('stock', item.toMap());
    await db.delete('stock', where: 'id = ?', whereArgs: [item.id]);
  }
}

class ModeleRepository {
  Future<Database> get _db async => AppDatabase.instance.database;
  final _trash = TrashRepository();

  Future<List<Modele>> all() async {
    final db = await _db;
    final rows = await db.query('modeles', orderBy: 'rowid DESC');
    return rows.map((r) => Modele.fromMap(r)).toList();
  }

  Future<Modele> create({
    required String nom,
    String categorie = 'Autre',
    double prix = 0,
    int jours = 1,
    String photo = '',
  }) async {
    final db = await _db;
    final id = await IdGenerator.next(db, 'modeles');
    final m = Modele(id: id, nom: nom, categorie: categorie, prix: prix, jours: jours, photo: photo);
    await db.insert('modeles', m.toMap());
    return m;
  }

  Future<void> delete(Modele m) async {
    final db = await _db;
    await _trash.moveToTrash('modeles', m.toMap());
    await db.delete('modeles', where: 'id = ?', whereArgs: [m.id]);
  }
}

class DevisRepository {
  Future<Database> get _db async => AppDatabase.instance.database;
  final _trash = TrashRepository();

  Future<List<Devis>> all() async {
    final db = await _db;
    final rows = await db.query('devis', orderBy: 'rowid DESC');
    return rows.map((r) => Devis.fromMap(r)).toList();
  }

  Future<Devis> create({required String client, double montant = 0, String statut = 'En attente'}) async {
    final db = await _db;
    final id = await IdGenerator.next(db, 'devis');
    final d = Devis(id: id, client: client, montant: montant, statut: statut, date: _todayFr());
    await db.insert('devis', d.toMap());
    return d;
  }

  Future<void> delete(Devis d) async {
    final db = await _db;
    await _trash.moveToTrash('devis', d.toMap());
    await db.delete('devis', where: 'id = ?', whereArgs: [d.id]);
  }
}

class FournisseurRepository {
  Future<Database> get _db async => AppDatabase.instance.database;
  final _trash = TrashRepository();

  Future<List<Fournisseur>> all() async {
    final db = await _db;
    final rows = await db.query('fournisseurs', orderBy: 'rowid DESC');
    return rows.map((r) => Fournisseur.fromMap(r)).toList();
  }

  Future<Fournisseur> create({required String nom, String contact = '', String ville = ''}) async {
    final db = await _db;
    final id = await IdGenerator.next(db, 'fournisseurs');
    final f = Fournisseur(id: id, nom: nom, contact: contact, ville: ville);
    await db.insert('fournisseurs', f.toMap());
    return f;
  }

  Future<void> delete(Fournisseur f) async {
    final db = await _db;
    await _trash.moveToTrash('fournisseurs', f.toMap());
    await db.delete('fournisseurs', where: 'id = ?', whereArgs: [f.id]);
  }
}

class EmployeRepository {
  Future<Database> get _db async => AppDatabase.instance.database;
  final _trash = TrashRepository();

  Future<List<Employe>> all() async {
    final db = await _db;
    final rows = await db.query('employes', orderBy: 'rowid DESC');
    return rows.map((r) => Employe.fromMap(r)).toList();
  }

  Future<Employe> create({
    required String nom,
    String poste = '',
    String specialite = '',
    String frequencePaiement = 'Mensuel',
    double tauxPaiement = 0,
  }) async {
    final db = await _db;
    final id = await IdGenerator.next(db, 'employes');
    final e = Employe(
      id: id, nom: nom, poste: poste, specialite: specialite,
      frequencePaiement: frequencePaiement, tauxPaiement: tauxPaiement, embauche: DateTime.now().year.toString(),
    );
    await db.insert('employes', e.toMap());
    return e;
  }

  Future<void> delete(Employe e) async {
    final db = await _db;
    await _trash.moveToTrash('employes', e.toMap());
    await db.delete('employes', where: 'id = ?', whereArgs: [e.id]);
  }
}

class PaiementEmployeRepository {
  Future<Database> get _db async => AppDatabase.instance.database;

  Future<List<PaiementEmploye>> all() async {
    final db = await _db;
    final rows = await db.query('paiements_employes', orderBy: 'rowid DESC');
    return rows.map((r) => PaiementEmploye.fromMap(r)).toList();
  }

  Future<PaiementEmploye> create({
    required String employe,
    double montant = 0,
    String mode = 'Espèces',
    String periode = '',
  }) async {
    final db = await _db;
    final id = await IdGenerator.next(db, 'paiements_employes');
    final p = PaiementEmploye(id: id, employe: employe, montant: montant, mode: mode, periode: periode, date: _todayFr());
    await db.insert('paiements_employes', p.toMap());
    return p;
  }
}

class UserRepository {
  Future<Database> get _db async => AppDatabase.instance.database;

  Future<List<Utilisateur>> all() async {
    final db = await _db;
    final rows = await db.query('utilisateurs', orderBy: 'rowid DESC');
    return rows.map((r) => Utilisateur.fromMap(r)).toList();
  }

  Future<Utilisateur> create({required String nom, String role = 'Employé'}) async {
    final db = await _db;
    final id = 'U-${DateTime.now().millisecondsSinceEpoch}';
    final user = Utilisateur(id: id, nom: nom, role: role);
    await db.insert('utilisateurs', user.toMap());
    return user;
  }

  Future<void> delete(String id) async {
    final db = await _db;
    await db.delete('utilisateurs', where: 'id = ?', whereArgs: [id]);
  }
}

/// Gère les réglages de l'application : thème clair/sombre et
/// informations d'entreprise personnalisées — persistés localement,
/// une seule ligne dans la table `parametres`.
class ParametresRepository {
  Future<Database> get _db async => AppDatabase.instance.database;

  Future<Map<String, dynamic>> get() async {
    final db = await _db;
    final rows = await db.query('parametres', where: 'id = 1');
    if (rows.isEmpty) return {'themeMode': 'dark', 'businessOverrideJson': '{}'};
    return rows.first;
  }

  Future<String> getThemeMode() async {
    final row = await get();
    return row['themeMode'] as String? ?? 'dark';
  }

  Future<void> setThemeMode(String mode) async {
    final db = await _db;
    await db.update('parametres', {'themeMode': mode}, where: 'id = 1');
  }

  Future<Map<String, dynamic>> getBusinessOverride() async {
    final row = await get();
    final raw = row['businessOverrideJson'] as String? ?? '{}';
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return {};
    }
  }

  Future<void> setBusinessOverride(Map<String, dynamic> value) async {
    final db = await _db;
    await db.update('parametres', {'businessOverrideJson': jsonEncode(value)}, where: 'id = 1');
  }
}
