import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Base de données locale de l'application — tout reste sur le téléphone,
/// aucune connexion internet n'est nécessaire pour utiliser l'application.
///
/// Chaque table correspond à une section de l'application (clients,
/// commandes, factures...). La table `corbeille` centralise les éléments
/// supprimés de n'importe quelle table, pour permettre de les restaurer
/// pendant 30 jours — exactement comme sur les versions ordinateur et web.
class AppDatabase {
  AppDatabase._internal();
  static final AppDatabase instance = AppDatabase._internal();

  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'champions_style.db');
    return openDatabase(
      path,
      version: 6,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute("ALTER TABLE parametres ADD COLUMN themeMode TEXT DEFAULT 'dark'");
      await db.execute('''
        CREATE TABLE utilisateurs (
          id TEXT PRIMARY KEY,
          nom TEXT NOT NULL,
          role TEXT DEFAULT 'Employé',
          actif INTEGER DEFAULT 1
        )
      ''');
    }
    if (oldVersion < 3) {
      await _creerTablesBoutique(db);
    }
    if (oldVersion < 4) {
      await db.execute("ALTER TABLE parametres ADD COLUMN pinCode TEXT");
    }
    if (oldVersion < 5) {
      await db.execute("ALTER TABLE articles_boutique ADD COLUMN photo TEXT DEFAULT ''");
      await db.execute("ALTER TABLE articles_boutique ADD COLUMN taille TEXT DEFAULT ''");
      await db.execute("ALTER TABLE ventes_boutique ADD COLUMN taille TEXT DEFAULT ''");
    }
    if (oldVersion < 6) {
      // Suivi de la quantité en stock de chaque article de boutique — les
      // articles déjà enregistrés démarrent à 0 (à ajuster ensuite via
      // "Réapprovisionner").
      await db.execute("ALTER TABLE articles_boutique ADD COLUMN qte REAL DEFAULT 0");
    }
  }

  /// Articles vendus directement en boutique (tissus, montres, parfums,
  /// gels de douche, prêt-à-porter...) — indépendants des clients et des
  /// commandes de couture, pour une vente rapide au comptoir.
  Future<void> _creerTablesBoutique(Database db) async {
    await db.execute('''
      CREATE TABLE articles_boutique (
        id TEXT PRIMARY KEY,
        nom TEXT NOT NULL,
        categorie TEXT NOT NULL,
        prix REAL DEFAULT 0,
        photo TEXT DEFAULT '',
        taille TEXT DEFAULT '',
        qte REAL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE ventes_boutique (
        id TEXT PRIMARY KEY,
        article TEXT NOT NULL,
        categorie TEXT NOT NULL,
        taille TEXT DEFAULT '',
        prixUnitaire REAL DEFAULT 0,
        quantite REAL DEFAULT 1,
        montant REAL DEFAULT 0,
        date TEXT
      )
    ''');
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE clients (
        id TEXT PRIMARY KEY,
        nom TEXT NOT NULL,
        tel TEXT,
        ville TEXT,
        sexe TEXT,
        depuis TEXT,
        mesures TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE modeles (
        id TEXT PRIMARY KEY,
        nom TEXT NOT NULL,
        categorie TEXT,
        prix REAL DEFAULT 0,
        jours INTEGER DEFAULT 1,
        photo TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE commandes (
        id TEXT PRIMARY KEY,
        client TEXT NOT NULL,
        modele TEXT,
        couturier TEXT,
        statut TEXT DEFAULT 'Nouvelle',
        dateEssayage TEXT,
        livraison TEXT,
        montant REAL DEFAULT 0,
        avance REAL DEFAULT 0,
        photo TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE devis (
        id TEXT PRIMARY KEY,
        client TEXT NOT NULL,
        montant REAL DEFAULT 0,
        statut TEXT DEFAULT 'En attente',
        date TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE factures (
        id TEXT PRIMARY KEY,
        client TEXT NOT NULL,
        montant REAL DEFAULT 0,
        statut TEXT DEFAULT 'Impayée',
        solde REAL DEFAULT 0,
        date TEXT,
        commandeId TEXT,
        devisId TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE paiements (
        id TEXT PRIMARY KEY,
        client TEXT NOT NULL,
        montant REAL DEFAULT 0,
        mode TEXT,
        reference TEXT,
        date TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE depenses (
        id TEXT PRIMARY KEY,
        categorie TEXT NOT NULL,
        fournisseur TEXT,
        montant REAL DEFAULT 0,
        montantVerse REAL DEFAULT 0,
        reliquat REAL DEFAULT 0,
        date TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE fournisseurs (
        id TEXT PRIMARY KEY,
        nom TEXT NOT NULL,
        contact TEXT,
        ville TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE employes (
        id TEXT PRIMARY KEY,
        nom TEXT NOT NULL,
        poste TEXT,
        specialite TEXT,
        dispo TEXT,
        frequencePaiement TEXT DEFAULT 'Mensuel',
        tauxPaiement REAL DEFAULT 0,
        embauche TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE paiements_employes (
        id TEXT PRIMARY KEY,
        employe TEXT NOT NULL,
        montant REAL DEFAULT 0,
        mode TEXT,
        periode TEXT,
        date TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE stock (
        id TEXT PRIMARY KEY,
        nom TEXT NOT NULL,
        type TEXT,
        qte REAL DEFAULT 0,
        unite TEXT,
        seuil REAL DEFAULT 0,
        fournisseur TEXT
      )
    ''');

    // Corbeille commune à toutes les tables ci-dessus : au lieu de
    // supprimer définitivement une ligne, on la déplace ici (en JSON)
    // avec la date de suppression, pour pouvoir la restaurer.
    await db.execute('''
      CREATE TABLE corbeille (
        trashId TEXT PRIMARY KEY,
        tableName TEXT NOT NULL,
        itemJson TEXT NOT NULL,
        trashedAt INTEGER NOT NULL
      )
    ''');

    // Paramètres de l'application : une seule ligne (id fixe = 1),
    // stockée en JSON pour rester flexible (infos entreprise, police...).
    await db.execute('''
      CREATE TABLE parametres (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        businessOverrideJson TEXT DEFAULT '{}',
        policeStyle TEXT DEFAULT 'elegant',
        tailleTexte TEXT DEFAULT 'normale',
        themeMode TEXT DEFAULT 'dark',
        pinCode TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE utilisateurs (
        id TEXT PRIMARY KEY,
        nom TEXT NOT NULL,
        role TEXT DEFAULT 'Employé',
        actif INTEGER DEFAULT 1
      )
    ''');
    await _creerTablesBoutique(db);
    await db.insert('parametres', {
      'id': 1,
      'businessOverrideJson': '{}',
      'policeStyle': 'elegant',
      'tailleTexte': 'normale',
      'themeMode': 'dark',
    });
  }
}
