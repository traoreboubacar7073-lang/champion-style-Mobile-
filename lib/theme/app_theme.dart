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

class AppTheme {
  AppTheme._();

  static ThemeData get theme {
    final headingFont = GoogleFonts.cormorantGaramond(
      fontWeight: FontWeight.w700,
    );
    final bodyFont = GoogleFonts.inter();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: bodyFont.fontFamily,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.gold,
        secondary: AppColors.goldLight,
        surface: AppColors.surface,
        error: AppColors.rose,
      ),
      textTheme: TextTheme(
        displayLarge: headingFont.copyWith(fontSize: 30, color: AppColors.textPrimary),
        headlineMedium: headingFont.copyWith(fontSize: 22, color: AppColors.textPrimary),
        titleLarge: headingFont.copyWith(fontSize: 18, color: AppColors.textPrimary),
        bodyLarge: bodyFont.copyWith(fontSize: 15, color: AppColors.textPrimary),
        bodyMedium: bodyFont.copyWith(fontSize: 13, color: AppColors.textMuted),
        bodySmall: bodyFont.copyWith(fontSize: 11, color: AppColors.textFaint),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        titleTextStyle: headingFont.copyWith(fontSize: 18, color: AppColors.textPrimary),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      // Remarque : le thème "Card" natif de Flutter n'est pas utilisé ici —
      // l'application utilise son propre composant AppCard (voir
      // widgets/shared_widgets.dart), pour garder une apparence identique
      // sur toutes les versions (ordinateur, web, mobile).
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceLight,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.gold, width: 1.4),
        ),
        hintStyle: bodyFont.copyWith(color: AppColors.textFaint, fontSize: 14),
        labelStyle: bodyFont.copyWith(color: AppColors.textMuted, fontSize: 13),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.background,
        selectedItemColor: AppColors.gold,
        unselectedItemColor: AppColors.textFaint,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: bodyFont.copyWith(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1),
    );
  }
}
