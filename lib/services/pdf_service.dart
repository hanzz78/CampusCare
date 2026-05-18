import 'dart:typed_data';
import 'package:flutter/material.dart' show debugPrint;
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/tiket_model.dart';

class PdfService {
  static const _teal    = PdfColor.fromInt(0xFF2A5256);
  static const _gold    = PdfColor.fromInt(0xFFE09F3E);
  static const _red     = PdfColor.fromInt(0xFF9E2A2B);
  static const _grey    = PdfColor.fromInt(0xFF7A9BA0);
  static const _dark    = PdfColor.fromInt(0xFF0F2B33);
  static const _green   = PdfColor.fromInt(0xFF2E7D32);
  static const _greenBg = PdfColor.fromInt(0xFFE8F5E9);
  static const _tealBg  = PdfColor.fromInt(0xFFEBF0F0);
  static const _border  = PdfColor.fromInt(0xFFDDE3E5);

  static Future<Uint8List> generateReportPdf(
    TiketModel report, {
    String? approvedBy,
    String? statusOverride,   // 'Approved' | 'Rejected'
    String? pjNoteOverride,   // catatan yang baru diketik
    String? urgencyOverride,  // urgensi yang dipilih
    DateTime? approvalDateOverride,
  }) async {
    final pdf = pw.Document();

    final effectiveStatus   = statusOverride   ?? report.status;
    final effectivePjNote   = pjNoteOverride   ?? report.catatanPJ ?? '';
    final effectiveUrgency  = urgencyOverride  ?? report.tingkatUrgensi ?? 'Prioritas Rendah';
    final effectiveApproval = approvalDateOverride ?? report.tanggalApproval ?? DateTime.now();
    final isApproved        = effectiveStatus == 'Approved';

    // ── Load foto (max 3 gambar) ──
    final List<pw.MemoryImage> photos = [];
    for (final url in report.buktiVisual.take(3)) {
      if (url == 'placeholder.jpg' || url.isEmpty) continue;
      try {
        final resp = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 7));
        if (resp.statusCode == 200) photos.add(pw.MemoryImage(resp.bodyBytes));
      } catch (e) {
        debugPrint('PDF foto skip: $e');
      }
    }

    final now          = DateTime.now();
    final dateStr      = DateFormat('d MMM yyyy').format(now);
    final timeStr      = DateFormat('HH:mm').format(now);
    final submittedStr = DateFormat('HH:mm · d MMM yyyy').format(report.tanggalPengajuan);
    final approvalStr  = DateFormat('d MMM yyyy · HH:mm').format(effectiveApproval);

    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(36, 32, 36, 28),
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // ── HEADER ──
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.RichText(text: pw.TextSpan(children: [
                  pw.TextSpan(text: 'Campus', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: _red)),
                  pw.TextSpan(text: 'Care',   style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: _gold)),
                ])),
                pw.Text('Campus Issue Report', style: const pw.TextStyle(fontSize: 8, color: _grey)),
              ]),
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                pw.Text('Doc No: ${report.idTiket}',
                    style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _dark)),
                pw.SizedBox(height: 2),
                pw.Text('Generated: $dateStr $timeStr',
                    style: const pw.TextStyle(fontSize: 8, color: _grey)),
              ]),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Divider(color: _border, thickness: 0.8),
          pw.SizedBox(height: 10),

          // ── JUDUL ──
          pw.Text(report.judulSingkat,
              style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold, color: _dark)),
          pw.SizedBox(height: 10),

          // ── INFO TABLE (2 kolom kiri-kanan) ──
          pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              _infoRow('KATEGORI', report.kategori.utama),
              pw.SizedBox(height: 5),
              _infoRow('LOKASI', report.lokasiDisplay),
              pw.SizedBox(height: 5),
              _infoRow('DIKIRIM', submittedStr),
            ])),
            pw.SizedBox(width: 20),
            pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              _infoRow('PELAPOR', 'Anonim'),
              pw.SizedBox(height: 5),
              _infoRow('DUKUNGAN', '${report.jumlahVote} orang'),
              pw.SizedBox(height: 5),
              pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
                pw.Text('STATUS', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: _grey, letterSpacing: 0.8)),
                pw.SizedBox(width: 10),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: pw.BoxDecoration(
                    color: isApproved ? _greenBg : const PdfColor.fromInt(0xFFFFEBEE),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
                  ),
                  child: pw.Text(
                    isApproved ? 'Approved' : 'Rejected',
                    style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold,
                        color: isApproved ? _green : _red),
                  ),
                ),
              ]),
            ])),
          ]),
          pw.SizedBox(height: 10),
          pw.Divider(color: _border, thickness: 0.5),
          pw.SizedBox(height: 8),

          // ── DESKRIPSI ──
          _label('DESKRIPSI LAPORAN'),
          pw.SizedBox(height: 4),
          pw.Text(report.deskripsiTiket,
              style: const pw.TextStyle(fontSize: 10, color: _dark, lineSpacing: 2),
              maxLines: 6),
          pw.SizedBox(height: 8),

          // ── FOTO (jika ada, compact row) ──
          if (photos.isNotEmpty) ...[
            pw.Divider(color: _border, thickness: 0.5),
            pw.SizedBox(height: 6),
            _label('FOTO BUKTI'),
            pw.SizedBox(height: 6),
            pw.Row(children: photos.map((img) => pw.Padding(
              padding: const pw.EdgeInsets.only(right: 8),
              child: pw.ClipRRect(
                horizontalRadius: 4, verticalRadius: 4,
                child: pw.Image(img, width: 130, height: 85, fit: pw.BoxFit.cover),
              ),
            )).toList()),
            pw.SizedBox(height: 8),
          ],

          pw.Divider(color: _border, thickness: 0.5),
          pw.SizedBox(height: 8),

          // ── CATATAN PJ ──
          _label('CATATAN PJ'),
          pw.SizedBox(height: 4),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: _tealBg,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              border: pw.Border.all(color: _border, width: 0.5),
            ),
            child: pw.Text(
              effectivePjNote.isNotEmpty ? effectivePjNote : 'Tidak ada catatan tambahan.',
              style: const pw.TextStyle(fontSize: 10, color: _dark, lineSpacing: 2),
              maxLines: 4,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Divider(color: _border, thickness: 0.5),
          pw.SizedBox(height: 8),

          // ── APPROVED BY + URGENCY + STAMP ── (satu baris)
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                _label('DISETUJUI OLEH'),
                pw.SizedBox(height: 3),
                pw.Text(approvedBy ?? 'Penanggung Jawab',
                    style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: _dark)),
              ])),
              pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                _label('TINGKAT URGENSI'),
                pw.SizedBox(height: 3),
                _urgencyBadge(effectiveUrgency),
              ])),
              // Stamp
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: isApproved ? _teal : _red, width: 2),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
                  pw.Text(
                    isApproved ? 'DISETUJUI' : 'DITOLAK',
                    style: pw.TextStyle(
                      fontSize: 13, fontWeight: pw.FontWeight.bold,
                      color: isApproved ? _teal : _red, letterSpacing: 1.5,
                    ),
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text(approvalStr,
                      style: const pw.TextStyle(fontSize: 8, color: _grey)),
                ]),
              ),
            ],
          ),

          pw.Spacer(),

          // ── FOOTER ──
          pw.Divider(color: _border, thickness: 0.5),
          pw.SizedBox(height: 4),
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Text('CampusCare — Layanan Pelaporan Terpadu Polban',
                style: const pw.TextStyle(fontSize: 7, color: _grey)),
            pw.Text('Digenerate otomatis oleh sistem',
                style: const pw.TextStyle(fontSize: 7, color: _grey)),
          ]),
        ],
      ),
    ));

    return pdf.save();
  }

  static pw.Widget _infoRow(String label, String value) => pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.SizedBox(
        width: 70,
        child: pw.Text(label,
            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: _grey, letterSpacing: 0.8)),
      ),
      pw.Expanded(
        child: pw.Text(value,
            style: const pw.TextStyle(fontSize: 9, color: _dark), maxLines: 2),
      ),
    ],
  );

  static pw.Widget _urgencyBadge(String level) {
    PdfColor color;
    if (level.contains('Tinggi'))       color = _red;
    else if (level.contains('Sedang'))  color = _gold;
    else                                color = _teal;
    final label = level.replaceAll('Prioritas ', '');
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: color, width: 1),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
      ),
      child: pw.Text(label,
          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: color)),
    );
  }

  static pw.Widget _label(String text) => pw.Text(
    text,
    style: pw.TextStyle(
      fontSize: 8, fontWeight: pw.FontWeight.bold, color: _grey, letterSpacing: 1.0),
  );
}
