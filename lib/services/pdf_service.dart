import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/facture.dart';
import '../models/boutique.dart';
import '../theme/business_info.dart';
import '../widgets/shared_widgets.dart';

/// Génère des documents PDF (factures, reçus de paiement) et permet de
/// les partager directement (WhatsApp, email, Bluetooth...), de les
/// télécharger, ou de les imprimer — via le sélecteur natif du téléphone.
class PdfService {
  PdfService._();

  static final _gold = PdfColor.fromInt(0xFFC9A430);
  static final _dark = PdfColor.fromInt(0xFF1C1C1E);
  static final _grey = PdfColor.fromInt(0xFF6B6B6B);
  static final _paleGold = PdfColor.fromInt(0xFFF7F1DF);
  static final _green = PdfColor.fromInt(0xFF1F6B4C);
  static final _rose = PdfColor.fromInt(0xFFE1596B);

  static pw.MemoryImage? _logoCache;

  /// Charge le logo une seule fois (mis en cache pour les documents
  /// suivants) — évite de relire le fichier à chaque génération de PDF.
  static Future<pw.MemoryImage> _loadLogo() async {
    if (_logoCache != null) return _logoCache!;
    final data = await rootBundle.load('assets/images/logo.png');
    _logoCache = pw.MemoryImage(data.buffer.asUint8List());
    return _logoCache!;
  }

  static pw.Widget _header(pw.MemoryImage logo) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Container(width: 48, height: 48, child: pw.Image(logo)),
            pw.SizedBox(width: 12),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(BusinessInfo.nom, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: _dark)),
                pw.SizedBox(height: 3),
                pw.Text(BusinessInfo.slogan, style: pw.TextStyle(fontSize: 10, color: _gold, fontStyle: pw.FontStyle.italic)),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 12),
        pw.Text(BusinessInfo.ville, style: pw.TextStyle(fontSize: 9, color: _grey)),
        pw.Text('${BusinessInfo.tel}  ·  ${BusinessInfo.email}', style: pw.TextStyle(fontSize: 9, color: _grey)),
        pw.SizedBox(height: 14),
        pw.Divider(color: _gold, thickness: 1.2),
        pw.SizedBox(height: 14),
      ],
    );
  }

  static pw.Widget _ligneMontant(String label, String value, {bool bold = false, PdfColor? color}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 11, color: _grey)),
        pw.Text(value, style: pw.TextStyle(fontSize: bold ? 15 : 12, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal, color: color ?? _dark)),
      ],
    );
  }

  /// Facture complète — montant total, ce qui a déjà été versé, et le
  /// solde restant dû, calculés directement depuis la commande.
  static Future<Uint8List> buildFacturePdf(Facture facture) async {
    final doc = pw.Document();
    final logo = await _loadLogo();
    final montantPaye = facture.montant - facture.solde;

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _header(logo),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('FACTURE', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: _dark)),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(facture.id, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: _gold)),
                      pw.Text(facture.date, style: pw.TextStyle(fontSize: 10, color: _grey)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 24),
              pw.Text('CLIENT', style: pw.TextStyle(fontSize: 9, color: _grey, letterSpacing: 1)),
              pw.SizedBox(height: 2),
              pw.Text(facture.client, style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold, color: _dark)),
              pw.SizedBox(height: 26),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(color: _paleGold, borderRadius: pw.BorderRadius.circular(10)),
                child: pw.Column(
                  children: [
                    _ligneMontant('Montant total', fmtFcfa(facture.montant), bold: true),
                    pw.SizedBox(height: 10),
                    _ligneMontant('Déjà versé', fmtFcfa(montantPaye)),
                    pw.SizedBox(height: 10),
                    pw.Divider(color: _grey, thickness: 0.5),
                    pw.SizedBox(height: 10),
                    _ligneMontant(
                      'Solde restant',
                      fmtFcfa(facture.solde),
                      bold: true,
                      color: facture.solde > 0 ? _rose : _green,
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text('Statut : ${facture.statut}', style: pw.TextStyle(fontSize: 11, color: _dark, fontWeight: pw.FontWeight.bold)),
              pw.Spacer(),
              pw.Divider(color: _grey, thickness: 0.5),
              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Text('Merci de votre confiance — ${BusinessInfo.nom}', style: pw.TextStyle(fontSize: 9, color: _grey, fontStyle: pw.FontStyle.italic)),
              ),
            ],
          );
        },
      ),
    );
    return doc.save();
  }

  /// Reçu de paiement simple — utile à remettre au client comme preuve
  /// d'un versement, séparément de la facture complète.
  static Future<Uint8List> buildRecuPdf({
    required String client,
    required double montant,
    required String date,
    String? referenceFacture,
    double? soldeRestant,
  }) async {
    final doc = pw.Document();
    final logo = await _loadLogo();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.all(32),
        build: (ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _header(logo),
              pw.Text('REÇU DE PAIEMENT', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: _dark)),
              pw.SizedBox(height: 16),
              pw.Text('Date : $date', style: pw.TextStyle(fontSize: 10, color: _grey)),
              pw.SizedBox(height: 6),
              pw.Text('Reçu de : $client', style: pw.TextStyle(fontSize: 13, color: _dark, fontWeight: pw.FontWeight.bold)),
              if (referenceFacture != null) ...[
                pw.SizedBox(height: 4),
                pw.Text('Référence facture : $referenceFacture', style: pw.TextStyle(fontSize: 10, color: _grey)),
              ],
              pw.SizedBox(height: 20),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(color: _paleGold, borderRadius: pw.BorderRadius.circular(10)),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Montant reçu', style: pw.TextStyle(fontSize: 10, color: _grey)),
                    pw.SizedBox(height: 4),
                    pw.Text(fmtFcfa(montant), style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: _gold)),
                    if (soldeRestant != null) ...[
                      pw.SizedBox(height: 12),
                      pw.Divider(color: _grey, thickness: 0.5),
                      pw.SizedBox(height: 10),
                      _ligneMontant(
                        'Solde restant à payer',
                        fmtFcfa(soldeRestant),
                        bold: true,
                        color: soldeRestant > 0 ? _rose : _green,
                      ),
                    ],
                  ],
                ),
              ),
              pw.SizedBox(height: 26),
              pw.Text('Merci de votre confiance.', style: pw.TextStyle(fontSize: 10, color: _grey, fontStyle: pw.FontStyle.italic)),
            ],
          );
        },
      ),
    );
    return doc.save();
  }

  /// Ouvre le sélecteur natif de partage du téléphone (WhatsApp, email,
  /// Bluetooth...) ou permet d'enregistrer le PDF directement.
  /// Devis à envoyer au client pour validation — même mise en page que la
  /// facture, avec la mention "DEVIS" et une durée de validité indicative.
  static Future<Uint8List> buildDevisPdf({
    required String id,
    required String client,
    required double montant,
    required String statut,
    required String date,
  }) async {
    final doc = pw.Document();
    final logo = await _loadLogo();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _header(logo),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('DEVIS', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: _dark)),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(id, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: _gold)),
                      pw.Text(date, style: pw.TextStyle(fontSize: 10, color: _grey)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 24),
              pw.Text('CLIENT', style: pw.TextStyle(fontSize: 9, color: _grey, letterSpacing: 1)),
              pw.SizedBox(height: 2),
              pw.Text(client, style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold, color: _dark)),
              pw.SizedBox(height: 26),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(color: _paleGold, borderRadius: pw.BorderRadius.circular(10)),
                child: _ligneMontant('Montant estimé', fmtFcfa(montant), bold: true),
              ),
              pw.SizedBox(height: 20),
              pw.Text('Statut : $statut', style: pw.TextStyle(fontSize: 11, color: _dark, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6),
              pw.Text('Ce devis est valable 30 jours à compter de sa date d\'émission.', style: pw.TextStyle(fontSize: 9.5, color: _grey, fontStyle: pw.FontStyle.italic)),
              pw.Spacer(),
              pw.Divider(color: _grey, thickness: 0.5),
              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Text('Merci de votre confiance — ${BusinessInfo.nom}', style: pw.TextStyle(fontSize: 9, color: _grey, fontStyle: pw.FontStyle.italic)),
              ),
            ],
          );
        },
      ),
    );
    return doc.save();
  }

  /// Catalogue des articles de la boutique — à partager avec un
  /// partenaire, un fournisseur, ou simplement garder une trace des prix
  /// pratiqués. Regroupé par catégorie, pour une lecture plus claire.
  static Future<Uint8List> buildCatalogueBoutiquePdf(List<ArticleBoutique> articles) async {
    final doc = pw.Document();
    final logo = await _loadLogo();

    final Map<String, List<ArticleBoutique>> parCategorie = {};
    for (final a in articles) {
      parCategorie.putIfAbsent(a.categorie, () => []).add(a);
    }
    final categoriesTriees = parCategorie.keys.toList()..sort();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (ctx) => [
          _header(logo),
          pw.Text('CATALOGUE BOUTIQUE', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: _dark)),
          pw.SizedBox(height: 22),
          if (articles.isEmpty)
            pw.Text('Aucun article enregistré pour le moment.', style: pw.TextStyle(fontSize: 11, color: _grey))
          else
            for (final cat in categoriesTriees) ...[
              pw.Text(cat.toUpperCase(), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: _gold, letterSpacing: 0.8)),
              pw.SizedBox(height: 6),
              pw.Table(
                columnWidths: {0: const pw.FlexColumnWidth(3), 1: const pw.FlexColumnWidth(1)},
                children: [
                  for (final a in parCategorie[cat]!)
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 5),
                          child: pw.Text(a.nom, style: pw.TextStyle(fontSize: 11, color: _dark)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 5),
                          child: pw.Text(fmtFcfa(a.prix), style: pw.TextStyle(fontSize: 11, color: _dark, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right),
                        ),
                      ],
                    ),
                ],
              ),
              pw.SizedBox(height: 16),
            ],
        ],
      ),
    );
    return doc.save();
  }

  /// Fiche de mesures d'un client — à imprimer ou partager pour le
  /// couturier en charge de la commande, avec toutes les mesures
  /// enregistrées (grille Homme ou Femme selon le client).
  static Future<Uint8List> buildFicheMesuresPdf({
    required String client,
    required String sexe,
    required Map<String, dynamic> mesures,
    required Map<String, String> labels,
  }) async {
    final doc = pw.Document();
    final logo = await _loadLogo();
    final entries = mesures.entries.where((e) {
      final v = e.value;
      if (v is num) return v != 0;
      return v != null && v.toString().isNotEmpty;
    }).toList();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _header(logo),
              pw.Text('FICHE DE MESURES', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: _dark)),
              pw.SizedBox(height: 4),
              if (sexe.isNotEmpty) pw.Text(sexe.toUpperCase(), style: pw.TextStyle(fontSize: 10, color: _gold, fontWeight: pw.FontWeight.bold, letterSpacing: 1)),
              pw.SizedBox(height: 20),
              pw.Text('CLIENT', style: pw.TextStyle(fontSize: 9, color: _grey, letterSpacing: 1)),
              pw.SizedBox(height: 2),
              pw.Text(client, style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold, color: _dark)),
              pw.SizedBox(height: 26),
              if (entries.isEmpty)
                pw.Text('Aucune mesure enregistrée pour ce client.', style: pw.TextStyle(fontSize: 11, color: _grey))
              else
                pw.Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final e in entries)
                      pw.Container(
                        width: 130,
                        padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        decoration: pw.BoxDecoration(color: _paleGold, borderRadius: pw.BorderRadius.circular(8)),
                        child: pw.Column(
                          children: [
                            pw.Text('${e.value}', style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold, color: _dark)),
                            pw.SizedBox(height: 3),
                            pw.Text((labels[e.key] ?? e.key).toString().toUpperCase(), style: pw.TextStyle(fontSize: 8, color: _grey)),
                          ],
                        ),
                      ),
                  ],
                ),
              pw.Spacer(),
              pw.Divider(color: _grey, thickness: 0.5),
              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Text('${BusinessInfo.nom} — Toutes les mesures sont en centimètres.', style: pw.TextStyle(fontSize: 9, color: _grey, fontStyle: pw.FontStyle.italic)),
              ),
            ],
          );
        },
      ),
    );
    return doc.save();
  }

  static Future<void> shareOrDownload(Uint8List bytes, String filename) async {
    await Printing.sharePdf(bytes: bytes, filename: filename);
  }

  /// Ouvre le sélecteur d'impression natif du téléphone.
  static Future<void> printDocument(Uint8List bytes) async {
    await Printing.layoutPdf(onLayout: (format) async => bytes);
  }
}
