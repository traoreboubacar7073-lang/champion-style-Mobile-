import 'package:flutter/material.dart';
import '../data/repository.dart';
import '../models/utilisateur.dart';
import '../theme/app_theme.dart';
import '../theme/business_info.dart';
import '../widgets/shared_widgets.dart';

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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final users = await _userRepo.all();
    if (!mounted) return;
    setState(() {
      _users = users;
      _loading = false;
    });
  }

  Future<void> _setTheme(ThemeMode mode) async {
    themeModeNotifier.value = mode;
    await _paramRepo.setThemeMode(mode == ThemeMode.light ? 'light' : 'dark');
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
