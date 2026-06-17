class LaporanPembayaran {
  final String pembayaranId;
  final DateTime? waktuBayar;
  final double jumlahBayar;
  final String metodePembayaran;
  final String statusPembayaran;
  final int periodeBulan;
  final int periodeTahun;
  final String namaPelanggan;
  final String tipePelanggan;

  LaporanPembayaran({
    required this.pembayaranId,
    this.waktuBayar,
    required this.jumlahBayar,
    required this.metodePembayaran,
    required this.statusPembayaran,
    required this.periodeBulan,
    required this.periodeTahun,
    required this.namaPelanggan,
    required this.tipePelanggan,
  });

  factory LaporanPembayaran.fromJson(Map<String, dynamic> json) {
    return LaporanPembayaran(
      pembayaranId: json['pembayaran_id']?.toString() ?? '',
      waktuBayar: json['waktu_bayar'] != null
          ? DateTime.tryParse(json['waktu_bayar'].toString())
          : null,
      jumlahBayar: double.tryParse(json['jumlah_bayar']?.toString() ?? '') ?? 0.0,
      metodePembayaran: json['metode_pembayaran']?.toString() ?? '',
      statusPembayaran: json['status_pembayaran']?.toString() ?? '',
      periodeBulan: int.tryParse(json['periode_bulan']?.toString() ?? '') ?? 0,
      periodeTahun: int.tryParse(json['periode_tahun']?.toString() ?? '') ?? 0,
      namaPelanggan: json['nama_pelanggan']?.toString() ?? '',
      tipePelanggan: json['tipe_pelanggan']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pembayaran_id': pembayaranId,
      'waktu_bayar': waktuBayar?.toIso8601String(),
      'jumlah_bayar': jumlahBayar,
      'metode_pembayaran': metodePembayaran,
      'status_pembayaran': statusPembayaran,
      'periode_bulan': periodeBulan,
      'periode_tahun': periodeTahun,
      'nama_pelanggan': namaPelanggan,
      'tipe_pelanggan': tipePelanggan,
    };
  }
}
