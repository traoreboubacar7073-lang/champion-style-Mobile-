import 'package:flutter/material.dart';
import '../data/repository.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class AlertItem {
  final String titre;
  final String detail;
  final IconData icon;
  final Color color;
  final String cible; // clé de section pour la navigation
  AlertItem({required this.titre, required this.detail, required this.icon, required this.color, required this.cible});
}

const List<String> _moisAbbrAlert = ['janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin', 'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'];

DateTime? _parseFrDateAlert(String s) {
  final parts = s.trim().split(RegExp(r'\s+'));
  if (parts.length != 3) return null;
  final day = int.tryParse(parts[0]);
  final monthIdx = _moisAbbrAlert.indexOf(parts[1]);
  final year = int.tryParse(parts[2]);
  if (day == null || monthIdx == -1 || year == null) return null;
  return DateTime(year, monthIdx + 1, day);
}

/// Rassemble toutes les alertes utiles de l'atelier — factures impayées,
/// stock bas, reliquats fournisseurs, livraisons et essayages proches —
/// exactement les mêmes catégories que sur les autres versions.
Future<List<AlertItem>> computeAlerts() async {
  final alerts = <AlertItem>[];

  final factures = await FactureRepository().all();
  for (final f in factures) {
    if (f.statut != 'Payée' && f.solde > 0) {
      alerts.add(AlertItem(
        titre: 'Facture ${f.statut == 'Impayée' ? 'impayée' : 'partiellement payée'} — ${f.client}',
        detail: '${f.id} · Solde restant : ${fmtFcfa(f.solde)}',
        icon: Icons.receipt_long_outlined, color: AppColors.rose, cible: 'factures',
      ));
    }
  }

  final stock = await StockRepository().all();
  for (final s in stock) {
    if (s.bas) {
      alerts.add(AlertItem(
        titre: 'Stock bas — ${s.nom}',
        detail: '${s.qte.toStringAsFixed(0)} / ${s.seuil.toStringAsFixed(0)} ${s.unite}',
        icon: Icons.warning_amber_rounded, color: AppColors.rose, cible: 'stock',
      ));
    }
  }

  final depenses = await DepenseRepository().all();
  for (final d in depenses) {
    if (d.reliquat > 0) {
      alerts.add(AlertItem(
        titre: 'Reliquat à régler — ${d.fournisseur.isNotEmpty ? d.fournisseur : d.categorie}',
        detail: '${d.categorie} · Reste dû : ${fmtFcfa(d.reliquat)}',
        icon: Icons.account_balance_wallet_outlined, color: AppColors.rose, cible: 'depenses',
      ));
    }
  }

  final commandes = await CommandeRepository().all();
  final now = DateTime.now();
  final dansTroisJours = now.add(const Duration(days: 3));
  for (final c in commandes) {
    if (c.statut == 'Livrée') continue;
    final dateLivraison = _parseFrDateAlert(c.livraison);
    if (dateLivraison != null && !dateLivraison.isBefore(DateTime(now.year, now.month, now.day)) && !dateLivraison.isAfter(dansTroisJours)) {
      alerts.add(AlertItem(
        titre: 'Livraison proche — ${c.client}',
        detail: '${c.id} · Prévue le ${c.livraison}',
        icon: Icons.local_shipping_outlined, color: AppColors.gold, cible: 'commandes',
      ));
    }
    if (c.dateEssayage.isNotEmpty) {
      final dateEssayage = _parseFrDateAlert(c.dateEssayage);
      if (dateEssayage != null && !dateEssayage.isBefore(DateTime(now.year, now.month, now.day)) && !dateEssayage.isAfter(dansTroisJours)) {
        alerts.add(AlertItem(
          titre: 'Essayage proche — ${c.client}',
          detail: '${c.id} · Prévu le ${c.dateEssayage}',
          icon: Icons.event_outlined, color: AppColors.purple, cible: 'commandes',
        ));
      }
    }
  }

  final employes = await EmployeRepository().all();
  final paiementsEmployes = await PaiementEmployeRepository().all();
  for (final e in employes) {
    // "Par tenue" n'est pas basé sur une échéance de calendrier (on paie
    // à la pièce confectionnée) — pas d'alerte automatique pertinente ici.
    if (e.frequencePaiement == 'Par tenue') continue;

    final paiementsDeCetEmploye = paiementsEmployes.where((p) => p.employe == e.nom).toList();
    DateTime? dernierPaiement;
    for (final p in paiementsDeCetEmploye) {
      final d = _parseFrDateAlert(p.date);
      if (d != null && (dernierPaiement == null || d.isAfter(dernierPaiement))) dernierPaiement = d;
    }

    bool estDu = false;
    String detail;
    if (dernierPaiement == null) {
      estDu = true;
      detail = 'Aucun paiement enregistré pour le moment';
    } else {
      final joursDepuis = DateTime(now.year, now.month, now.day).difference(dernierPaiement).inDays;
      final seuil = e.frequencePaiement == 'Journalier' ? 1 : (e.frequencePaiement == 'Hebdomadaire' ? 7 : 30);
      estDu = joursDepuis >= seuil;
      detail = 'Dernier versement le ${_formatDateAlert(dernierPaiement)} · ${e.frequencePaiement}';
    }

    if (estDu) {
      alerts.add(AlertItem(
        titre: 'Paiement employé dû — ${e.nom}',
        detail: detail,
        icon: Icons.payments_outlined, color: AppColors.purple, cible: 'employes',
      ));
    }
  }

  return alerts;
}

String _formatDateAlert(DateTime d) {
  return '${d.day.toString().padLeft(2, '0')} ${_moisAbbrAlert[d.month - 1]} ${d.year}';
}
