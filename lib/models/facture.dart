class Facture {
  final String id;
  final String client;
  final double montant;
  final String statut;
  final double solde;
  final String date;
  final String? commandeId;
  final String? devisId;

  Facture({
    required this.id,
    required this.client,
    this.montant = 0,
    this.statut = 'Impayée',
    this.solde = 0,
    this.date = '',
    this.commandeId,
    this.devisId,
  });

  factory Facture.fromMap(Map<String, dynamic> map) => Facture(
        id: map['id'] as String,
        client: map['client'] as String? ?? '',
        montant: (map['montant'] as num?)?.toDouble() ?? 0,
        statut: map['statut'] as String? ?? 'Impayée',
        solde: (map['solde'] as num?)?.toDouble() ?? 0,
        date: map['date'] as String? ?? '',
        commandeId: map['commandeId'] as String?,
        devisId: map['devisId'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'client': client,
        'montant': montant,
        'statut': statut,
        'solde': solde,
        'date': date,
        'commandeId': commandeId,
        'devisId': devisId,
      };
}
