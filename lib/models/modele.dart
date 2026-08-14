class Modele {
  final String id;
  final String nom;
  final String categorie;
  final double prix;
  final int jours;
  final String photo;

  Modele({
    required this.id,
    required this.nom,
    this.categorie = 'Autre',
    this.prix = 0,
    this.jours = 1,
    this.photo = '',
  });

  factory Modele.fromMap(Map<String, dynamic> map) => Modele(
        id: map['id'] as String,
        nom: map['nom'] as String? ?? '',
        categorie: map['categorie'] as String? ?? 'Autre',
        prix: (map['prix'] as num?)?.toDouble() ?? 0,
        jours: (map['jours'] as num?)?.toInt() ?? 1,
        photo: map['photo'] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'nom': nom,
        'categorie': categorie,
        'prix': prix,
        'jours': jours,
        'photo': photo,
      };
}
