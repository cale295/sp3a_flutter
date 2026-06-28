// lib/services/midtrans_service.dart
// Secure Midtrans payment service — calls Supabase Edge Function only.
// The Midtrans Server Key is NEVER stored or used in Flutter.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Result of a transaction creation request.
class MidtransTransactionResult {
  final String redirectUrl;

  const MidtransTransactionResult({required this.redirectUrl});
}

/// Handles all communication with the `midtrans-handler` Supabase Edge Function.
class MidtransService {
  final SupabaseClient _client;

  MidtransService(this._client);

  /// Calls the `create-transaction` action on the Edge Function.
  ///
  /// Returns a [MidtransTransactionResult] containing the Snap redirect URL.
  /// Throws an [Exception] on failure.
  Future<MidtransTransactionResult> createTransaction({
    required int tagihanId,
    required double jumlahBayar,
    required String pelangganName,
  }) async {
    debugPrint(
      '[MidtransService] Invoking create-transaction: '
      'tagihanId=$tagihanId, jumlahBayar=$jumlahBayar',
    );

    try {
      final response = await _client.functions.invoke(
        'midtrans-handler',
        body: {
          'action': 'create-transaction',
          'tagihan_id': tagihanId,
          'jumlah_bayar': jumlahBayar,
          'pelanggan_name': pelangganName,
        },
      );

      // `functions.invoke` throws on HTTP error, but check data defensively
      final data = response.data as Map<String, dynamic>?;

      if (data == null) {
        throw Exception('Edge Function returned empty response.');
      }

      // Edge Function may return an error body even on 2xx in some cases
      if (data.containsKey('error')) {
        throw Exception('Edge Function error: ${data['error']}');
      }

      final redirectUrl = data['redirect_url'] as String?;
      if (redirectUrl == null || redirectUrl.isEmpty) {
        throw Exception('Edge Function did not return a valid redirect_url.');
      }

      debugPrint('[MidtransService] Got redirect_url: $redirectUrl');
      return MidtransTransactionResult(redirectUrl: redirectUrl);
    } on FunctionException catch (e) {
      debugPrint('[MidtransService] FunctionException: ${e.reasonPhrase}');
      throw Exception('Gagal menghubungi server pembayaran: ${e.reasonPhrase}');
    } catch (e) {
      debugPrint('[MidtransService] Unexpected error: $e');
      rethrow;
    }
  }
}

/// Riverpod provider for [MidtransService].
final midtransServiceProvider = Provider<MidtransService>((ref) {
  return MidtransService(Supabase.instance.client);
});
