class Paiement {
  final String id;
  final String client;
  final double montant;
  final String mode;
  final String reference;
  final String date;

  Paiement({
    required this.id,
    required this.client,
    this.montant = 0,
    this.mode = 'Espèces',
    this.reference = '',
    this.date = '',
  });

  factory Paiement.fromMap(Map<String, dynamic> map) => Paiement(
        id: map['id'] as String,
        client: map['client'] as String? ?? '',
        montant: (map['montant'] as num?)?.toDouble() ?? 0,
        mode: map['mode'] as String? ?? 'Espèces',
        reference: map['reference'] as String? ?? '',
        date: map['date'] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'client': client,
        'montant': montant,
        'mode': mode,
        'reference': reference,
        'date': date,
      };
}
