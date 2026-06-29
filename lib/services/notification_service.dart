import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  final SupabaseClient _client;

  NotificationService(this._client);

  /// Invokes the `send-reminder` Edge Function to trigger an FCM push notification.
  Future<void> sendReminder({
    required String pelangganId,
    required String periode,
  }) async {
    debugPrint(
      '[NotificationService] Invoking send-reminder: '
      'pelangganId=$pelangganId, periode=$periode',
    );

    try {
      final response = await _client.functions.invoke(
        'send-reminder',
        body: {
          'pelanggan_id': pelangganId,
          'periode': periode,
        },
      );

      final data = response.data as Map<String, dynamic>?;

      if (data == null) {
        throw Exception('Edge Function returned empty response.');
      }

      if (data.containsKey('error')) {
        throw Exception('Edge Function error: ${data['error']}');
      }

      debugPrint('[NotificationService] send-reminder success: ${data['message'] ?? 'OK'}');
    } on FunctionException catch (e) {
      debugPrint('[NotificationService] FunctionException: ${e.reasonPhrase}');
      throw Exception('Gagal mengirim peringatan: ${e.reasonPhrase}');
    } catch (e) {
      debugPrint('[NotificationService] Unexpected error: $e');
      rethrow;
    }
  }
}

/// Riverpod provider for [NotificationService].
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(Supabase.instance.client);
});
