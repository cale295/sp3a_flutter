enum StatusPembayaran {
  pending,
  sukses,
  gagal;

  String get dbValue {
    return name;
  }

  static StatusPembayaran fromString(String value) {
    return StatusPembayaran.values.firstWhere(
      (e) => e.name == value,
      orElse: () => StatusPembayaran.pending,
    );
  }
}

class PembayaranModel {
  final String id; // Order ID
  final int tagihanId;
  final String metodePembayaran;
  final double jumlahBayar;
  final StatusPembayaran statusPembayaran;
  final DateTime waktuBayar;
  final String? diterimaOleh; // UUID of officer who received payment (nullable)

  PembayaranModel({
    required this.id,
    required this.tagihanId,
    required this.metodePembayaran,
    required this.jumlahBayar,
    required this.statusPembayaran,
    required this.waktuBayar,
    this.diterimaOleh,
  });

  factory PembayaranModel.fromJson(Map<String, dynamic> json) {
    return PembayaranModel(
      id: json['id'] as String,
      tagihanId: json['tagihan_id'] as int,
      metodePembayaran: json['metode_pembayaran'] as String? ?? '',
      jumlahBayar: (json['jumlah_bayar'] as num).toDouble(),
      statusPembayaran: StatusPembayaran.fromString(json['status_pembayaran'] as String? ?? 'pending'),
      waktuBayar: DateTime.parse(json['waktu_bayar'] as String),
      diterimaOleh: json['diterima_oleh'] as String?,
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
    };
  }

  PembayaranModel copyWith({
    String? id,
    int? tagihanId,
    String? metodePembayaran,
    double? jumlahBayar,
    StatusPembayaran? statusPembayaran,
    DateTime? waktuBayar,
    String? diterimaOleh,
  }) {
    return PembayaranModel(
      id: id ?? this.id,
      tagihanId: tagihanId ?? this.tagihanId,
      metodePembayaran: metodePembayaran ?? this.metodePembayaran,
      jumlahBayar: jumlahBayar ?? this.jumlahBayar,
      statusPembayaran: statusPembayaran ?? this.statusPembayaran,
      waktuBayar: waktuBayar ?? this.waktuBayar,
      diterimaOleh: diterimaOleh ?? this.diterimaOleh,
    );
  }
}
