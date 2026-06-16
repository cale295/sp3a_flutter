enum StatusTagihan {
  belumDibayar,
  lunas;

  String get dbValue {
    switch (this) {
      case StatusTagihan.belumDibayar:
        return 'belum_dibayar';
      case StatusTagihan.lunas:
        return 'lunas';
    }
  }

  static StatusTagihan fromString(String value) {
    if (value == 'belum_dibayar' || value == 'belum_bayar') return StatusTagihan.belumDibayar;
    if (value == 'lunas') return StatusTagihan.lunas;
    return StatusTagihan.belumDibayar;
  }
}

class TagihanModel {
  final int id;
  final String pelangganId;
  final int pencatatanId;
  final int pemakaianM3;
  final double totalTagihan;
  final StatusTagihan statusTagihan;
  final double totalDenda;
  final int jumlahBulanTunggakan;

  TagihanModel({
    required this.id,
    required this.pelangganId,
    required this.pencatatanId,
    required this.pemakaianM3,
    required this.totalTagihan,
    required this.statusTagihan,
    this.totalDenda = 0.0,
    this.jumlahBulanTunggakan = 0,
  });

  factory TagihanModel.fromJson(Map<String, dynamic> json) {
    return TagihanModel(
      id: json['id'] as int,
      pelangganId: json['pelanggan_id'] as String,
      pencatatanId: json['pencatatan_id'] as int,
      pemakaianM3: json['pemakaian_m3'] as int,
      totalTagihan: (json['total_tagihan'] as num).toDouble(),
      statusTagihan: StatusTagihan.fromString(json['status_tagihan'] as String? ?? 'belum_dibayar'),
      totalDenda: (json['total_denda'] as num?)?.toDouble() ?? 0.0,
      jumlahBulanTunggakan: json['jumlah_bulan_tunggakan'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != 0) 'id': id,
      'pelanggan_id': pelangganId,
      'pencatatan_id': pencatatanId,
      'pemakaian_m3': pemakaianM3,
      'total_tagihan': totalTagihan,
      'status_tagihan': statusTagihan.dbValue,
      'total_denda': totalDenda,
    };
  }

  TagihanModel copyWith({
    int? id,
    String? pelangganId,
    int? pencatatanId,
    int? pemakaianM3,
    double? totalTagihan,
    StatusTagihan? statusTagihan,
    double? totalDenda,
    int? jumlahBulanTunggakan,
  }) {
    return TagihanModel(
      id: id ?? this.id,
      pelangganId: pelangganId ?? this.pelangganId,
      pencatatanId: pencatatanId ?? this.pencatatanId,
      pemakaianM3: pemakaianM3 ?? this.pemakaianM3,
      totalTagihan: totalTagihan ?? this.totalTagihan,
      statusTagihan: statusTagihan ?? this.statusTagihan,
      totalDenda: totalDenda ?? this.totalDenda,
      jumlahBulanTunggakan: jumlahBulanTunggakan ?? this.jumlahBulanTunggakan,
    );
  }
}
