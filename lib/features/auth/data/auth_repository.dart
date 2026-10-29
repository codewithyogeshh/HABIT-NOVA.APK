import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';

/// AuthRepository — clean interface for authentication operations.
///
/// This repository wraps the SupabaseService and provides a stable API
/// for the presentation layer. It handles error mapping and returns
/// typed results instead of throwing exceptions.
class AuthRepository {
  /// Sign up a new user with email, password, and username.
  ///
  /// Returns [AuthResponse] on success, or throws [AuthException] on failure.
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      final result = await SupabaseService.signUp(
        email: email,
        password: password,
        username: username,
      );
      if (result.user != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_user_logged_in', true);
        await prefs.setString('logged_in_user_id', result.user!.id);
      }
      return result;
    } on AuthException catch (e) {
      throw _mapAuthException(e);
    } catch (e) {
      throw AuthException('Signup failed: ${e.toString()}');
    }
  }

  /// Sign in with email and password.
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final result = await SupabaseService.signIn(
        email: email,
        password: password,
      );
      if (result.user != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_user_logged_in', true);
        await prefs.setString('logged_in_user_id', result.user!.id);
      }
      return result;
    } on AuthException catch (e) {
      throw _mapAuthException(e);
    } catch (e) {
      throw AuthException('Login failed: ${e.toString()}');
    }
  }

  /// Sign out the current user.
  Future<void> signOut() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_user_logged_in', false);
      await prefs.remove('logged_in_user_id');
      await SupabaseService.signOut();
    } on AuthException catch (e) {
      throw _mapAuthException(e);
    } catch (e) {
      throw AuthException('Logout failed: ${e.toString()}');
    }
  }

  /// Check whether the user is persistently logged in across restarts/reloads.
  Future<bool> isLoggedIn() async {
    try {
      if (SupabaseService.isAuthenticated) return true;
      if (SupabaseService.session != null) return true;
      if (SupabaseService.user != null) return true;

      final prefs = await SharedPreferences.getInstance();
      final hasFlag = prefs.getBool('is_user_logged_in') ?? false;
      return hasFlag;
    } catch (_) {
      return SupabaseService.isAuthenticated;
    }
  }

  /// Get the current session (for session restore on app start).
  Session? getCurrentSession() {
    return SupabaseService.getCurrentSession();
  }

  /// Get the current authenticated user.
  User? getCurrentUser() {
    return SupabaseService.user;
  }

  /// Check if user is authenticated.
  bool get isAuthenticated => SupabaseService.isAuthenticated;

  /// Fetch the user's profile from the profiles table.
  Future<Map<String, dynamic>> getProfile({required String userId}) async {
    try {
      return await SupabaseService.getProfile(userId: userId);
    } catch (e) {
      throw AuthException('Failed to fetch profile: ${e.toString()}');
    }
  }

  /// Update the user's profile.
  Future<void> updateProfile({
    required String userId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      await SupabaseService.updateProfile(userId: userId, updates: updates);
    } catch (e) {
      throw AuthException('Failed to update profile: ${e.toString()}');
    }
  }

  /// Send a password reset email.
  Future<void> resetPassword({required String email}) async {
    try {
      await SupabaseService.resetPassword(email: email);
    } on AuthException catch (e) {
      throw _mapAuthException(e);
    } catch (e) {
      throw AuthException('Password reset failed: ${e.toString()}');
    }
  }

  /// Stream of auth state changes (for reactive UI).
  Stream<AuthState> get authStateChanges => SupabaseService.client.auth.onAuthStateChange;

  /// Map Supabase AuthException to user-friendly messages.
  AuthException _mapAuthException(AuthException e) {
    String message;
    final code = e.code?.toLowerCase() ?? '';
    final rawMessage = e.message.toLowerCase();

    if (code == 'over_email_send_rate_limit' ||
        code == 'email_rate_limit_exceeded' ||
        code == 'over_request_rate_limit' ||
        rawMessage.contains('rate limit')) {
      message =
          'Email rate limit reached for Supabase. If you already created this account, please Log In. In development, turn off "Confirm email" in Supabase Dashboard (Auth > Providers > Email).';
    } else if (code == 'user_already_exists' || rawMessage.contains('already registered')) {
      message = 'An account with this email already exists. Please log in.';
    } else if (code == 'invalid_credentials' || rawMessage.contains('invalid login credentials')) {
      message = 'Invalid email or password. If you don\'t have an account, please register first then log in.';
    } else if (code == 'email_not_confirmed' || rawMessage.contains('email not confirmed')) {
      message = 'Please confirm your email address before signing in.';
    } else if (code == 'weak_password') {
      message = 'Password is too weak. Please use at least 8 characters.';
    } else if (code == 'invalid_email') {
      message = 'Please enter a valid email address.';
    } else if (code == 'signup_disabled') {
      message = 'Sign up is currently disabled.';
    } else {
      message = e.message;
    }
    return AuthException(message, code: e.code);
  }
}

/// Custom exception for auth operations with user-friendly messages.
class AuthException implements Exception {
  final String message;
  final String? code;

  const AuthException(this.message, {this.code});

  @override
  String toString() => 'AuthException: $message${code != null ? ' (code: $code)' : ''}';
}