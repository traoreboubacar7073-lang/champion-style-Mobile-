/// Grilles de mesures — reprises à l'identique des versions ordinateur et
/// web mobile de Champions Style. Chaque sexe a sa propre méthode de
/// mesure, entièrement indépendante de l'autre.
///
/// `isDash` = true signifie que la mesure se saisit comme du texte libre
/// avec un tiret (ex : "32-18"), pas comme un simple nombre.
class MesureField {
  final String key;
  final String label;
  final bool isDash;

  const MesureField(this.key, this.label, {this.isDash = false});
}

class MesuresGrilles {
  MesuresGrilles._();

  static const List<MesureField> homme = [
    MesureField('l', 'L'),
    MesureField('p', 'P'),
    MesureField('tt', 'TT'),
    MesureField('c', 'C'),
    MesureField('f', 'F'),
    MesureField('e', 'E'),
    MesureField('m', 'M'),
    MesureField('tm', 'TM', isDash: true),
    MesureField('cui', 'CUI'),
    MesureField('tz', 'TZ'),
    MesureField('tt2', 'TT'),
    MesureField('cou', 'Cou'),
    MesureField('lp', 'LP'),
  ];

  static const List<MesureField> femme = [
    MesureField('lr', 'LR'),
    MesureField('s', 'S'),
    MesureField('t', 'T'),
    MesureField('p', 'P'),
    MesureField('tt', 'TT'),
    MesureField('c', 'C'),
    MesureField('f', 'F'),
    MesureField('f2', 'F2'),
    MesureField('e', 'E'),
    MesureField('m', 'M'),
    MesureField('tm', 'TM', isDash: true),
    MesureField('dot', 'DOT'),
    MesureField('dot2', 'DOT2'),
    MesureField('lg', 'LG', isDash: true),
  ];

  static List<MesureField> forSexe(String? sexe) {
    if (sexe == 'Homme') return homme;
    if (sexe == 'Femme') return femme;
    return const [];
  }

  /// Table de correspondance clé -> libellé, pour afficher n'importe
  /// quelle mesure enregistrée sans connaître à l'avance le sexe du client.
  static final Map<String, String> labels = {
    for (final f in [...homme, ...femme]) f.key: f.label,
  };
}
