import 'package:equatable/equatable.dart';

/// Domain entity representing an authenticated ChargeMate user.
class User extends Equatable {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String? profileImagePath;
  final String? preferredCity;
  final List<String> preferredCategories;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    this.profileImagePath,
    this.preferredCity,
    this.preferredCategories = const [],
    required this.createdAt,
  });

  String get firstName => fullName.trim().split(' ').first;

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  User copyWith({
    String? fullName,
    String? phone,
    String? preferredCity,
    List<String>? preferredCategories,
  }) =>
      User(
        id: id,
        fullName: fullName ?? this.fullName,
        email: email,
        phone: phone ?? this.phone,
        profileImagePath: profileImagePath,
        preferredCity: preferredCity ?? this.preferredCity,
        preferredCategories: preferredCategories ?? this.preferredCategories,
        createdAt: createdAt,
      );

  @override
  List<Object?> get props => [
        id,
        fullName,
        email,
        phone,
        profileImagePath,
        preferredCity,
        preferredCategories,
        createdAt,
      ];
}
