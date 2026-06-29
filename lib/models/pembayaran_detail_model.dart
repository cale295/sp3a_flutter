import 'pembayaran_model.dart';
import 'tagihan_model.dart';

class PembayaranDetailModel {
  final String id;
  final int tagihanId;
  final String metodePembayaran;
  final double jumlahBayar;
  final StatusPembayaran statusPembayaran;
  final DateTime waktuBayar;
  final String? diterimaOleh;
  final TagihanModel tagihan;
  final int periodeBulan;
  final int periodeTahun;

  PembayaranDetailModel({
    required this.id,
    required this.tagihanId,
    required this.metodePembayaran,
    required this.jumlahBayar,
    required this.statusPembayaran,
    required this.waktuBayar,
    this.diterimaOleh,
    required this.tagihan,
    required this.periodeBulan,
    required this.periodeTahun,
  });

  factory PembayaranDetailModel.fromJson(Map<String, dynamic> json) {
    final tagihanMap = json['tagihan'] as Map<String, dynamic>;
    final pencatatanMap = tagihanMap['pencatatan_meteran'] as Map<String, dynamic>;

    return PembayaranDetailModel(
      id: json['id'] as String,
      tagihanId: json['tagihan_id'] as int,
      metodePembayaran: json['metode_pembayaran'] as String? ?? '',
      jumlahBayar: (json['jumlah_bayar'] as num).toDouble(),
      statusPembayaran: StatusPembayaran.fromString(json['status_pembayaran'] as String? ?? 'pending'),
      waktuBayar: DateTime.parse(json['waktu_bayar'] as String),
      diterimaOleh: json['diterima_oleh'] as String?,
      tagihan: TagihanModel.fromJson(tagihanMap),
      periodeBulan: pencatatanMap['periode_bulan'] as int? ?? 0,
      periodeTahun: pencatatanMap['periode_tahun'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tagihan_id': tagihanId,
      'metode_pembayaran': metodePembayaran,
      'jumlah_bayar': jumlahBayar,
      'status_pembayaran': statusPembayaran.dbValue,
      'waktu_bayar': waktuBayar.toIso8601String(),
      if (diterimaOleh != null) 'diterima_oleh': diterimaOleh,
      'tagihan': tagihan.toJson(),
      'pencatatan_meteran': {
        'periode_bulan': periodeBulan,
        'periode_tahun': periodeTahun,
      },
    };
  }
}
