class Employe {
  final String id;
  final String nom;
  final String poste;
  final String specialite;
  final String frequencePaiement;
  final double tauxPaiement;
  final String embauche;

  Employe({
    required this.id,
    required this.nom,
    this.poste = '',
    this.specialite = '',
    this.frequencePaiement = 'Mensuel',
    this.tauxPaiement = 0,
    this.embauche = '',
  });

  factory Employe.fromMap(Map<String, dynamic> map) => Employe(
        id: map['id'] as String,
        nom: map['nom'] as String? ?? '',
        poste: map['poste'] as String? ?? '',
        specialite: map['specialite'] as String? ?? '',
        frequencePaiement: map['frequencePaiement'] as String? ?? 'Mensuel',
        tauxPaiement: (map['tauxPaiement'] as num?)?.toDouble() ?? 0,
        embauche: map['embauche'] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'nom': nom,
        'poste': poste,
        'specialite': specialite,
        'dispo': specialite.isNotEmpty ? 'Disponible' : '',
        'frequencePaiement': frequencePaiement,
        'tauxPaiement': tauxPaiement,
        'embauche': embauche,
      };
}

class PaiementEmploye {
  final String id;
  final String employe;
  final double montant;
  final String mode;
  final String periode;
  final String date;

  PaiementEmploye({
    required this.id,
    required this.employe,
    this.montant = 0,
    this.mode = 'Espèces',
    this.periode = '',
    this.date = '',
  });

  factory PaiementEmploye.fromMap(Map<String, dynamic> map) => PaiementEmploye(
        id: map['id'] as String,
        employe: map['employe'] as String? ?? '',
        montant: (map['montant'] as num?)?.toDouble() ?? 0,
        mode: map['mode'] as String? ?? 'Espèces',
        periode: map['periode'] as String? ?? '',
        date: map['date'] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'employe': employe,
        'montant': montant,
        'mode': mode,
        'periode': periode,
        'date': date,
      };
}
