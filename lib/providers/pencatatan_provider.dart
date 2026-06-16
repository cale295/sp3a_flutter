import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/pencatatan_meteran_model.dart';

class PencatatanService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<PencatatanMeteranModel>> getReadingsForCustomer(String pelangganId) async {
    final response = await _client
        .from('pencatatan_meteran')
        .select()
        .eq('pelanggan_id', pelangganId)
        .order('periode_tahun', ascending: false)
        .order('periode_bulan', ascending: false);
    return (response as List).map((json) => PencatatanMeteranModel.fromJson(json)).toList();
  }

  Future<List<PencatatanMeteranModel>> getAllReadings() async {
    final response = await _client
        .from('pencatatan_meteran')
        .select()
        .order('periode_tahun', ascending: false)
        .order('periode_bulan', ascending: false);
    return (response as List).map((json) => PencatatanMeteranModel.fromJson(json)).toList();
  }

  /// Uploads an image to Supabase Storage and returns the public path.
  Future<String> uploadMeterPhoto(String fileName, dynamic fileData) async {
    try {
      final storageBucket = _client.storage.from('meteran');
      
      if (kIsWeb) {
        // fileData is Uint8List on Web
        final Uint8List bytes = fileData as Uint8List;
        await storageBucket.uploadBinary(
          fileName,
          bytes,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
        );
      } else {
        // fileData is File on Mobile
        final File file = fileData as File;
        await storageBucket.upload(
          fileName,
          file,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
        );
      }

      // Return the storage path
      return fileName;
    } catch (e) {
      throw Exception('Failed to upload image to Supabase Storage: $e');
    }
  }

  /// Inserts a new meter reading log and returns the model.
  Future<PencatatanMeteranModel> createReading({
    required String pelangganId,
    required String dicatatOleh,
    required int periodeBulan,
    required int periodeTahun,
    required int angkaMeteran,
    required String fotoBuktiPath,
  }) async {
    final response = await _client.from('pencatatan_meteran').insert({
      'pelanggan_id': pelangganId,
      'dicatat_oleh': dicatatOleh,
      'periode_bulan': periodeBulan,
      'periode_tahun': periodeTahun,
      'angka_meteran': angkaMeteran,
      'foto_bukti': fotoBuktiPath,
    }).select().single();

    return PencatatanMeteranModel.fromJson(response);
  }
}

final pencatatanServiceProvider = Provider<PencatatanService>((ref) {
  return PencatatanService();
});

final customerReadingsProvider = FutureProvider.family.autoDispose<List<PencatatanMeteranModel>, String>((ref, pelangganId) async {
  return ref.watch(pencatatanServiceProvider).getReadingsForCustomer(pelangganId);
});

final allReadingsProvider = FutureProvider.autoDispose<List<PencatatanMeteranModel>>((ref) async {
  return ref.watch(pencatatanServiceProvider).getAllReadings();
});
