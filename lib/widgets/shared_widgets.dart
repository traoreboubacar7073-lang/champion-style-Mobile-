import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
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

extension ThemeHelpers on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get cardBg => isDark ? AppColors.surfaceLight : AppColors.surfaceLightModeSubtle;
  Color get cardBorder => isDark ? AppColors.border : AppColors.borderLight;
  Color get textPrimary => isDark ? AppColors.textPrimary : AppColors.textPrimaryLight;
  Color get textMuted => isDark ? AppColors.textMuted : AppColors.textMutedLight;
  Color get textFaint => isDark ? AppColors.textFaint : AppColors.textFaintLight;
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
            color: context.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.cardBorder),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        statut,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
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
            if (icon != null) ...[Icon(icon, size: 19), const SizedBox(width: 8)],
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
          foregroundColor: context.textPrimary,
          padding: const EdgeInsets.symmetric(vertical: 17),
          side: BorderSide(color: context.cardBorder),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
      ),
    );
  }
}

class AppAvatar extends StatelessWidget {
  final String name;
  final double size;
  const AppAvatar({super.key, required this.name, this.size = 44});

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
    // Center() s'étire pour occuper tout l'espace disponible puis centre
    // son contenu à l'intérieur — indépendamment de l'alignement de la
    // colonne parente (qui, sur la plupart des écrans, aligne à gauche).
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 36, color: context.textFaint),
            const SizedBox(height: 12),
            Text(text, style: TextStyle(color: context.textFaint, fontSize: 14), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

/// Sélecteur relié à un catalogue existant (ex : Fournisseurs, Produits) —
/// affiche les éléments déjà enregistrés dans une liste déroulante, avec
/// une option "+ Autre" qui fait apparaître un champ libre pour les cas
/// où l'élément n'existe pas encore dans le catalogue (ex : un client qui
/// apporte son propre modèle, ou un tout nouveau fournisseur ponctuel).
class CatalogPickerField extends StatefulWidget {
  final List<String> options;
  final String? initialValue;
  final String hintText;
  final String customHintText;
  final ValueChanged<String?> onChanged;
  const CatalogPickerField({
    super.key,
    required this.options,
    this.initialValue,
    this.hintText = 'Choisir…',
    this.customHintText = 'Saisir un nom personnalisé',
    required this.onChanged,
  });

  @override
  State<CatalogPickerField> createState() => _CatalogPickerFieldState();
}

class _CatalogPickerFieldState extends State<CatalogPickerField> {
  static const _customKey = '__autre__';
  String? _selected;
  late TextEditingController _customCtrl;

  @override
  void initState() {
    super.initState();
    _customCtrl = TextEditingController();
    final initial = widget.initialValue;
    if (initial != null && initial.isNotEmpty) {
      if (widget.options.contains(initial)) {
        _selected = initial;
      } else {
        _selected = _customKey;
        _customCtrl.text = initial;
      }
    }
  }

  @override
  void dispose() {
    _customCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: _selected,
          dropdownColor: AppColors.surface,
          isExpanded: true,
          hint: Text(widget.hintText, style: TextStyle(color: context.textFaint)),
          items: [
            for (final o in widget.options)
              DropdownMenuItem(value: o, child: Text(o, style: TextStyle(color: context.textPrimary), overflow: TextOverflow.ellipsis)),
            const DropdownMenuItem(value: _customKey, child: Text('+ Autre (saisir un nom)', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w600))),
          ],
          onChanged: (v) {
            setState(() => _selected = v);
            widget.onChanged(v == _customKey ? _customCtrl.text.trim() : v);
          },
        ),
        if (_selected == _customKey) ...[
          const SizedBox(height: 8),
          TextField(
            controller: _customCtrl,
            decoration: InputDecoration(hintText: widget.customHintText),
            onChanged: (v) => widget.onChanged(v.trim()),
          ),
        ],
      ],
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
                style: const TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2),
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
  final IconData icon;
  const FabRound({super.key, required this.onPressed, this.icon = Icons.add});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 42,
        height: 42,
        decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.goldGradient),
        child: Icon(icon, color: Colors.black, size: 22),
      ),
    );
  }
}

/// Sélecteur de photo — permet de prendre une photo avec l'appareil photo
/// du téléphone ou d'en choisir une depuis la galerie. La photo est
/// stockée encodée en base64 (comme sur les versions ordinateur et web),
/// pour rester simple et ne dépendre d'aucun stockage de fichiers externe.
class PhotoPickerField extends StatefulWidget {
  final String? initialBase64;
  final ValueChanged<String?> onChanged;
  const PhotoPickerField({super.key, this.initialBase64, required this.onChanged});

  @override
  State<PhotoPickerField> createState() => _PhotoPickerFieldState();
}

class _PhotoPickerFieldState extends State<PhotoPickerField> {
  String? _base64;

  @override
  void initState() {
    super.initState();
    _base64 = widget.initialBase64;
  }

  Future<void> _pick(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(source: source, maxWidth: 1080, imageQuality: 80);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      final b64 = base64Encode(bytes);
      if (!mounted) return;
      setState(() => _base64 = b64);
      widget.onChanged(b64);
    } catch (_) {
      // Si l'appareil ne permet pas l'accès (permission refusée, pas de
      // caméra sur un émulateur, etc.), on ne bloque pas le formulaire —
      // la photo reste simplement facultative.
    }
  }

  void _showSourceSheet() {
    final dark = context.isDark;
    showModalBottomSheet(
      context: context,
      backgroundColor: dark ? AppColors.surface : AppColors.surfaceLightMode,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.photo_camera_outlined, color: ctx.textPrimary),
              title: Text('Prendre une photo', style: TextStyle(color: ctx.textPrimary)),
              onTap: () { Navigator.pop(ctx); _pick(ImageSource.camera); },
            ),
            ListTile(
              leading: Icon(Icons.photo_library_outlined, color: ctx.textPrimary),
              title: Text('Choisir dans la galerie', style: TextStyle(color: ctx.textPrimary)),
              onTap: () { Navigator.pop(ctx); _pick(ImageSource.gallery); },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_base64 != null && _base64!.isNotEmpty) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.memory(base64Decode(_base64!), height: 160, width: double.infinity, fit: BoxFit.cover),
          ),
          Positioned(
            top: 8, right: 8,
            child: InkWell(
              onTap: () { setState(() => _base64 = null); widget.onChanged(null); },
              child: Container(
                width: 28, height: 28,
                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      );
    }
    return InkWell(
      onTap: _showSourceSheet,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 110,
        width: double.infinity,
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.cardBorder),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_outlined, color: context.textFaint, size: 26),
            const SizedBox(height: 8),
            Text('Prendre une photo ou choisir', style: TextStyle(color: context.textFaint, fontSize: 12.5)),
          ],
        ),
      ),
    );
  }
}

/// Ouvre une feuille modale qui remonte du bas de l'écran — équivalent
/// du "BottomSheet" utilisé sur la version web mobile.
Future<T?> showAppBottomSheet<T>(BuildContext context, {required String title, required Widget child}) {
  final dark = context.isDark;
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: dark ? AppColors.surface : AppColors.surfaceLightMode,
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
                      Expanded(child: Text(title, style: Theme.of(ctx).textTheme.titleLarge)),
                      IconButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        icon: Icon(Icons.close, color: ctx.textPrimary, size: 20),
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
