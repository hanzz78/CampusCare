import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'dart:typed_data';
import '../models/tiket_model.dart';

class PdfService {
  static Future<Uint8List> generateReportPdf(TiketModel report) async {
    final pdf = pw.Document();

    final dateStr = DateFormat('dd MMM yyyy, HH:mm').format(report.createdAt);
    final approvalDateStr = report.tanggalApproval != null 
        ? DateFormat('dd MMM yyyy, HH:mm').format(report.tanggalApproval!) 
        : '-';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            _buildHeader(),
            pw.SizedBox(height: 20),
            _buildTitle(),
            pw.SizedBox(height: 20),
            _buildInfoTable(report, dateStr, approvalDateStr),
            pw.SizedBox(height: 20),
            _buildSectionTitle('Deskripsi Laporan'),
            pw.Paragraph(text: report.deskripsiTiket),
            pw.SizedBox(height: 20),
            if (report.catatanPJ != null && report.catatanPJ!.isNotEmpty) ...[
              _buildSectionTitle('Catatan Penanggung Jawab'),
              pw.Paragraph(text: report.catatanPJ!),
            ],
            pw.SizedBox(height: 40),
            _buildFooter(),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text('CAMPUSCARE', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.teal800)),
        pw.Text('Sistem Layanan Laporan Kerusakan & Kebersihan', style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
        pw.Divider(thickness: 2),
      ],
    );
  }

  static pw.Widget _buildTitle() {
    return pw.Center(
      child: pw.Text(
        'DOKUMEN HASIL REVIEW LAPORAN',
        style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, decoration: pw.TextDecoration.underline),
      ),
    );
  }

  static pw.Widget _buildInfoTable(TiketModel report, String dateStr, String approvalDateStr) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      columnWidths: {
        0: const pw.FlexColumnWidth(1),
        1: const pw.FlexColumnWidth(2),
      },
      children: [
        _buildTableRow('ID Laporan', report.idTiket.toUpperCase()),
        _buildTableRow('Tanggal Dilaporkan', dateStr),
        _buildTableRow('Tanggal Disetujui', approvalDateStr),
        _buildTableRow('Kategori', report.kategori.utama),
        _buildTableRow('Lokasi', report.lokasiDisplay),
        _buildTableRow('Status', report.status),
        _buildTableRow('Tingkat Urgensi', report.tingkatUrgensi ?? '-'),
        _buildTableRow('Jumlah Dukungan', '${report.jumlahVote} Mahasiswa'),
      ],
    );
  }

  static pw.TableRow _buildTableRow(String label, String value) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(value),
        ),
      ],
    );
  }

  static pw.Widget _buildSectionTitle(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 8),
      margin: const pw.EdgeInsets.only(bottom: 8),
      decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey400))),
      child: pw.Text(title, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
    );
  }

  static pw.Widget _buildFooter() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text('Divalidasi Oleh,'),
            pw.SizedBox(height: 50),
            pw.Text('Penanggung Jawab', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          ],
        ),
      ],
    );
  }
}
