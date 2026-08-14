class Utilisateur {
  final String id;
  final String nom;
  final String role;
  final bool actif;

  Utilisateur({required this.id, required this.nom, this.role = 'Employé', this.actif = true});

  factory Utilisateur.fromMap(Map<String, dynamic> map) => Utilisateur(
        id: map['id'] as String,
        nom: map['nom'] as String? ?? '',
        role: map['role'] as String? ?? 'Employé',
        actif: (map['actif'] as int? ?? 1) == 1,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'nom': nom,
        'role': role,
        'actif': actif ? 1 : 0,
      };
}
