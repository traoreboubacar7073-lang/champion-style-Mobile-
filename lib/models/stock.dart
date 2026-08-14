class StockItem {
  final String id;
  final String nom;
  final String type;
  final double qte;
  final String unite;
  final double seuil;
  final String fournisseur;

  StockItem({
    required this.id,
    required this.nom,
    this.type = 'Tissu',
    this.qte = 0,
    this.unite = 'unités',
    this.seuil = 0,
    this.fournisseur = '',
  });

  bool get bas => qte < seuil;

  factory StockItem.fromMap(Map<String, dynamic> map) => StockItem(
        id: map['id'] as String,
        nom: map['nom'] as String? ?? '',
        type: map['type'] as String? ?? 'Tissu',
        qte: (map['qte'] as num?)?.toDouble() ?? 0,
        unite: map['unite'] as String? ?? 'unités',
        seuil: (map['seuil'] as num?)?.toDouble() ?? 0,
        fournisseur: map['fournisseur'] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'nom': nom,
        'type': type,
        'qte': qte,
        'unite': unite,
        'seuil': seuil,
        'fournisseur': fournisseur,
      };
}
