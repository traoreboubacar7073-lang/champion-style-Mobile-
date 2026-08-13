import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Formate un montant en francs CFA (ex : "45 000 FCFA") — même format
/// que sur les versions ordinateur et web mobile. Écrit à la main plutôt
/// que via le paquet `intl`, pour éviter tout souci d'initialisation de
/// locale au démarrage de l'application.
String fmtFcfa(num amount) {
  final rounded = amount.round();
  final digits = rounded.abs().toString();
  final buffer = StringBuffer();
  for (int i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(' ');
    buffer.write(digits[i]);
  }
  final sign = rounded < 0 ? '-' : '';
  return '$sign${buffer.toString()} FCFA';
}

class AppCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  const AppCard({super.key, required this.child, this.onTap, this.padding = const EdgeInsets.all(16)});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: child,
        ),
      ),
    );
  }
}

class StatutBadge extends StatelessWidget {
  final String statut;
  const StatutBadge({super.key, required this.statut});

  @override
  Widget build(BuildContext context) {
    final color = StatutColors.of(statut);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        statut,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class GoldButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;

  const GoldButton({super.key, required this.label, required this.onPressed, this.icon});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
            Text(label),
          ],
        ),
      ),
    );
  }
}

class GhostButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const GhostButton({super.key, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      ),
    );
  }
}

class AppAvatar extends StatelessWidget {
  final String name;
  final double size;
  const AppAvatar({super.key, required this.name, this.size = 42});

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    final letters = parts.take(2).map((p) => p.isNotEmpty ? p[0].toUpperCase() : '').join();
    return letters.isEmpty ? '?' : letters;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.goldGradient),
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700, fontSize: size * 0.38),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String text;
  const EmptyState({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64),
      child: Column(
        children: [
          Icon(icon, size: 34, color: AppColors.textFaint),
          const SizedBox(height: 12),
          Text(text, style: const TextStyle(color: AppColors.textFaint, fontSize: 13)),
        ],
      ),
    );
  }
}

class ScreenHeader extends StatelessWidget {
  final String eyebrow;
  final String title;
  final Widget? action;

  const ScreenHeader({super.key, required this.eyebrow, required this.title, this.action});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow.toUpperCase(),
                style: const TextStyle(color: AppColors.gold, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2),
              ),
              const SizedBox(height: 3),
              Text(title, style: Theme.of(context).textTheme.headlineMedium),
            ],
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}

/// Bouton rond doré, utilisé comme action "+" en haut à droite des écrans.
class FabRound extends StatelessWidget {
  final VoidCallback onPressed;
  const FabRound({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.goldGradient),
        child: const Icon(Icons.add, color: Colors.black, size: 22),
      ),
    );
  }
}

/// Ouvre une feuille modale qui remonte du bas de l'écran — équivalent
/// du "BottomSheet" utilisé sur la version web mobile.
Future<T?> showAppBottomSheet<T>(BuildContext context, {required String title, required Widget child}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(title, style: Theme.of(ctx).textTheme.titleLarge),
                      IconButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        icon: const Icon(Icons.close, color: Colors.white, size: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  child,
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
