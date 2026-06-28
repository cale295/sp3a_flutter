import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../models/pencatatan_meteran_model.dart';
import '../models/user_model.dart';
import 'database_provider.dart';

class MeteranService {
  final SupabaseClient _client = Supabase.instance.client;

  // ── READ ─────────────────────────────────────────────────────────────────

  Future<List<PencatatanMeteranModel>> getReadingsForCustomer(
      String pelangganId) async {
    final response = await _client
        .from('pencatatan_meteran')
        .select()
        .eq('pelanggan_id', pelangganId)
        .order('periode_tahun', ascending: false)
        .order('periode_bulan', ascending: false);
    return (response as List)
        .map((json) => PencatatanMeteranModel.fromJson(json))
        .toList();
  }

  Future<List<PencatatanMeteranModel>> getAllReadings() async {
    final response = await _client
        .from('pencatatan_meteran')
        .select()
        .order('periode_tahun', ascending: false)
        .order('periode_bulan', ascending: false);
    return (response as List)
        .map((json) => PencatatanMeteranModel.fromJson(json))
        .toList();
  }

  Future<List<PencatatanMeteranModel>> getReadingsForPeriod(
      int month, int year) async {
    final response = await _client
        .from('pencatatan_meteran')
        .select()
        .eq('periode_bulan', month)
        .eq('periode_tahun', year);
    return (response as List)
        .map((json) => PencatatanMeteranModel.fromJson(json))
        .toList();
  }

  // ── WRITE (Petugas only) ─────────────────────────────────────────────────

  /// Inserts a meter reading AND immediately generates the tagihan row.
  ///
  /// Flow:
  ///   1. Upload the image to Supabase Storage bucket 'meteran'.
  ///   2. Insert into `pencatatan_meteran`.
  ///   3. Fetch the most recent PREVIOUS reading for this customer to compute pemakaian_m3.
  ///   4. Fetch the applicable tarif for the customer's tipe_pelanggan.
  ///   5. Insert a new row into `tagihan`.
  Future<void> petugasInputMeter({
    required String pelangganId,
    required String dicatatOlehId,
    required int periodeBulan,
    required int periodeTahun,
    required int angkaMeter,
    required XFile imageFile,
  }) async {
    // ── 1. Upload photo to Supabase storage bucket 'meteran' ──────────────
    final bytes = await imageFile.readAsBytes();
    final fileExtension = imageFile.name.split('.').last;
    final path = 'meteran_${pelangganId}_${periodeTahun}_${periodeBulan}_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';

    await _client.storage.from('meteran').uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(
            cacheControl: '3600',
            upsert: true,
          ),
        );
    final publicUrl = _client.storage.from('meteran').getPublicUrl(path);

    // ── 2. Insert the meter reading ──────────────────────────────────────
    final newReadingResponse = await _client
        .from('pencatatan_meteran')
        .insert({
          'pelanggan_id': pelangganId,
          'dicatat_oleh': dicatatOlehId,
          'periode_bulan': periodeBulan,
          'periode_tahun': periodeTahun,
          'angka_meteran': angkaMeter,
          'foto_bukti': publicUrl,
        })
        .select()
        .single();

    final newReading = PencatatanMeteranModel.fromJson(newReadingResponse);

    // ── 2. Fetch previous reading (any period before current) ────────────
    // We order by year desc, then month desc, and skip the first result
    // (which is the one we just inserted) by filtering period < current.
    final prevResponse = await _client
        .from('pencatatan_meteran')
        .select()
        .eq('pelanggan_id', pelangganId)
        .or('periode_tahun.lt.$periodeTahun,and(periode_tahun.eq.$periodeTahun,periode_bulan.lt.$periodeBulan)')
        .order('periode_tahun', ascending: false)
        .order('periode_bulan', ascending: false)
        .limit(1);

    int pemakaianM3;
    if ((prevResponse as List).isNotEmpty) {
      final prevReading = PencatatanMeteranModel.fromJson(prevResponse.first);
      pemakaianM3 = angkaMeter - prevReading.angkaMeteran;
      if (pemakaianM3 < 0) pemakaianM3 = 0; // Sanity guard
    } else {
      // First-ever reading for this customer — treat full reading as usage
      pemakaianM3 = angkaMeter;
    }

    // ── 3. Fetch tarif for this customer ─────────────────────────────────
    final userResponse = await _client
        .from('users')
        .select('tipe_pelanggan')
        .eq('id', pelangganId)
        .single();
    final tipePelangganStr = userResponse['tipe_pelanggan'] as String?;
    final tipePelanggan = TipePelanggan.fromString(tipePelangganStr);

    final tarifResponse = await _client
        .from('tarif')
        .select('harga_per_m3, biaya_abodemen')
        .eq('tipe_pelanggan', tipePelanggan.dbValue)
        .single();

    final hargaPerM3 = (tarifResponse['harga_per_m3'] as num).toDouble();
    final biayaAbodemen = (tarifResponse['biaya_abodemen'] as num).toDouble();

    // ── 4. Calculate total tagihan ────────────────────────────────────────
    // If pemakaian = 0, customer pays abodemen only; otherwise water charge applies.
    final totalTagihan =
        pemakaianM3 == 0 ? biayaAbodemen : (pemakaianM3 * hargaPerM3);

    // ── 5. Insert tagihan row ─────────────────────────────────────────────
    await _client.from('tagihan').insert({
      'pelanggan_id': pelangganId,
      'pencatatan_id': newReading.id,
      'pemakaian_m3': pemakaianM3,
      'total_tagihan': totalTagihan,
      'status_tagihan': 'belum_dibayar',
      'total_denda': 0.0,
    });
  }
}

// ── Providers ────────────────────────────────────────────────────────────────

final meteranServiceProvider = Provider<MeteranService>((ref) {
  return MeteranService();
});

/// Alias kept for backward compatibility with existing provider references.
final pencatatanServiceProvider = meteranServiceProvider;

final customerReadingsProvider =
    FutureProvider.family.autoDispose<List<PencatatanMeteranModel>, String>(
        (ref, pelangganId) async {
  return ref.watch(meteranServiceProvider).getReadingsForCustomer(pelangganId);
});

final allReadingsProvider =
    FutureProvider.autoDispose<List<PencatatanMeteranModel>>((ref) async {
  return ref.watch(meteranServiceProvider).getAllReadings();
});

// ── Status Model (Petugas List) ───────────────────────────────────────────────

class PelangganStatusModel {
  final UserModel pelanggan;

  /// The current-month reading recorded by a Petugas, if it exists.
  final PencatatanMeteranModel? reading;

  PelangganStatusModel({
    required this.pelanggan,
    this.reading,
  });

  /// True when a Petugas has already recorded this customer's meter for the
  /// current month. Replaces the old `hasInputMandiri` (customer self-input).
  bool get hasPetugasReading => reading != null;
}

final readingsForCurrentPeriodProvider =
    FutureProvider.autoDispose<List<PencatatanMeteranModel>>((ref) async {
  final now = DateTime.now();
  return ref
      .watch(meteranServiceProvider)
      .getReadingsForPeriod(now.month, now.year);
});

final pelangganWithStatusProvider =
    FutureProvider.autoDispose<List<PelangganStatusModel>>((ref) async {
  final pelangganList = await ref.watch(pelangganListProvider.future);
  final readings = await ref.watch(readingsForCurrentPeriodProvider.future);

  final readingsMap = {for (var r in readings) r.pelangganId: r};

  return pelangganList.map((pelanggan) {
    return PelangganStatusModel(
      pelanggan: pelanggan,
      reading: readingsMap[pelanggan.id],
    );
  }).toList();
});
