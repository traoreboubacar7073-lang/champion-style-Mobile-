class ArticleBoutique {
  final String id;
  final String nom;
  final String categorie;
  final double prix;
  final String photo;
  final String taille;
  final double qte;

  ArticleBoutique({required this.id, required this.nom, required this.categorie, this.prix = 0, this.photo = '', this.taille = '', this.qte = 0});

  factory ArticleBoutique.fromMap(Map<String, dynamic> map) => ArticleBoutique(
        id: map['id'] as String,
        nom: map['nom'] as String? ?? '',
        categorie: map['categorie'] as String? ?? 'Autre',
        prix: (map['prix'] as num?)?.toDouble() ?? 0,
        photo: map['photo'] as String? ?? '',
        taille: map['taille'] as String? ?? '',
        qte: (map['qte'] as num?)?.toDouble() ?? 0,
      );

  Map<String, dynamic> toMap() => {'id': id, 'nom': nom, 'categorie': categorie, 'prix': prix, 'photo': photo, 'taille': taille, 'qte': qte};
}

class VenteBoutique {
  final String id;
  final String article;
  final String categorie;
  final String taille;
  final double prixUnitaire;
  final double quantite;
  final double montant;
  final String date;

  VenteBoutique({
    required this.id,
    required this.article,
    required this.categorie,
    this.taille = '',
    this.prixUnitaire = 0,
    this.quantite = 1,
    this.montant = 0,
    this.date = '',
  });

  factory VenteBoutique.fromMap(Map<String, dynamic> map) => VenteBoutique(
        id: map['id'] as String,
        article: map['article'] as String? ?? '',
        categorie: map['categorie'] as String? ?? 'Autre',
        taille: map['taille'] as String? ?? '',
        prixUnitaire: (map['prixUnitaire'] as num?)?.toDouble() ?? 0,
        quantite: (map['quantite'] as num?)?.toDouble() ?? 1,
        montant: (map['montant'] as num?)?.toDouble() ?? 0,
        date: map['date'] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'article': article,
        'categorie': categorie,
        'taille': taille,
        'prixUnitaire': prixUnitaire,
        'quantite': quantite,
        'montant': montant,
        'date': date,
      };
}
