import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/logger.dart';
import '../local/hive_boxes.dart';
import '../models/user_profile.dart';
import 'package:hive_flutter/hive_flutter.dart';

final _log = AppLogger('AuthRepository');

/// Handles all authentication operations via Supabase Auth.
///
/// Manages signup, signin, signout, session state, and profile
/// CRUD. Leverages Supabase's built-in JWT session management —
/// no manual token storage required.
class AuthRepository {
  final SupabaseClient _client;

  AuthRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  // ── Sign Up ─────────────────────────────────────────────────────────────

  /// Create a new user account with email, password, and full name.
  ///
  /// The `full_name` is passed as user metadata so the database trigger
  /// (`handle_new_user`) can automatically create the profile row.
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    _log.info('Signing up user: $email');

    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );

    _log.info('Signup successful for: $email');
    return response;
  }

  // ── Sign In ─────────────────────────────────────────────────────────────

  /// Authenticate a user with email and password.
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    _log.info('Signing in user: $email');

    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    // Cache profile locally on successful login
    await _cacheCurrentProfile();

    _log.info('Sign-in successful for: $email');
    return response;
  }

  // ── Sign Out ────────────────────────────────────────────────────────────

  /// Sign out the current user and clear all local caches.
  Future<void> signOut() async {
    _log.info('Signing out current user');

    await _client.auth.signOut();

    // Clear all Hive caches on logout
    await _clearLocalCache();

    _log.info('Sign-out complete — local cache cleared');
  }

  // ── Current User ────────────────────────────────────────────────────────

  /// Get the currently authenticated user, or `null` if not signed in.
  User? get currentUser => _client.auth.currentUser;

  /// Get the current session, or `null` if not authenticated.
  Session? get currentSession => _client.auth.currentSession;

  /// Whether the user is currently authenticated.
  bool get isAuthenticated => currentSession != null;

  // ── Auth State Stream ───────────────────────────────────────────────────

  /// Stream of authentication state changes.
  ///
  /// Emits events for sign-in, sign-out, token refresh, etc.
  Stream<AuthState> get onAuthStateChange =>
      _client.auth.onAuthStateChange;

  // ── Profile Operations ──────────────────────────────────────────────────

  /// Fetch the current user's profile from Supabase.
  ///
  /// Returns `null` if the user is not authenticated or profile not found.
  Future<UserProfile?> getProfile() async {
    final user = currentUser;
    if (user == null) {
      _log.warning('getProfile called with no authenticated user');
      return null;
    }

    _log.debug('Fetching profile for user: ${user.id}');

    final data = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (data == null) {
      _log.warning('No profile found for user: ${user.id}');
      return null;
    }

    // Merge email from auth (not stored in profiles table)
    data['email'] = user.email ?? '';

    final profile = UserProfile.fromJson(data);
    _log.debug('Profile fetched: ${profile.fullName}');
    return profile;
  }

  /// Update the current user's profile name.
  Future<void> updateProfile({required String fullName}) async {
    final user = currentUser;
    if (user == null) {
      throw AuthException('Cannot update profile — not authenticated');
    }

    _log.info('Updating profile for user: ${user.id}');

    await _client
        .from('profiles')
        .update({'full_name': fullName})
        .eq('id', user.id);

    // Update local cache
    await _cacheCurrentProfile();

    _log.info('Profile updated successfully');
  }

  /// Upload a profile picture to Supabase Storage and update user metadata.
  Future<String> uploadAvatar(String localPath) async {
    final user = currentUser;
    if (user == null) {
      throw AuthException('Cannot upload avatar — not authenticated');
    }

    _log.info('Uploading avatar for user: ${user.id}');

    final file = File(localPath);
    final fileExt = localPath.split('.').last;
    final fileName = '${user.id}.${DateTime.now().millisecondsSinceEpoch}.$fileExt';

    // Upload to 'profile-pictures' bucket
    await _client.storage
        .from('profile-pictures')
        .upload(fileName, file);

    // Get public URL
    final publicUrl = _client.storage
        .from('profile-pictures')
        .getPublicUrl(fileName);

    // Update Supabase Auth metadata
    await _client.auth.updateUser(
      UserAttributes(
        data: {'avatar_url': publicUrl},
      ),
    );

    // Also update profiles table if supported
    try {
      await _client
          .from('profiles')
          .update({'avatar_url': publicUrl})
          .eq('id', user.id);
    } catch (_) {
      // Non-fatal if schema differs
    }

    // Refresh local cache
    await _cacheCurrentProfile();

    _log.info('Avatar uploaded successfully: $publicUrl');
    return publicUrl;
  }

  // ── Private Helpers ─────────────────────────────────────────────────────

  /// Cache the current user's profile in Hive for offline access.
  Future<void> _cacheCurrentProfile() async {
    try {
      final profile = await getProfile();
      if (profile != null) {
        final box = Hive.box<UserProfile>(HiveBoxes.userProfile);
        await box.put('current', profile);
        _log.debug('Profile cached locally');
      }
    } catch (e) {
      _log.warning('Failed to cache profile: $e');
    }
  }

  /// Clear all local Hive caches (called on sign-out).
  Future<void> _clearLocalCache() async {
    try {
      await Hive.box<UserProfile>(HiveBoxes.userProfile).clear();
      await Hive.box(HiveBoxes.appSettings).clear();
      _log.debug('Local caches cleared');
    } catch (e) {
      _log.warning('Failed to clear local cache: $e');
    }
  }
}
