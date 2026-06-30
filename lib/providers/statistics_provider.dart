import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MonthlyStat {
  final String monthLabel;
  final int month;
  final int year;
  final double rumahTanggaPemakaian;
  final double bisnisPemakaian;
  final double rumahTanggaPendapatan;
  final double bisnisPendapatan;

  MonthlyStat({
    required this.monthLabel,
    required this.month,
    required this.year,
    required this.rumahTanggaPemakaian,
    required this.bisnisPemakaian,
    required this.rumahTanggaPendapatan,
    required this.bisnisPendapatan,
  });
}

final statisticsProvider = FutureProvider.autoDispose<List<MonthlyStat>>((ref) async {
  final client = Supabase.instance.client;

  // Query tagihan joined with pencatatan_meteran and users
  final response = await client
      .from('tagihan')
      .select('*, pencatatan_meteran!inner(*), users!inner(*)');

  final tagihanList = response as List;

  // Calculate the last 6 months dynamically (including current month)
  final List<DateTime> months = [];
  final now = DateTime.now();
  for (int i = 5; i >= 0; i--) {
    months.add(DateTime(now.year, now.month - i, 1));
  }

  final List<String> listBulanSingkat = [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
  ];

  return months.map((m) {
    final monthLabel = "${listBulanSingkat[m.month]} ${m.year.toString().substring(2)}";

    double rtPemakaian = 0;
    double bisnisPemakaian = 0;
    double rtPendapatan = 0;
    double bisnisPendapatan = 0;

    for (var row in tagihanList) {
      final pencatatan = row['pencatatan_meteran'] as Map<String, dynamic>?;
      final user = row['users'] as Map<String, dynamic>?;

      if (pencatatan != null && user != null) {
        final pBulan = pencatatan['periode_bulan'] as int? ?? 0;
        final pTahun = pencatatan['periode_tahun'] as int? ?? 0;

        if (pBulan == m.month && pTahun == m.year) {
          final pemakaian = (row['pemakaian_m3'] as num? ?? 0).toDouble();
          final totalTagihan = (row['total_tagihan'] as num? ?? 0.0).toDouble();
          final status = row['status_tagihan'] as String? ?? '';
          final tipe = user['tipe_pelanggan'] as String? ?? 'rumah_tangga';

          if (tipe == 'rumah_tangga') {
            rtPemakaian += pemakaian;
            if (status == 'lunas') {
              rtPendapatan += totalTagihan;
            }
          } else if (tipe == 'bisnis') {
            bisnisPemakaian += pemakaian;
            if (status == 'lunas') {
              bisnisPendapatan += totalTagihan;
            }
          }
        }
      }
    }

    return MonthlyStat(
      monthLabel: monthLabel,
      month: m.month,
      year: m.year,
      rumahTanggaPemakaian: rtPemakaian,
      bisnisPemakaian: bisnisPemakaian,
      rumahTanggaPendapatan: rtPendapatan,
      bisnisPendapatan: bisnisPendapatan,
    );
  }).toList();
});
