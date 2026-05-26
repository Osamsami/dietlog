import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/user_profile.dart';
import '../../data/repositories/auth_repository.dart';

/// Provides the [AuthRepository] singleton instance.
/// This is the entry point for all authentication operations in the app.
/// The repository pattern decouples Supabase SDK calls from the UI layer.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// Stream provider for authentication state changes.
///
/// Emits [AuthState] events (signed_in, signed_out, token_refreshed, etc.)
/// that downstream providers and widgets can reactively listen to.
/// This drives automatic UI re-renders when auth state changes.
final authStateProvider = StreamProvider<AuthState>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return authRepo.onAuthStateChange;
});

/// Provider for the currently authenticated Supabase [User].
///
/// CRITICAL FIX: Uses direct Supabase client access as the primary source,
/// with `authStateProvider` watched only to trigger re-evaluation when
/// auth state changes. This fixes the false-positive "sign in first" error
/// on the camera screen, which occurred because the stream hadn't emitted
/// yet on first read.
final currentAuthUserProvider = Provider<User?>((ref) {
  // Watch auth state stream to trigger re-evaluation on auth changes
  ref.watch(authStateProvider);
  // PRIMARY SOURCE: Direct Supabase client access — always returns
  // the current user even before the stream emits its first event
  return Supabase.instance.client.auth.currentUser;
});

/// Convenience provider exposing just the user ID string.
/// Used by the camera screen to pass userId to the inference pipeline.
final currentAuthUserIdProvider = Provider<String?>((ref) {
  return ref.watch(currentAuthUserProvider)?.id;
});

/// Future provider that fetches the current user's [UserProfile]
/// from Supabase (with local cache fallback).
///
/// Automatically invalidated when auth state changes, ensuring
/// fresh profile data after login/signup.
final currentUserProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final authRepo = ref.watch(authRepositoryProvider);
  // Re-fetch when auth state changes
  ref.watch(authStateProvider);

  if (!authRepo.isAuthenticated) return null;
  return authRepo.getProfile();
});

/// Provider that exposes whether the user is currently authenticated.
/// Consumed by guards and conditional UI rendering.
final isAuthenticatedProvider = Provider<bool>((ref) {
  // Direct check — does not depend on stream timing
  return Supabase.instance.client.auth.currentSession != null;
});
