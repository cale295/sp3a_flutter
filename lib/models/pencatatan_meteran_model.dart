class PencatatanMeteranModel {
  final int id;
  final String pelangganId;
  final String dicatatOleh;
  final int periodeBulan;
  final int periodeTahun;
  final int angkaMeteran;
  final String fotoBukti;

  PencatatanMeteranModel({
    required this.id,
    required this.pelangganId,
    required this.dicatatOleh,
    required this.periodeBulan,
    required this.periodeTahun,
    required this.angkaMeteran,
    required this.fotoBukti,
  });

  factory PencatatanMeteranModel.fromJson(Map<String, dynamic> json) {
    return PencatatanMeteranModel(
      id: json['id'] as int,
      pelangganId: json['pelanggan_id'] as String,
      dicatatOleh: json['dicatat_oleh'] as String,
      periodeBulan: json['periode_bulan'] as int,
      periodeTahun: json['periode_tahun'] as int,
      angkaMeteran: json['angka_meteran'] as int,
      fotoBukti: json['foto_bukti'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != 0) 'id': id,
      'pelanggan_id': pelangganId,
      'dicatat_oleh': dicatatOleh,
      'periode_bulan': periodeBulan,
      'periode_tahun': periodeTahun,
      'angka_meteran': angkaMeteran,
      'foto_bukti': fotoBukti,
    };
  }

  PencatatanMeteranModel copyWith({
    int? id,
    String? pelangganId,
    String? dicatatOleh,
    int? periodeBulan,
    int? periodeTahun,
    int? angkaMeteran,
    String? fotoBukti,
  }) {
    return PencatatanMeteranModel(
      id: id ?? this.id,
      pelangganId: pelangganId ?? this.pelangganId,
      dicatatOleh: dicatatOleh ?? this.dicatatOleh,
      periodeBulan: periodeBulan ?? this.periodeBulan,
      periodeTahun: periodeTahun ?? this.periodeTahun,
      angkaMeteran: angkaMeteran ?? this.angkaMeteran,
      fotoBukti: fotoBukti ?? this.fotoBukti,
    );
  }
}
