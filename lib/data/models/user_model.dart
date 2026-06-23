import 'package:razak_travel/data/models/model_parsers.dart';

enum UserRole {
  owner,
  admin,
  user;

  static UserRole fromValue(String? value) {
    switch (value?.trim().toLowerCase()) {
      case 'owner':
        return UserRole.owner;
      case 'admin':
        return UserRole.admin;
      case 'user':
      default:
        return UserRole.user;
    }
  }
}

class UserModel {
  static const defaultRole = UserRole.user;
  static const defaultIsBanned = false;

  final String id;
  final String email;
  final UserRole role;
  final bool isBanned;

  const UserModel({
    required this.id,
    required this.email,
    this.role = defaultRole,
    this.isBanned = defaultIsBanned,
  });

  factory UserModel.fromMap(
    String id,
    Map<String, dynamic> json,
  ) {
    return UserModel(
      id: id.trim(),
      email: json['email']?.toString().trim() ?? '',
      role: UserRole.fromValue(json['role']?.toString()),
      isBanned: parseBool(json['is_banned'] ?? json['isBanned']),
    );
  }

  UserModel copyWith({
    String? id,
    String? email,
    UserRole? role,
    bool? isBanned,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      role: role ?? this.role,
      isBanned: isBanned ?? this.isBanned,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'role': role.name,
      'is_banned': isBanned,
    };
  }
}
