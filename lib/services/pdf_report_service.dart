import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/laporan_pembayaran_model.dart';

class PdfReportService {
  static Future<void> generateAndDownloadYearlyReport(List<LaporanPembayaran> reports, int year) async {
    final pdf = pw.Document();
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    // Calculate totals
    double totalIncome = 0;
    int totalSuccess = 0;
    for (var r in reports) {
      if (r.statusPembayaran.toLowerCase() == 'sukses') {
        totalIncome += r.jumlahBayar;
        totalSuccess++;
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildHeader(year),
        build: (context) => [
          pw.SizedBox(height: 20),
          _buildSummary(totalIncome, totalSuccess, formatter),
          pw.SizedBox(height: 20),
          _buildTable(reports, formatter),
        ],
        footer: (context) => _buildFooter(context),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Laporan_Tahunan_$year.pdf',
    );
  }

  static pw.Widget _buildHeader(int year) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('LAPORAN TAHUNAN PEMBAYARAN', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        pw.Text('Tahun: $year', style: const pw.TextStyle(fontSize: 12)),
        pw.SizedBox(height: 10),
        pw.Divider(),
      ],
    );
  }

  static pw.Widget _buildSummary(double totalIncome, int totalSuccess, NumberFormat formatter) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Total Pendapatan (Sukses)', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
              pw.Text(formatter.format(totalIncome), style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Total Transaksi Sukses', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
              pw.Text('$totalSuccess', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTable(List<LaporanPembayaran> reports, NumberFormat formatter) {
    final headers = ['Tanggal', 'Pelanggan', 'Tipe', 'Bln/Thn', 'Metode', 'Status', 'Jumlah'];

    final data = reports.map((r) {
      final dateStr = r.waktuBayar != null
          ? DateFormat('dd MMM yyyy').format(r.waktuBayar!)
          : '-';
      return [
        dateStr,
        r.namaPelanggan.isNotEmpty ? r.namaPelanggan : '-',
        r.tipePelanggan,
        '${r.periodeBulan}/${r.periodeTahun}',
        r.metodePembayaran,
        r.statusPembayaran,
        formatter.format(r.jumlahBayar),
      ];
    }).toList();

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: data,
      border: pw.TableBorder.all(color: PdfColors.grey300),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
      cellStyle: const pw.TextStyle(fontSize: 9),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
      cellHeight: 25,
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.centerLeft,
        3: pw.Alignment.center,
        4: pw.Alignment.centerLeft,
        5: pw.Alignment.center,
        6: pw.Alignment.centerRight,
      },
    );
  }

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 20),
      child: pw.Text(
        'Halaman ${context.pageNumber} dari ${context.pagesCount}',
        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
      ),
    );
  }
}
