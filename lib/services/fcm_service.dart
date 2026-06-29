import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FcmService {
  final SupabaseClient _supabase = Supabase.instance.client;
  StreamSubscription<String>? _tokenRefreshSubscription;

  /// Retrieves the device token (after asking for iOS/Android permissions)
  /// and updates the Supabase 'users' table.
  Future<void> saveDeviceToken() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      debugPrint('[FcmService] User is not logged in. Skipping token registration.');
      return;
    }

    try {
      final messaging = FirebaseMessaging.instance;

      // 1. Request permissions for iOS and newer Android versions
      debugPrint('[FcmService] Requesting notification permissions...');
      final settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('[FcmService] Permission status: ${settings.authorizationStatus}');

      // 2. Fetch the FCM token
      final token = await messaging.getToken();
      if (token == null) {
        debugPrint('[FcmService] FCM token is null.');
        return;
      }

      debugPrint('[FcmService] Device token retrieved: ${token.substring(0, 10)}...');

      // 3. Update Supabase
      await _supabase
          .from('users')
          .update({'fcm_token': token})
          .eq('id', userId);

      debugPrint('[FcmService] Successfully saved device token to Supabase users table.');
    } catch (e) {
      debugPrint('[FcmService] Error retrieving or saving device token: $e');
    }
  }

  /// Sets up a stream listener to automatically update the token in Supabase
  /// if it changes while the user session is active.
  void listenToTokenRefresh() {
    _tokenRefreshSubscription?.cancel();

    _tokenRefreshSubscription = FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      debugPrint('[FcmService] FCM Token refreshed. Updating Supabase...');
      try {
        await _supabase
            .from('users')
            .update({'fcm_token': newToken})
            .eq('id', userId);
        debugPrint('[FcmService] Automatically updated refreshed token in Supabase.');
      } catch (e) {
        debugPrint('[FcmService] Error updating refreshed token: $e');
      }
    });
  }

  /// Cancel token refresh stream subscription
  void dispose() {
    _tokenRefreshSubscription?.cancel();
  }
}

final fcmServiceProvider = Provider<FcmService>((ref) {
  final service = FcmService();
  ref.onDispose(() => service.dispose());
  return service;
});
