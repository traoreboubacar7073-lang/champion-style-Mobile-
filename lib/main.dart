import 'package:flutter/material.dart';
import 'data/repository.dart';
import 'theme/app_theme.dart';
import 'screens/main_shell.dart';
import 'screens/pin_lock_screen.dart';
import 'services/route_observer.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ChampionsStyleApp());
}

class ChampionsStyleApp extends StatefulWidget {
  const ChampionsStyleApp({super.key});

  @override
  State<ChampionsStyleApp> createState() => _ChampionsStyleAppState();
}

class _ChampionsStyleAppState extends State<ChampionsStyleApp> {
  bool _verrouille = false;
  String? _pinCode;
  bool _pretAAfficher = false;

  @override
  void initState() {
    super.initState();
    // Purge silencieuse des éléments de la corbeille de plus de 30 jours,
    // à chaque démarrage — comme sur les autres versions.
    TrashRepository().purgeExpired();
    _loadThemePreference();
    _loadPin();
  }

  Future<void> _loadPin() async {
    final pin = await ParametresRepository().getPinCode();
    if (!mounted) return;
    setState(() {
      _pinCode = (pin != null && pin.isNotEmpty) ? pin : null;
      _verrouille = _pinCode != null;
      _pretAAfficher = true;
    });
  }

  Future<void> _loadThemePreference() async {
    final saved = await ParametresRepository().getThemeMode();
    themeModeNotifier.value = saved == 'light' ? ThemeMode.light : ThemeMode.dark;
    final savedPolice = await ParametresRepository().getPoliceStyle();
    policeNotifier.value = savedPolice;
    final savedTaille = await ParametresRepository().getTailleTexte();
    tailleTexteNotifier.value = taillesTexte[savedTaille] ?? 1.0;
  }

  @override
  Widget build(BuildContext context) {
    // Toute l'application se redessine automatiquement dès que le thème,
    // la police ou la taille de texte choisis dans Paramètres changent,
    // sans avoir besoin de redémarrer.
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, mode, _) {
        return ValueListenableBuilder<String>(
          valueListenable: policeNotifier,
          builder: (context, police, __) {
            return ValueListenableBuilder<double>(
              valueListenable: tailleTexteNotifier,
              builder: (context, scale, ___) {
                return MaterialApp(
                  title: 'Champions Style',
                  debugShowCheckedModeBanner: false,
                  theme: AppTheme.build(dark: mode == ThemeMode.dark, police: police, scale: scale),
                  navigatorObservers: [routeObserver],
                  home: !_pretAAfficher
                      ? const Scaffold(backgroundColor: AppColors.background, body: SizedBox.shrink())
                      : (_verrouille && _pinCode != null)
                          ? PinLockScreen(correctPin: _pinCode!, onUnlocked: () => setState(() => _verrouille = false))
                          : const MainShell(),
                );
              },
            );
          },
        );
      },
    );
  }
}
