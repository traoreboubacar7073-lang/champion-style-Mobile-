import 'dart:convert';

class Client {
  final String id;
  final String nom;
  final String tel;
  final String ville;
  final String sexe; // "Homme", "Femme" ou vide
  final String depuis;
  final Map<String, dynamic> mesures; // clé -> nombre ou texte (ex: "tm": "32-18")

  Client({
    required this.id,
    required this.nom,
    this.tel = '',
    this.ville = '',
    this.sexe = '',
    this.depuis = '',
    Map<String, dynamic>? mesures,
  }) : mesures = mesures ?? {};

  factory Client.fromMap(Map<String, dynamic> map) {
    Map<String, dynamic> mesuresMap = {};
    final raw = map['mesures'] as String?;
    if (raw != null && raw.isNotEmpty) {
      try {
        mesuresMap = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      } catch (_) {
        mesuresMap = {};
      }
    }
    return Client(
      id: map['id'] as String,
      nom: map['nom'] as String? ?? '',
      tel: map['tel'] as String? ?? '',
      ville: map['ville'] as String? ?? '',
      sexe: map['sexe'] as String? ?? '',
      depuis: map['depuis'] as String? ?? '',
      mesures: mesuresMap,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'nom': nom,
        'tel': tel,
        'ville': ville,
        'sexe': sexe,
        'depuis': depuis,
        'mesures': jsonEncode(mesures),
      };

  Client copyWith({
    String? nom,
    String? tel,
    String? ville,
    String? sexe,
    Map<String, dynamic>? mesures,
  }) {
    return Client(
      id: id,
      nom: nom ?? this.nom,
      tel: tel ?? this.tel,
      ville: ville ?? this.ville,
      sexe: sexe ?? this.sexe,
      depuis: depuis,
      mesures: mesures ?? this.mesures,
    );
  }
}
