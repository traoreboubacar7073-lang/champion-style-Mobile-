import 'package:flutter/material.dart';
import 'data/repository.dart';
import 'theme/app_theme.dart';
import 'screens/main_shell.dart';

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
  @override
  void initState() {
    super.initState();
    // Purge silencieuse des éléments de la corbeille de plus de 30 jours,
    // à chaque démarrage — comme sur les autres versions.
    TrashRepository().purgeExpired();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Champions Style',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const MainShell(),
    );
  }
}
