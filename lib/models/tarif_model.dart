import 'user_model.dart';

class TarifModel {
  final int id;
  final TipePelanggan tipePelanggan;
  final double hargaPerM3;
  final double biayaAbodemen;
  final double dendaPerBulan;

  TarifModel({
    required this.id,
    required this.tipePelanggan,
    required this.hargaPerM3,
    required this.biayaAbodemen,
    required this.dendaPerBulan,
  });

  factory TarifModel.fromJson(Map<String, dynamic> json) {
    return TarifModel(
      id: json['id'] as int,
      tipePelanggan: TipePelanggan.fromString(json['tipe_pelanggan'] as String?),
      hargaPerM3: (json['harga_per_m3'] as num).toDouble(),
      biayaAbodemen: (json['biaya_abodemen'] as num).toDouble(),
      dendaPerBulan: (json['denda_per_bulan'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tipe_pelanggan': tipePelanggan.dbValue,
      'harga_per_m3': hargaPerM3,
      'biaya_abodemen': biayaAbodemen,
      'denda_per_bulan': dendaPerBulan,
    };
  }

  TarifModel copyWith({
    int? id,
    TipePelanggan? tipePelanggan,
    double? hargaPerM3,
    double? biayaAbodemen,
    double? dendaPerBulan,
  }) {
    return TarifModel(
      id: id ?? this.id,
      tipePelanggan: tipePelanggan ?? this.tipePelanggan,
      hargaPerM3: hargaPerM3 ?? this.hargaPerM3,
      biayaAbodemen: biayaAbodemen ?? this.biayaAbodemen,
      dendaPerBulan: dendaPerBulan ?? this.dendaPerBulan,
    );
  }
}
