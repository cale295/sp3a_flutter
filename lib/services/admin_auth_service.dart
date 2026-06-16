import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/supabase_constants.dart';
import '../models/user_model.dart';

class AdminAuthService {
  late final SupabaseClient adminClient;

  AdminAuthService() {
    final url = SupabaseConstants.url;
    final serviceRoleKey = SupabaseConstants.serviceRoleKey;
    adminClient = SupabaseClient(url, serviceRoleKey);
  }

  /// Creates a new authentication user and profile securely.
  /// Rollbacks Auth user creation if profile insertion fails to prevent orphaned auth users.
  Future<void> createAuthUserAndProfile({
    required UserModel user,
    required String email,
    required String password,
  }) async {
    String? userId;
    try {
      final response = await adminClient.auth.admin.createUser(
        AdminUserAttributes(
          email: email,
          password: password,
          emailConfirm: true,
        ),
      );

      final authUser = response.user;
      if (authUser == null) {
        throw Exception('Response user is null during admin auth user creation.');
      }
      userId = authUser.id;

      // Insert profile details mapping UUID as id to public.users
      await adminClient.from('users').insert({
        'id': userId,
        'username': user.username,
        'role': user.role.name,
        'nama_lengkap': user.namaLengkap,
        'alamat': user.alamat,
        'tipe_pelanggan': user.tipePelanggan.dbValue,
        'is_first_login': true,
      });
    } catch (e) {
      // Rollback Auth user creation if database profile insertion failed
      if (userId != null) {
        try {
          await adminClient.auth.admin.deleteUser(userId);
        } catch (rollbackError) {
          debugPrint('Error deleting Auth user during rollback cleanup: $rollbackError');
        }
      }
      rethrow;
    }
  }

  /// Resets a user's password and forces change password on next login.
  Future<void> adminResetPassword({
    required String userId,
    required String tempPassword,
  }) async {
    // 1. Update Auth password using Service Role Key client
    await adminClient.auth.admin.updateUserById(
      userId,
      attributes: AdminUserAttributes(password: tempPassword),
    );

    // 2. Set is_first_login to true in profile table
    await adminClient.from('users').update({
      'is_first_login': true,
    }).eq('id', userId);
  }
}

final adminAuthServiceProvider = Provider<AdminAuthService>((ref) {
  return AdminAuthService();
});
