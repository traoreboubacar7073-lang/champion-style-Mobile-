class Depense {
  final String id;
  final String categorie;
  final String fournisseur;
  final double montant;
  final double montantVerse;
  final double reliquat;
  final String date;

  Depense({
    required this.id,
    required this.categorie,
    this.fournisseur = '',
    this.montant = 0,
    double? montantVerse,
    double? reliquat,
    this.date = '',
  })  : montantVerse = montantVerse ?? montant,
        reliquat = reliquat ?? 0;

  factory Depense.fromMap(Map<String, dynamic> map) => Depense(
        id: map['id'] as String,
        categorie: map['categorie'] as String? ?? '',
        fournisseur: map['fournisseur'] as String? ?? '',
        montant: (map['montant'] as num?)?.toDouble() ?? 0,
        montantVerse: (map['montantVerse'] as num?)?.toDouble(),
        reliquat: (map['reliquat'] as num?)?.toDouble(),
        date: map['date'] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'categorie': categorie,
        'fournisseur': fournisseur,
        'montant': montant,
        'montantVerse': montantVerse,
        'reliquat': reliquat,
        'date': date,
      };
}
