import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/user_profile.dart';
import '../../data/repositories/auth_repository.dart';

/// Provides the [AuthRepository] singleton instance.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// Stream provider for authentication state changes.
///
/// Emits [AuthState] events (signed_in, signed_out, token_refreshed, etc.)
/// that downstream providers and widgets can reactively listen to.
final authStateProvider = StreamProvider<AuthState>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return authRepo.onAuthStateChange;
});

/// Provider for the currently authenticated Supabase [User].
///
/// Returns `null` when no user is signed in.
final currentAuthUserProvider = Provider<User?>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  // Re-evaluate when auth state changes
  ref.watch(authStateProvider);
  return authRepo.currentUser;
});

/// Future provider that fetches the current user's [UserProfile]
/// from Supabase (with local cache fallback).
///
/// Automatically invalidated when auth state changes.
final currentUserProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final authRepo = ref.watch(authRepositoryProvider);
  // Re-fetch when auth state changes
  ref.watch(authStateProvider);

  if (!authRepo.isAuthenticated) return null;
  return authRepo.getProfile();
});

/// Provider that exposes whether the user is currently authenticated.
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  ref.watch(authStateProvider);
  return authRepo.isAuthenticated;
});
