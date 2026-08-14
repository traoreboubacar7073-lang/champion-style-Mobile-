import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Palette de couleurs — identique aux versions ordinateur et web mobile
/// de Champions Style, pour garder une identité visuelle cohérente partout.
class AppColors {
  AppColors._();

  static const Color background = Color(0xFF0A0A0C);
  static const Color surface = Color(0xFF141417);
  static const Color surfaceLight = Color(0x0DFFFFFF); // blanc à 5% d'opacité
  static const Color border = Color(0x1AFFFFFF); // blanc à 10% d'opacité

  // Équivalents pour le thème clair
  static const Color backgroundLight = Color(0xFFFAF8F3);
  static const Color surfaceLightMode = Color(0xFFFFFFFF);
  static const Color surfaceLightModeSubtle = Color(0xFFF3EFE4);
  static const Color borderLight = Color(0x14000000);

  static const Color gold = Color(0xFFC9A430);
  static const Color goldLight = Color(0xFFF0D584);
  static const Color goldDark = Color(0xFF8B6F1F);

  static const Color deepGreen = Color(0xFF1F6B4C);
  static const Color rose = Color(0xFFE1596B);
  static const Color blue = Color(0xFF6C8FE0);
  static const Color purple = Color(0xFFA77DE0);
  static const Color pink = Color(0xFFD98FB0);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFF9CA3AF);
  static const Color textFaint = Color(0xFF6B7280);

  static const Color textPrimaryLight = Color(0xFF1C1C1E);
  static const Color textMutedLight = Color(0xFF6B6B6B);
  static const Color textFaintLight = Color(0xFF9A9A9A);

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [goldLight, gold],
  );
}

/// Couleurs associées à chaque statut (commande, devis, facture...) — reprend
/// exactement la même logique que sur les versions ordinateur et web.
class StatutColors {
  StatutColors._();

  static const Map<String, Color> map = {
    'Nouvelle': AppColors.blue,
    'En cours': AppColors.gold,
    'Essayage': AppColors.purple,
    'Prête': AppColors.deepGreen,
    'Livrée': AppColors.textFaint,
    'En attente': AppColors.textFaint,
    'Accepté': AppColors.deepGreen,
    'Refusé': AppColors.rose,
    'Payée': AppColors.deepGreen,
    'Partielle': AppColors.gold,
    'Impayée': AppColors.rose,
  };

  static Color of(String? statut) => map[statut] ?? AppColors.textFaint;
}

/// Préférence de thème de l'application (clair / sombre), modifiable
/// depuis l'écran Paramètres et sauvegardée localement. Toute l'app
/// écoute cette valeur pour se redessiner instantanément au changement.
final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(ThemeMode.dark);

class AppTheme {
  AppTheme._();

  static ThemeData get theme => _build(dark: true);
  static ThemeData get lightTheme => _build(dark: false);

  static ThemeData _build({required bool dark}) {
    final bg = dark ? AppColors.background : AppColors.backgroundLight;
    final surfaceLight = dark ? AppColors.surfaceLight : AppColors.surfaceLightModeSubtle;
    final border = dark ? AppColors.border : AppColors.borderLight;
    final textPrimary = dark ? AppColors.textPrimary : AppColors.textPrimaryLight;
    final textMuted = dark ? AppColors.textMuted : AppColors.textMutedLight;
    final textFaint = dark ? AppColors.textFaint : AppColors.textFaintLight;

    // Tailles de texte volontairement généreuses, pour une lecture
    // confortable sur mobile — plus grandes que la première version.
    final headingFont = GoogleFonts.cormorantGaramond(fontWeight: FontWeight.w700);
    final bodyFont = GoogleFonts.inter();

    return ThemeData(
      useMaterial3: true,
      brightness: dark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: bg,
      fontFamily: bodyFont.fontFamily,
      colorScheme: dark
          ? const ColorScheme.dark(primary: AppColors.gold, secondary: AppColors.goldLight, surface: AppColors.surface, error: AppColors.rose)
          : ColorScheme.light(primary: AppColors.goldDark, secondary: AppColors.gold, surface: AppColors.surfaceLightModeSubtle, error: AppColors.rose),
      textTheme: TextTheme(
        displayLarge: headingFont.copyWith(fontSize: 34, color: textPrimary),
        headlineMedium: headingFont.copyWith(fontSize: 25, color: textPrimary),
        titleLarge: headingFont.copyWith(fontSize: 20, color: textPrimary),
        bodyLarge: bodyFont.copyWith(fontSize: 16, color: textPrimary),
        bodyMedium: bodyFont.copyWith(fontSize: 14, color: textMuted),
        bodySmall: bodyFont.copyWith(fontSize: 12, color: textFaint),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        elevation: 0,
        titleTextStyle: headingFont.copyWith(fontSize: 19, color: textPrimary),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      // Remarque : le thème "Card" natif de Flutter n'est pas utilisé ici —
      // l'application utilise son propre composant AppCard (voir
      // widgets/shared_widgets.dart), pour garder une apparence identique
      // sur toutes les versions (ordinateur, web, mobile).
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceLight,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gold, width: 1.4)),
        hintStyle: bodyFont.copyWith(color: textFaint, fontSize: 15),
        labelStyle: bodyFont.copyWith(color: textMuted, fontSize: 14),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: bg,
        selectedItemColor: dark ? AppColors.gold : AppColors.goldDark,
        unselectedItemColor: textFaint,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 17),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: bodyFont.copyWith(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1),
    );
  }
}
