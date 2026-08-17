import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard;
import '../data/repository.dart';
import '../models/utilisateur.dart';
import '../theme/app_theme.dart';
import '../theme/business_info.dart';
import '../widgets/shared_widgets.dart';
import '../services/backup_service.dart';

class ParametresScreen extends StatefulWidget {
  const ParametresScreen({super.key});

  @override
  State<ParametresScreen> createState() => _ParametresScreenState();
}

class _ParametresScreenState extends State<ParametresScreen> {
  final _paramRepo = ParametresRepository();
  final _userRepo = UserRepository();
  List<Utilisateur> _users = [];
  bool _loading = true;
  bool _pinActif = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final users = await _userRepo.all();
    final pin = await _paramRepo.getPinCode();
    if (!mounted) return;
    setState(() {
      _users = users;
      _pinActif = pin != null && pin.isNotEmpty;
      _loading = false;
    });
  }

  Future<void> _setTheme(ThemeMode mode) async {
    themeModeNotifier.value = mode;
    await _paramRepo.setThemeMode(mode == ThemeMode.light ? 'light' : 'dark');
  }

  Future<void> _setPolice(String key) async {
    policeNotifier.value = key;
    await _paramRepo.setPoliceStyle(key);
  }

  Future<void> _setTaille(String key) async {
    tailleTexteNotifier.value = taillesTexte[key] ?? 1.0;
    await _paramRepo.setTailleTexte(key);
  }

  bool _sauvegardeEnCours = false;

  Future<void> _exporterSauvegarde() async {
    setState(() => _sauvegardeEnCours = true);
    try {
      await BackupService.partagerSauvegarde();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Impossible de générer la sauvegarde.")));
    } finally {
      if (mounted) setState(() => _sauvegardeEnCours = false);
    }
  }

  Future<void> _restaurerSauvegarde() async {
    await showAppBottomSheet(
      context,
      title: 'Restaurer une sauvegarde',
      child: _RestaurationForm(onSuccess: () { Navigator.of(context).pop(); _load(); }),
    );
  }

  void _ouvrirGestionPin({required bool creation}) async {
    final ctrl1 = TextEditingController();
    final ctrl2 = TextEditingController();
    await showAppBottomSheet(
      context,
      title: creation ? 'Définir un code PIN' : 'Modifier le code PIN',
      child: StatefulBuilder(
        builder: (ctx, setSheetState) {
          String? erreur;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nouveau code (4 à 6 chiffres)', style: TextStyle(color: context.textMuted, fontSize: 12)),
              const SizedBox(height: 6),
              TextField(controller: ctrl1, keyboardType: TextInputType.number, obscureText: true, maxLength: 6, decoration: const InputDecoration()),
              Text('Confirmer le code', style: TextStyle(color: context.textMuted, fontSize: 12)),
              const SizedBox(height: 6),
              TextField(controller: ctrl2, keyboardType: TextInputType.number, obscureText: true, maxLength: 6, decoration: const InputDecoration()),
              if (erreur != null) Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(erreur!, style: const TextStyle(color: AppColors.rose, fontSize: 12))),
              GoldButton(
                label: 'Enregistrer',
                onPressed: () async {
                  final p1 = ctrl1.text.trim();
                  final p2 = ctrl2.text.trim();
                  if (p1.length < 4 || p1.length > 6) {
                    setSheetState(() => erreur = 'Le code doit contenir 4 à 6 chiffres.');
                    return;
                  }
                  if (p1 != p2) {
                    setSheetState(() => erreur = 'Les deux codes ne correspondent pas.');
                    return;
                  }
                  await _paramRepo.setPinCode(p1);
                  if (!mounted) return;
                  setState(() => _pinActif = true);
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _retirerPin() async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.isDark ? AppColors.surface : AppColors.surfaceLightMode,
        title: Text('Retirer le code PIN ?', style: TextStyle(color: context.textPrimary, fontSize: 16)),
        content: Text("L'application ne demandera plus de code à l'ouverture.", style: TextStyle(color: context.textMuted, fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Annuler', style: TextStyle(color: context.textMuted))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Retirer', style: TextStyle(color: AppColors.rose))),
        ],
      ),
    );
    if (confirme == true) {
      await _paramRepo.setPinCode(null);
      if (!mounted) return;
      setState(() => _pinActif = false);
    }
  }

  void _openAddUser() async {
    final nomCtrl = TextEditingController();
    String role = 'Employé';
    await showAppBottomSheet(
      context,
      title: 'Nouvel utilisateur',
      child: StatefulBuilder(
        builder: (ctx, setSheetState) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Nom complet *', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
            const SizedBox(height: 6),
            TextField(controller: nomCtrl, decoration: const InputDecoration(hintText: 'Ex : Sidiki Konaté')),
            const SizedBox(height: 14),
            const Text('Rôle', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: role,
              dropdownColor: AppColors.surface,
              items: const [
                DropdownMenuItem(value: 'Administrateur', child: Text('Administrateur', style: TextStyle(color: Colors.white))),
                DropdownMenuItem(value: 'Employé', child: Text('Employé', style: TextStyle(color: Colors.white))),
              ],
              onChanged: (v) => setSheetState(() => role = v ?? 'Employé'),
            ),
            const SizedBox(height: 20),
            GoldButton(
              label: 'Ajouter',
              onPressed: () async {
                if (nomCtrl.text.trim().isEmpty) return;
                await _userRepo.create(nom: nomCtrl.text.trim(), role: role);
                if (!mounted) return;
                Navigator.of(context).pop();
                _load();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('APPARENCE', style: TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.1)),
          const SizedBox(height: 10),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Thème', style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 12),
                ValueListenableBuilder<ThemeMode>(
                  valueListenable: themeModeNotifier,
                  builder: (context, mode, _) => Row(
                    children: [
                      Expanded(
                        child: _ThemeChoiceTile(
                          label: 'Sombre',
                          icon: Icons.dark_mode_outlined,
                          selected: mode == ThemeMode.dark,
                          onTap: () => _setTheme(ThemeMode.dark),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ThemeChoiceTile(
                          label: 'Clair',
                          icon: Icons.light_mode_outlined,
                          selected: mode == ThemeMode.light,
                          onTap: () => _setTheme(ThemeMode.light),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('POLICE D\'ÉCRITURE', style: TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.1)),
          const SizedBox(height: 10),
          AppCard(
            child: ValueListenableBuilder<String>(
              valueListenable: policeNotifier,
              builder: (context, policeActuelle, _) => Column(
                children: [
                  for (final entry in FontPresets.all.entries)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () => _setPolice(entry.key),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                          decoration: BoxDecoration(
                            color: policeActuelle == entry.key ? AppColors.gold.withOpacity(0.13) : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: policeActuelle == entry.key ? AppColors.gold : context.cardBorder),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(entry.value.label, style: entry.value.heading().copyWith(fontSize: 15, color: policeActuelle == entry.key ? AppColors.gold : context.textPrimary)),
                              if (policeActuelle == entry.key) const Icon(Icons.check_circle, color: AppColors.gold, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('TAILLE DU TEXTE', style: TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.1)),
          const SizedBox(height: 10),
          AppCard(
            child: ValueListenableBuilder<double>(
              valueListenable: tailleTexteNotifier,
              builder: (context, scaleActuelle, _) => Row(
                children: [
                  for (final entry in taillesTexte.entries)
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: entry.key == taillesTexte.keys.last ? 0 : 8),
                        child: InkWell(
                          onTap: () => _setTaille(entry.key),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            decoration: BoxDecoration(
                              color: scaleActuelle == entry.value ? AppColors.gold.withOpacity(0.15) : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: scaleActuelle == entry.value ? AppColors.gold : context.cardBorder),
                            ),
                            child: Column(
                              children: [
                                Text('A', style: TextStyle(fontSize: 14 + (entry.value - 0.92) * 20, fontWeight: FontWeight.w700, color: scaleActuelle == entry.value ? AppColors.gold : context.textMuted)),
                                const SizedBox(height: 4),
                                Text(
                                  entry.key == 'petite' ? 'Petite' : (entry.key == 'normale' ? 'Normale' : 'Grande'),
                                  style: TextStyle(fontSize: 11, color: scaleActuelle == entry.value ? AppColors.gold : context.textMuted, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('UTILISATEURS', style: TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.1)),
              GestureDetector(
                onTap: _openAddUser,
                child: const Text('+ Ajouter', style: TextStyle(color: AppColors.gold, fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_loading)
            const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Center(child: CircularProgressIndicator(color: AppColors.gold)))
          else if (_users.isEmpty)
            const EmptyState(icon: Icons.people_outline, text: 'Aucun utilisateur ajouté pour le moment.')
          else
            ..._users.map((u) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AppCard(
                    child: Row(
                      children: [
                        AppAvatar(name: u.nom, size: 38),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(u.nom, style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w500, fontSize: 15)),
                              Text(u.role, style: TextStyle(color: context.textFaint, fontSize: 12)),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () async {
                            await _userRepo.delete(u.id);
                            _load();
                          },
                          icon: const Icon(Icons.delete_outline, color: AppColors.rose, size: 20),
                        ),
                      ],
                    ),
                  ),
                )),
          const SizedBox(height: 24),
          Text('SÉCURITÉ', style: TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.1)),
          const SizedBox(height: 10),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Code PIN', style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w600, fontSize: 15)),
                        Text(_pinActif ? 'Activé — demandé à l\'ouverture' : 'Désactivé', style: TextStyle(color: context.textFaint, fontSize: 12)),
                      ],
                    ),
                    Icon(_pinActif ? Icons.lock_outline : Icons.lock_open_outlined, color: _pinActif ? AppColors.deepGreen : context.textFaint, size: 22),
                  ],
                ),
                const SizedBox(height: 12),
                if (_pinActif)
                  Row(
                    children: [
                      Expanded(child: GhostButton(label: 'Modifier', onPressed: () => _ouvrirGestionPin(creation: false))),
                      const SizedBox(width: 10),
                      Expanded(child: GhostButton(label: 'Retirer', onPressed: _retirerPin)),
                    ],
                  )
                else
                  GoldButton(label: 'Activer un code PIN', onPressed: () => _ouvrirGestionPin(creation: true)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('SAUVEGARDE', style: TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.1)),
          const SizedBox(height: 10),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Toutes les données restent uniquement sur ce téléphone. Exporte régulièrement une copie pour ne rien perdre si le téléphone est perdu, cassé, ou l'application supprimée par erreur.",
                  style: TextStyle(color: context.textFaint, fontSize: 12),
                ),
                const SizedBox(height: 14),
                if (_sauvegardeEnCours)
                  const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 10), child: CircularProgressIndicator(color: AppColors.gold)))
                else ...[
                  GoldButton(label: 'Exporter une copie', onPressed: _exporterSauvegarde),
                  const SizedBox(height: 10),
                  GhostButton(label: 'Restaurer une sauvegarde', onPressed: _restaurerSauvegarde),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('ENTREPRISE', style: TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.1)),
          const SizedBox(height: 10),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoRow(label: 'Nom', value: BusinessInfo.nom),
                _InfoRow(label: 'Activité', value: BusinessInfo.activite),
                _InfoRow(label: 'Adresse', value: BusinessInfo.ville),
                _InfoRow(label: 'Téléphone', value: BusinessInfo.tel),
                _InfoRow(label: 'Email', value: BusinessInfo.email, isLast: true),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text('Champions Style — Application v$appVersion', style: TextStyle(color: context.textFaint, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _ThemeChoiceTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _ThemeChoiceTile({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.gold.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? AppColors.gold : context.cardBorder),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: selected ? AppColors.gold : context.textMuted),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(color: selected ? AppColors.gold : context.textMuted, fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isLast;
  const _InfoRow({required this.label, required this.value, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: context.textFaint, fontSize: 13)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(value, style: TextStyle(color: context.textPrimary, fontSize: 13), textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }
}

/// Fenêtre de restauration — l'utilisateur colle le contenu texte du
/// fichier de sauvegarde exporté précédemment (ouvert dans n'importe
/// quelle application de fichiers/notes/email, puis copié).
class _RestaurationForm extends StatefulWidget {
  final VoidCallback onSuccess;
  const _RestaurationForm({required this.onSuccess});

  @override
  State<_RestaurationForm> createState() => _RestaurationFormState();
}

class _RestaurationFormState extends State<_RestaurationForm> {
  final _texteCtrl = TextEditingController();
  bool _enCours = false;
  String? _erreur;

  @override
  void dispose() {
    _texteCtrl.dispose();
    super.dispose();
  }

  Future<void> _collerDepuisPressePapier() async {
    final data = await Clipboard.getData('text/plain');
    if (data?.text != null) {
      setState(() => _texteCtrl.text = data!.text!);
    }
  }

  Future<void> _confirmerEtRestaurer() async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.isDark ? AppColors.surface : AppColors.surfaceLightMode,
        title: Text('Restaurer cette sauvegarde ?', style: TextStyle(color: context.textPrimary, fontSize: 16)),
        content: Text(
          "Toutes les données actuelles de l'application seront remplacées par celles-ci. Cette action ne peut pas être annulée.",
          style: TextStyle(color: context.textMuted, fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Annuler', style: TextStyle(color: context.textMuted))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Restaurer', style: TextStyle(color: AppColors.rose, fontWeight: FontWeight.w600))),
        ],
      ),
    );
    if (confirme != true) return;

    setState(() { _enCours = true; _erreur = null; });
    try {
      final reussi = await BackupService.restaurerDepuisTexte(_texteCtrl.text);
      if (!mounted) return;
      if (reussi) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sauvegarde restaurée avec succès.'), backgroundColor: AppColors.deepGreen));
        widget.onSuccess();
      }
    } catch (_) {
      setState(() => _erreur = "Ce contenu n'a pas pu être lu — vérifie qu'il s'agit bien d'une sauvegarde Champions Style complète.");
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Ouvre le fichier de sauvegarde exporté (dans tes fichiers, Google Drive, WhatsApp, email...), copie tout son contenu, puis colle-le ci-dessous.",
          style: TextStyle(color: context.textFaint, fontSize: 12.5),
        ),
        const SizedBox(height: 12),
        GhostButton(label: 'Coller depuis le presse-papier', onPressed: _collerDepuisPressePapier),
        const SizedBox(height: 12),
        TextField(
          controller: _texteCtrl,
          maxLines: 8,
          style: TextStyle(color: context.textPrimary, fontSize: 12),
          decoration: const InputDecoration(hintText: '{ "application": "Champions Style", ... }'),
        ),
        if (_erreur != null) ...[
          const SizedBox(height: 8),
          Text(_erreur!, style: const TextStyle(color: AppColors.rose, fontSize: 12)),
        ],
        const SizedBox(height: 18),
        if (_enCours)
          const Center(child: CircularProgressIndicator(color: AppColors.gold))
        else
          GoldButton(label: 'Restaurer', onPressed: _confirmerEtRestaurer),
      ],
    );
  }
}
