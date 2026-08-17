import 'package:url_launcher/url_launcher.dart';

/// Ouvre WhatsApp directement sur la conversation d'un numéro donné, avec
/// un message déjà rédigé — l'utilisateur n'a plus qu'à appuyer sur
/// "Envoyer". WhatsApp n'autorise aucune application tierce à envoyer un
/// message sans confirmation de la personne (protection anti-spam), donc
/// ce dernier geste reste toujours manuel, volontairement.
class WhatsappService {
  WhatsappService._();

  /// Ne garde que les chiffres du numéro (retire le "+", les espaces,
  /// tirets...), format attendu par le lien wa.me.
  static String _nettoyerNumero(String numero) {
    return numero.replaceAll(RegExp(r'[^0-9]'), '');
  }

  static bool numeroValide(String numero) => _nettoyerNumero(numero).length >= 8;

  static Future<bool> ouvrirConversation({required String numero, required String message}) async {
    final numeroPropre = _nettoyerNumero(numero);
    if (numeroPropre.isEmpty) return false;
    final uri = Uri.parse('https://wa.me/$numeroPropre?text=${Uri.encodeComponent(message)}');
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
