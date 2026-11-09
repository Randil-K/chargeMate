import 'package:charge_mate/features/auth/domain/entities/user.dart';

/// Data-transfer object for [User]; maps to/from the Spring Boot JSON contract.
class UserModel extends User {
  const UserModel({
    required super.id,
    required super.fullName,
    required super.email,
    required super.phone,
    super.profileImagePath,
    super.preferredCity,
    super.preferredCategories,
    required super.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['userId'].toString(),
        fullName: json['fullName'] as String,
        email: json['email'] as String,
        phone: (json['phoneNumber'] ?? '') as String,
        profileImagePath: json['profileImage'] as String?,
        preferredCity: json['preferredCity'] as String?,
        preferredCategories:
            (json['preferredCategories'] as List?)?.cast<String>() ?? const [],
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
            DateTime.now(),
      );

  factory UserModel.fromEntity(User user) => UserModel(
        id: user.id,
        fullName: user.fullName,
        email: user.email,
        phone: user.phone,
        profileImagePath: user.profileImagePath,
        preferredCity: user.preferredCity,
        preferredCategories: user.preferredCategories,
        createdAt: user.createdAt,
      );

  Map<String, dynamic> toJson() => {
        'userId': id,
        'fullName': fullName,
        'email': email,
        'phoneNumber': phone,
        'profileImage': profileImagePath,
        'preferredCity': preferredCity,
        'preferredCategories': preferredCategories,
        'createdAt': createdAt.toIso8601String(),
      };
}

/// JWT token pair + user returned by `/auth/login` and `/auth/register`.
class AuthResponseModel {
  final String accessToken;
  final String refreshToken;
  final UserModel user;

  const AuthResponseModel({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) =>
      AuthResponseModel(
        accessToken: json['access_token'] as String,
        refreshToken: json['refresh_token'] as String,
        user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      );
}
