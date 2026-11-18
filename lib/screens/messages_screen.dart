import 'package:flutter/material.dart';
import '../data/repository.dart';
import '../models/client.dart';
import '../theme/app_theme.dart';
import '../theme/business_info.dart';
import '../widgets/shared_widgets.dart';
import '../services/whatsapp_service.dart';

/// Contacter un client — envoie directement via WhatsApp plutôt que de
/// simuler une messagerie interne qui n'existerait nulle part ailleurs :
/// aucune conversation n'est stockée ni inventée dans l'application, le
/// vrai message part réellement depuis WhatsApp du téléphone.
class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  List<Client> _clients = [];
  bool _loading = true;
  String _recherche = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final clients = await ClientRepository().all();
    if (!mounted) return;
    setState(() {
      _clients = clients;
      _loading = false;
    });
  }

  void _contacter(Client c) {
    if (!WhatsappService.numeroValide(c.tel)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ce client n'a pas de numéro de téléphone valide enregistré.")),
      );
      return;
    }
    showAppBottomSheet(
      context,
      title: c.nom,
      child: WhatsappMessageSheet(
        telephone: c.tel,
        messageInitial: 'Bonjour ${c.nom}, ici ${BusinessInfo.nom}. ',
        introTexte: 'Le message sera envoyé sur WhatsApp',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppColors.gold));

    final filtres = _recherche.trim().isEmpty
        ? _clients
        : _clients.where((c) => c.nom.toLowerCase().contains(_recherche.toLowerCase())).toList();

    return RefreshIndicator(
      color: AppColors.gold,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          const ScreenHeader(eyebrow: 'Contact direct', title: 'Messages'),
          Text('Envoie un message WhatsApp directement à un client — la conversation se passe dans WhatsApp, rien n\'est stocké ici.',
              style: TextStyle(color: context.textFaint, fontSize: 12.5)),
          const SizedBox(height: 14),
          TextField(
            decoration: const InputDecoration(hintText: 'Rechercher un client…', prefixIcon: Icon(Icons.search, size: 20)),
            onChanged: (v) => setState(() => _recherche = v),
          ),
          const SizedBox(height: 16),
          if (filtres.isEmpty)
            const EmptyState(icon: Icons.chat_bubble_outline, text: 'Aucun client à contacter pour le moment.')
          else
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  for (int i = 0; i < filtres.length; i++) ...[
                    if (i > 0) Divider(height: 1, color: context.cardBorder),
                    InkWell(
                      onTap: () => _contacter(filtres[i]),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        child: Row(
                          children: [
                            AppAvatar(name: filtres[i].nom, size: 40),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(filtres[i].nom, style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w500, fontSize: 14)),
                                  const SizedBox(height: 2),
                                  Text(filtres[i].tel.isEmpty ? 'Aucun numéro enregistré' : filtres[i].tel,
                                      style: TextStyle(color: context.textFaint, fontSize: 12)),
                                ],
                              ),
                            ),
                            const Icon(Icons.chat_bubble_outline, color: AppColors.deepGreen, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}
