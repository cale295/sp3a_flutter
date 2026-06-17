import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../models/tarif_model.dart';
import '../models/laporan_pembayaran_model.dart';

class DatabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  // --- USER PROFILE CRUD (Admin) ---

  Future<List<UserModel>> getUsers() async {
    final response = await _client.from('users').select().order('nama_lengkap', ascending: true);
    return (response as List).map((json) => UserModel.fromJson(json)).toList();
  }

  Future<void> createUser(UserModel user, String email) async {
    // Note: Creating auth users requires Admin API, which is handled on the backend.
    // Here we insert the profile mapping to public.users table.
    // We mock/assume that the Auth user ID is generated or passed.
    await _client.from('users').insert({
      'id': user.id,
      'username': user.username,
      'role': user.role.name,
      'nama_lengkap': user.namaLengkap,
      'alamat': user.alamat,
      'tipe_pelanggan': user.tipePelanggan.dbValue,
      'is_first_login': true,
    });
  }

  Future<void> updateUser(UserModel user) async {
    await _client.from('users').update({
      'username': user.username,
      'role': user.role.name,
      'nama_lengkap': user.namaLengkap,
      'alamat': user.alamat,
      'tipe_pelanggan': user.tipePelanggan.dbValue,
      'is_first_login': user.isFirstLogin,
    }).eq('id', user.id);
  }

  Future<void> deleteUser(String userId) async {
    await _client.from('users').delete().eq('id', userId);
  }

  // --- WATER TARIFF CRUD (Admin) ---

  Future<List<TarifModel>> getTarifs() async {
    final response = await _client.from('tarif').select().order('id', ascending: true);
    return (response as List).map((json) => TarifModel.fromJson(json)).toList();
  }

  Future<void> updateTarif(TarifModel tarif) async {
    await _client.from('tarif').update({
      'harga_per_m3': tarif.hargaPerM3,
      'biaya_abodemen': tarif.biayaAbodemen,
      'denda_per_bulan': tarif.dendaPerBulan,
    }).eq('id', tarif.id);
  }


  Future<TarifModel> getTarifForTipe(TipePelanggan tipe) async {
    final response = await _client
        .from('tarif')
        .select()
        .eq('tipe_pelanggan', tipe.dbValue)
        .single();
    return TarifModel.fromJson(response);
  }

  // --- LAPORAN VIEW (Admin) ---

  Future<List<LaporanPembayaran>> getLaporan() async {
    final response = await _client.from('view_laporan_pembayaran').select();
    return (response as List).map((json) => LaporanPembayaran.fromJson(json)).toList();
  }

  // --- CUSTOMERS LIST (Petugas) ---

  Future<List<UserModel>> getPelangganList() async {
    final response = await _client
        .from('users')
        .select()
        .eq('role', 'pelanggan')
        .order('nama_lengkap', ascending: true);
    return (response as List).map((json) => UserModel.fromJson(json)).toList();
  }
}

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

// Providers for UI consumption
final usersListProvider = FutureProvider.autoDispose<List<UserModel>>((ref) async {
  return ref.watch(databaseServiceProvider).getUsers();
});

final tarifsListProvider = FutureProvider.autoDispose<List<TarifModel>>((ref) async {
  return ref.watch(databaseServiceProvider).getTarifs();
});

final laporanProvider = FutureProvider.autoDispose<List<LaporanPembayaran>>((ref) async {
  return ref.watch(databaseServiceProvider).getLaporan();
});

final pelangganListProvider = FutureProvider.autoDispose<List<UserModel>>((ref) async {
  return ref.watch(databaseServiceProvider).getPelangganList();
});

final tarifForTipeProvider = FutureProvider.family.autoDispose<TarifModel, TipePelanggan>((ref, tipe) async {
  return ref.watch(databaseServiceProvider).getTarifForTipe(tipe);
});
