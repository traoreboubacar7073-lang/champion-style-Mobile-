import 'package:flutter/material.dart';
import '../widgets/shared_widgets.dart';

/// Écran temporaire pour les modules qui seront construits dans une
/// prochaine étape — même principe que sur la version web mobile :
/// on avance module par module, en testant chaque fois.
class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: const Center(
        child: EmptyState(
          icon: Icons.construction_outlined,
          text: 'Ce module arrive dans la prochaine étape de construction.',
        ),
      ),
    );
  }
}
