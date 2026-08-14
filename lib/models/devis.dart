class Devis {
  final String id;
  final String client;
  final double montant;
  final String statut;
  final String date;

  Devis({
    required this.id,
    required this.client,
    this.montant = 0,
    this.statut = 'En attente',
    this.date = '',
  });

  factory Devis.fromMap(Map<String, dynamic> map) => Devis(
        id: map['id'] as String,
        client: map['client'] as String? ?? '',
        montant: (map['montant'] as num?)?.toDouble() ?? 0,
        statut: map['statut'] as String? ?? 'En attente',
        date: map['date'] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'client': client,
        'montant': montant,
        'statut': statut,
        'date': date,
      };
}
