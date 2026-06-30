import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/tagihan_model.dart';
import '../models/pembayaran_model.dart';
import '../models/user_model.dart';
import '../models/pembayaran_detail_model.dart';
import '../models/tagihan_with_pencatatan.dart';

class TagihanService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<TagihanModel>> getTagihanForCustomer(String pelangganId) async {
    final response = await _client
        .from('tagihan')
        .select()
        .eq('pelanggan_id', pelangganId)
        .order('id', ascending: false);
    return (response as List).map((json) => TagihanModel.fromJson(json)).toList();
  }

  Future<TagihanModel?> getActiveTagihanForCustomer(String pelangganId) async {
    final response = await _client
      .from('tagihan')
      .select()
      .eq('pelanggan_id', pelangganId)
      .eq('status_tagihan', 'belum_dibayar')
      .order('id', ascending: false);

    final unpaidList = (response as List).map((json) => TagihanModel.fromJson(json)).toList();
    if (unpaidList.isEmpty) return null;

    final activeBill = unpaidList.first;
    final jumlahBulanTunggakan = unpaidList.length - 1;

    // Fetch foto_bukti from corresponding pencatatan_meteran entry
    String? fotoBuktiUrl;
    try {
      final pencatatanResponse = await _client
          .from('pencatatan_meteran')
          .select('foto_bukti')
          .eq('id', activeBill.pencatatanId)
          .single();
      final rawFotoBukti = pencatatanResponse['foto_bukti'] as String?;
      if (rawFotoBukti != null && rawFotoBukti.isNotEmpty) {
        if (!rawFotoBukti.startsWith('http://') && !rawFotoBukti.startsWith('https://')) {
          fotoBuktiUrl = _client.storage.from('meteran').getPublicUrl(rawFotoBukti);
        } else {
          fotoBuktiUrl = rawFotoBukti;
        }
      }
    } catch (_) {
      // Keep it null on error
    }

    try {
      final userResponse = await _client
          .from('users')
          .select('tipe_pelanggan')
          .eq('id', pelangganId)
          .single();
      final tipePelangganStr = userResponse['tipe_pelanggan'] as String?;
      final tipePelanggan = TipePelanggan.fromString(tipePelangganStr);

      final tarifResponse = await _client
          .from('tarif')
          .select('denda_per_bulan')
          .eq('tipe_pelanggan', tipePelanggan.dbValue)
          .single();
      final dendaPerBulan = (tarifResponse['denda_per_bulan'] as num?)?.toDouble() ?? 0.0;

      final totalDenda = jumlahBulanTunggakan * dendaPerBulan;
      return activeBill.copyWith(
        totalDenda: totalDenda,
        jumlahBulanTunggakan: jumlahBulanTunggakan,
        fotoBukti: fotoBuktiUrl,
      );
    } catch (e) {
      return activeBill.copyWith(
        totalDenda: 0.0,
        jumlahBulanTunggakan: jumlahBulanTunggakan,
        fotoBukti: fotoBuktiUrl,
      );
    }
  }

  Future<List<PembayaranModel>> getPaymentsForCustomer(String pelangganId) async {
    // Get payments where payment's tagihan's pelanggan_id matches pelangganId.
    // In Supabase we can do inner join or filter.
    // A simpler way is: query tagihan IDs for this customer, then query payments matching those tagihan IDs.
    final bills = await getTagihanForCustomer(pelangganId);
    if (bills.isEmpty) return [];
    
    final billIds = bills.map((b) => b.id).toList();
    final response = await _client
        .from('pembayaran')
        .select()
        .inFilter('tagihan_id', billIds)
        .order('waktu_bayar', ascending: false);

    return (response as List).map((json) => PembayaranModel.fromJson(json)).toList();
  }

  Future<List<TagihanModel>> getAllTagihan() async {
    final response = await _client
        .from('tagihan')
        .select()
        .order('id', ascending: false);
    return (response as List).map((json) => TagihanModel.fromJson(json)).toList();
  }

  /// Mock payment processing
  Future<bool> processPaymentMock({
    required int tagihanId,
    required String metodePembayaran,
    required double jumlahBayar,
    double totalDenda = 0.0,
    String? diterimaOleh,
  }) async {
    // 1. Simulate 2-second network latency
    await Future.delayed(const Duration(seconds: 2));

    try {
      final orderId = 'SP3A-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(900) + 100}';
      
      // 2. Record the payment in the DB
      await _client.from('pembayaran').insert({
        'id': orderId,
        'tagihan_id': tagihanId,
        'metode_pembayaran': metodePembayaran,
        'jumlah_bayar': jumlahBayar,
        'status_pembayaran': 'sukses',
        'waktu_bayar': DateTime.now().toIso8601String(),
        if (diterimaOleh != null) 'diterima_oleh': diterimaOleh,
      });

      // 3. Update the tagihan status to 'lunas' and total_denda
      await _client
          .from('tagihan')
          .update({
            'status_tagihan': 'lunas',
            'total_denda': totalDenda,
          })
          .eq('id', tagihanId);
      return true;
    } catch (e) {
      throw Exception('Payment simulation failed: $e');
    }
  }

  Future<List<PembayaranDetailModel>> getPaymentsWithDetails(String pelangganId) async {
    final response = await _client
        .from('pembayaran')
        .select('*, tagihan!inner(*, pencatatan_meteran(*))')
        .eq('tagihan.pelanggan_id', pelangganId)
        .order('waktu_bayar', ascending: false);

    return (response as List)
        .map((json) => PembayaranDetailModel.fromJson(json))
        .toList();
  }
}

final tagihanServiceProvider = Provider<TagihanService>((ref) {
  return TagihanService();
});

final activeTagihanProvider = FutureProvider.family.autoDispose<TagihanModel?, String>((ref, pelangganId) async {
  return ref.watch(tagihanServiceProvider).getActiveTagihanForCustomer(pelangganId);
});

final paymentHistoryProvider = FutureProvider.family.autoDispose<List<PembayaranModel>, String>((ref, pelangganId) async {
  return ref.watch(tagihanServiceProvider).getPaymentsForCustomer(pelangganId);
});

final paymentHistoryWithDetailsProvider = FutureProvider.family.autoDispose<List<PembayaranDetailModel>, String>((ref, pelangganId) async {
  return ref.watch(tagihanServiceProvider).getPaymentsWithDetails(pelangganId);
});

final customerBillsProvider = FutureProvider.family.autoDispose<List<TagihanModel>, String>((ref, pelangganId) async {
  return ref.watch(tagihanServiceProvider).getTagihanForCustomer(pelangganId);
});

final allBillsProvider = FutureProvider.autoDispose<List<TagihanModel>>((ref) async {
  return ref.watch(tagihanServiceProvider).getAllTagihan();
});

final tagihanWithPencatatanProvider = FutureProvider.family.autoDispose<List<TagihanWithPencatatan>, String>((ref, pelangganId) async {
  final response = await Supabase.instance.client
      .from('tagihan')
      .select('*, pencatatan_meteran(*)')
      .eq('pelanggan_id', pelangganId)
      .order('id', ascending: false);
  return (response as List).map((json) => TagihanWithPencatatan.fromJson(json)).toList();
});

final unpaidTagihanProvider = FutureProvider.family.autoDispose<List<TagihanWithPencatatan>, String>((ref, pelangganId) async {
  final response = await Supabase.instance.client
      .from('tagihan')
      .select('*, pencatatan_meteran!inner(*)')
      .eq('pelanggan_id', pelangganId)
      .eq('status_tagihan', 'belum_dibayar');
  
  final list = (response as List).map((json) => TagihanWithPencatatan.fromJson(json)).toList();
  
  // Sort chronologically descending
  list.sort((a, b) {
    if (a.periodeTahun != b.periodeTahun) {
      return b.periodeTahun.compareTo(a.periodeTahun);
    }
    return b.periodeBulan.compareTo(a.periodeBulan);
  });
  return list;
});
