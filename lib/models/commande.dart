class Commande {
  final String id;
  final String client;
  final String modele;
  final String couturier;
  final String statut;
  final String dateEssayage;
  final String livraison;
  final double montant;
  final double avance;
  final String photo;

  Commande({
    required this.id,
    required this.client,
    this.modele = '',
    this.couturier = '',
    this.statut = 'Nouvelle',
    this.dateEssayage = '',
    this.livraison = '',
    this.montant = 0,
    this.avance = 0,
    this.photo = '',
  });

  double get solde => (montant - avance) < 0 ? 0 : (montant - avance);

  factory Commande.fromMap(Map<String, dynamic> map) => Commande(
        id: map['id'] as String,
        client: map['client'] as String? ?? '',
        modele: map['modele'] as String? ?? '',
        couturier: map['couturier'] as String? ?? '',
        statut: map['statut'] as String? ?? 'Nouvelle',
        dateEssayage: map['dateEssayage'] as String? ?? '',
        livraison: map['livraison'] as String? ?? '',
        montant: (map['montant'] as num?)?.toDouble() ?? 0,
        avance: (map['avance'] as num?)?.toDouble() ?? 0,
        photo: map['photo'] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'client': client,
        'modele': modele,
        'couturier': couturier,
        'statut': statut,
        'dateEssayage': dateEssayage,
        'livraison': livraison,
        'montant': montant,
        'avance': avance,
        'photo': photo,
      };

  Commande copyWith({
    String? client,
    String? modele,
    String? couturier,
    String? statut,
    String? dateEssayage,
    String? livraison,
    double? montant,
    double? avance,
    String? photo,
  }) {
    return Commande(
      id: id,
      client: client ?? this.client,
      modele: modele ?? this.modele,
      couturier: couturier ?? this.couturier,
      statut: statut ?? this.statut,
      dateEssayage: dateEssayage ?? this.dateEssayage,
      livraison: livraison ?? this.livraison,
      montant: montant ?? this.montant,
      avance: avance ?? this.avance,
      photo: photo ?? this.photo,
    );
  }
}
