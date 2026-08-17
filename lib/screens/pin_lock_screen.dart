import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/business_info.dart';

/// Écran de verrouillage par code PIN — affiché au lancement de
/// l'application si un code a été défini dans Paramètres. Empêche
/// l'accès aux données si quelqu'un d'autre prend le téléphone.
class PinLockScreen extends StatefulWidget {
  final String correctPin;
  final VoidCallback onUnlocked;
  const PinLockScreen({super.key, required this.correctPin, required this.onUnlocked});

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen> {
  String _saisie = '';
  bool _erreur = false;

  void _appuyerChiffre(String chiffre) {
    if (_saisie.length >= 6) return;
    setState(() {
      _saisie += chiffre;
      _erreur = false;
    });
    if (_saisie.length == widget.correctPin.length) {
      if (_saisie == widget.correctPin) {
        widget.onUnlocked();
      } else {
        setState(() {
          _erreur = true;
          _saisie = '';
        });
      }
    }
  }

  void _effacer() {
    if (_saisie.isEmpty) return;
    setState(() => _saisie = _saisie.substring(0, _saisie.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(color: AppColors.gold.withOpacity(0.12), borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.lock_outline, color: AppColors.gold, size: 28),
              ),
              const SizedBox(height: 18),
              Text(BusinessInfo.nom, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              const Text('Entrez le code PIN pour continuer', style: TextStyle(color: AppColors.textFaint, fontSize: 13)),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.correctPin.length, (i) {
                  final rempli = i < _saisie.length;
                  return Container(
                    width: 14, height: 14,
                    margin: const EdgeInsets.symmetric(horizontal: 7),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _erreur ? AppColors.rose : (rempli ? AppColors.gold : Colors.transparent),
                      border: Border.all(color: _erreur ? AppColors.rose : AppColors.gold, width: 1.5),
                    ),
                  );
                }),
              ),
              if (_erreur) ...[
                const SizedBox(height: 14),
                const Text('Code incorrect, réessaie.', style: TextStyle(color: AppColors.rose, fontSize: 12.5)),
              ],
              const Spacer(),
              _buildClavier(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClavier() {
    final lignes = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', '⌫'],
    ];
    return Column(
      children: [
        for (final ligne in lignes)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final touche in ligne)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: SizedBox(
                      width: 64, height: 64,
                      child: touche.isEmpty
                          ? null
                          : Material(
                              color: Colors.white.withOpacity(0.05),
                              shape: const CircleBorder(),
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: () => touche == '⌫' ? _effacer() : _appuyerChiffre(touche),
                                child: Center(
                                  child: touche == '⌫'
                                      ? const Icon(Icons.backspace_outlined, color: Colors.white70, size: 20)
                                      : Text(touche, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w500)),
                                ),
                              ),
                            ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
