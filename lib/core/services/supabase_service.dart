import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

/// Supabase service — singleton client and helper methods.
///
/// All methods use the publishable/anon key only. The Supabase client is
/// initialized once and shared across the app.
class SupabaseService {
  /// The initialized Supabase client from supabase_flutter.
  ///
  /// Uses Supabase.instance.client (initialized in main()), which configures
  /// the persistent asyncStorage required for PKCE authentication flow and
  /// session persistence across Web and Mobile.
  static SupabaseClient get client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      // Fallback for tests or environments where Supabase.initialize() hasn't run
      return SupabaseClient(
        supabaseUrl,
        supabaseAnonKey,
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      );
    }
  }

  static SupabaseClient get _client => client;

  /// Get the current authenticated user, or null if not logged in.
  static User? get user {
    try {
      return _client.auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  /// Check if there is an active authenticated session.
  static bool get isAuthenticated => _client.auth.currentSession != null;

  /// Get the current session, or null if not logged in.
  static Session? get session => _client.auth.currentSession;

  /// Sign up with email and password, then create a profile row.
  /// Returns the auth result and the created user.
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    // 1. Create the auth user in Supabase Auth
    final authResponse = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'username': username},
    );

    // 2. If the user was created (not just a session), create their profile
    if (authResponse.user != null) {
      try {
        await _createProfile(
          userId: authResponse.user!.id,
          username: username,
          email: email,
        );
      } catch (_) {
        // If profile creation failed (e.g. database trigger already created it), don't crash signup
      }
    }

    return authResponse;
  }

  /// Log in with email and password.
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final authResponse = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return authResponse;
  }

  /// Log out the current user.
  static Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Restore the current session from storage (called on app startup).
  static Session? getCurrentSession() {
    return _client.auth.currentSession;
  }

  /// Fetch the user's profile from the profiles table.
  static Future<Map<String, dynamic>> getProfile({
    required String userId,
  }) async {
    final response = await _client
      .from('profiles')
      .select()
      .eq('id', userId)
      .single();

    return Map<String, dynamic>.from(response);
  }

  /// Update the user's profile (username, etc.).
  static Future<void> updateProfile({
    required String userId,
    required Map<String, dynamic> updates,
  }) async {
    await _client
      .from('profiles')
      .update(updates)
      .eq('id', userId);
  }

  /// Send a password recovery email.
  static Future<void> resetPassword({required String email}) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  /// Sign in anonymously (useful for guest flows).
  static Future<AuthResponse> signInAnonymously() async {
    final authResponse = await _client.auth.signInAnonymously();
    return authResponse;
  }

  /// Link an email/password auth to an existing anonymous session.
  static Future<AuthResponse> linkWithPassword({
    required String email,
    required String password,
  }) async {
    // First sign in anonymously, then link
    final anonResponse = await _client.auth.signInAnonymously();
    // Note: Full password linking requires the user to have an existing account.
    // This is a simplified placeholder.
    return anonResponse;
  }

  /// Helper: create the user's profile row in the profiles table.
  static Future<void> _createProfile({
    required String userId,
    required String username,
    required String email,
  }) async {
    await _client.from('profiles').insert({
      'id': userId,
      'username': username,
      'email': email,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }
}
