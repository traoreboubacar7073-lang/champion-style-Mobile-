class Fournisseur {
  final String id;
  final String nom;
  final String contact;
  final String ville;

  Fournisseur({required this.id, required this.nom, this.contact = '', this.ville = ''});

  factory Fournisseur.fromMap(Map<String, dynamic> map) => Fournisseur(
        id: map['id'] as String,
        nom: map['nom'] as String? ?? '',
        contact: map['contact'] as String? ?? '',
        ville: map['ville'] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {'id': id, 'nom': nom, 'contact': contact, 'ville': ville};
}
