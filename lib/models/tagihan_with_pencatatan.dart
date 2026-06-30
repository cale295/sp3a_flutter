import 'package:supabase_flutter/supabase_flutter.dart';
import 'tagihan_model.dart';

class TagihanWithPencatatan {
  final TagihanModel tagihan;
  final int periodeBulan;
  final int periodeTahun;

  TagihanWithPencatatan({
    required this.tagihan,
    required this.periodeBulan,
    required this.periodeTahun,
  });

  factory TagihanWithPencatatan.fromJson(Map<String, dynamic> json) {
    final pencatatanMap = json['pencatatan_meteran'] as Map<String, dynamic>? ?? {};
    final rawFotoBukti = pencatatanMap['foto_bukti'] as String?;

    String? fotoBuktiUrl;
    if (rawFotoBukti != null && rawFotoBukti.isNotEmpty) {
      if (!rawFotoBukti.startsWith('http://') && !rawFotoBukti.startsWith('https://')) {
        fotoBuktiUrl = Supabase.instance.client.storage.from('meteran').getPublicUrl(rawFotoBukti);
      } else {
        fotoBuktiUrl = rawFotoBukti;
      }
    }

    final tagihan = TagihanModel.fromJson(json).copyWith(fotoBukti: fotoBuktiUrl);
    final periodeBulan = pencatatanMap['periode_bulan'] as int? ?? 0;
    final periodeTahun = pencatatanMap['periode_tahun'] as int? ?? 0;

    return TagihanWithPencatatan(
      tagihan: tagihan,
      periodeBulan: periodeBulan,
      periodeTahun: periodeTahun,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      ...tagihan.toJson(),
      'pencatatan_meteran': {
        'periode_bulan': periodeBulan,
        'periode_tahun': periodeTahun,
      },
    };
  }
}
