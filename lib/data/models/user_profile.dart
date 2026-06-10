import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

import '../local/hive_boxes.dart';

part 'user_profile.g.dart';

/// Represents a user profile in DietLog.
///
/// Maps to the `public.profiles` table in Supabase, which extends
/// `auth.users`. Annotated for both JSON serialization (Supabase REST)
/// and Hive local caching.
@JsonSerializable()
@HiveType(typeId: HiveTypeIds.userProfile)
class UserProfile extends HiveObject {
  /// Unique user identifier (matches `auth.users.id`).
  @HiveField(0)
  @JsonKey(name: 'id')
  final String id;

  /// User's display name.
  @HiveField(1)
  @JsonKey(name: 'full_name')
  final String fullName;

  /// User's email address (from auth.users, not stored in profiles table).
  @HiveField(2)
  @JsonKey(name: 'email')
  final String email;

  /// Timestamp when the profile was created.
  @HiveField(3)
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  /// Timestamp when the profile was last updated.
  @HiveField(4)
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  UserProfile({
    required this.id,
    required this.fullName,
    required this.email,
    this.createdAt,
    this.updatedAt,
  });

  /// Create a [UserProfile] from a Supabase JSON response.
  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);

  /// Serialize this profile to JSON for Supabase operations.
  Map<String, dynamic> toJson() => _$UserProfileToJson(this);

  /// Create a copy with selective field overrides.
  UserProfile copyWith({
    String? id,
    String? fullName,
    String? email,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() =>
      'UserProfile(id: $id, fullName: $fullName, email: $email)';
}
