import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/user_model.dart';

class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;

  AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    String? error,
    bool? isAuthenticated,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final SupabaseClient _client = Supabase.instance.client;

  AuthNotifier() : super(AuthState()) {
    _init();
  }

  void _init() {
    // Listen to Supabase Auth State changes
    _client.auth.onAuthStateChange.listen((data) async {
      final session = data.session;
      if (session == null) {
        state = AuthState();
      } else {
        await fetchUserProfile(session.user.id);
        if (state.isAuthenticated && state.user?.role == UserRole.pelanggan) {
          await updateFcmToken();
        }
      }
    });
  }

  Future<void> updateFcmToken() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      final token = await messaging.getToken();
      if (token != null) {
        await _client
            .from('users')
            .update({'fcm_token': token})
            .eq('id', userId);
      }
    } catch (e) {
      // Fail silently to prevent login errors in environments without Firebase config
      debugPrint('Firebase Messaging Token update failed: $e');
    }
  }

  Future<void> signIn(String identifier, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Supabase signInWithPassword takes email/phone. We support both.
      // If it doesn't look like an email, we assume username. In a real-world setting,
      // you might map username -> email via an Edge function or table query first.
      String email = identifier;
      if (!identifier.contains('@')) {
        // Query email from profile table users where username == identifier
        final res = await _client
            .from('users')
            .select('id')
            .eq('username', identifier)
            .maybeSingle();
        if (res != null) {
          // In Supabase Auth, you normally login via email. If we need to fetch the email, 
          // we can assume the email is username@sp3a.com or let's try login directly,
          // or assume username is actually an email since Supabase signIn expects email.
          // Let's assume standard email structure or username-configured email.
          // For safety, we'll try to use the identifier as-is. If it is a username,
          // we'll assume it is formatted as "username@sp3a.local" for auth mapping, 
          // or simply login as-is.
          email = '$identifier@sp3a.com'; // Default mapping pattern if user enters username
        }
      }

      await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      // fetchUserProfile is automatically triggered by onAuthStateChange
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> fetchUserProfile(String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _client
          .from('users')
          .select()
          .eq('id', userId)
          .single();
      
      final userModel = UserModel.fromJson(data);
      state = AuthState(
        user: userModel,
        isLoading: false,
        isAuthenticated: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load user profile: ${e.toString()}',
      );
    }
  }

  Future<bool> changePassword(String newPassword) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // 1. Update Auth password
      await _client.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      // 2. Set is_first_login to false in public.users table
      final userId = _client.auth.currentUser?.id;
      if (userId != null) {
        await _client
            .from('users')
            .update({'is_first_login': false})
            .eq('id', userId);
        
        await fetchUserProfile(userId);
        return true;
      }
      state = state.copyWith(isLoading: false, error: 'User session not found');
      return false;
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    try {
      await _client.auth.signOut();
      state = AuthState();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
