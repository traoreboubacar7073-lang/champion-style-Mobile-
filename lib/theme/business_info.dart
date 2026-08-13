/// Informations par défaut de l'atelier — utilisées partout dans
/// l'application (en-tête, menu, écran Paramètres, documents).
/// Peuvent être modifiées depuis l'écran Paramètres ; dans ce cas, les
/// valeurs modifiées sont stockées dans la table `parametres` et
/// remplacent celles-ci à l'affichage.
class BusinessInfo {
  BusinessInfo._();

  static const String nom = 'Champions Style';
  static const String monogramme = 'CS';
  static const String activite = 'Vente de Tissus, Accessoires, Broderie Dame & Homme';
  static const String slogan = "La couture n'a pas de secret";
  static const String ville = "Bamako Sokorodji (Près de l'École BEN)";
  static const String tel = '+223 91 71 11 00 / 66 07 45 95';
  static const String email = 'konatesidiki017@gmail.com';
  static const String facebook = 'champion Style';
  static const String instagram = 'Sidiki champion Konaté';
  static const String tiktok = 'champion Style';

  static Map<String, String> asMap() => {
        'nom': nom,
        'activite': activite,
        'ville': ville,
        'tel': tel,
        'email': email,
        'facebook': facebook,
        'instagram': instagram,
        'tiktok': tiktok,
      };
}

/// Numéro de version de l'application + historique des évolutions —
/// à mettre à jour à chaque intervention réelle (même logique que sur
/// la version ordinateur, page Maintenance).
const String appVersion = '1.0.0';
