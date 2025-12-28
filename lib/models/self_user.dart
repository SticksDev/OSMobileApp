class SelfUser {
  final String id;
  final String name;
  final String email;
  final String image;
  final List<UserRole> roles;
  final String rank;

  const SelfUser({
    required this.id,
    required this.name,
    required this.email,
    required this.image,
    required this.roles,
    required this.rank,
  });

  factory SelfUser.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rolesJson = json['roles'] as List<dynamic>;
    final roles = rolesJson
        .map((role) => UserRole.fromString(role as String))
        .toList();

    return SelfUser(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      image: json['image'] as String,
      roles: roles,
      rank: json['rank'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'image': image,
      'roles': roles.map((role) => role.value).toList(),
      'rank': rank,
    };
  }

  SelfUser copyWith({
    String? id,
    String? name,
    String? email,
    String? image,
    List<UserRole>? roles,
    String? rank,
  }) {
    return SelfUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      image: image ?? this.image,
      roles: roles ?? this.roles,
      rank: rank ?? this.rank,
    );
  }

  @override
  String toString() {
    return 'SelfUser(id: $id, name: $name, email: $email, rank: $rank, roles: $roles)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SelfUser &&
        other.id == id &&
        other.name == name &&
        other.email == email &&
        other.image == image &&
        other.rank == rank;
  }

  @override
  int get hashCode {
    return Object.hash(id, name, email, image, rank);
  }
}

enum UserRole {
  support('Support'),
  staff('Staff'),
  admin('Admin'),
  system('System');

  final String value;
  const UserRole(this.value);

  static UserRole fromString(String value) {
    switch (value) {
      case 'Support':
        return UserRole.support;
      case 'Staff':
        return UserRole.staff;
      case 'Admin':
        return UserRole.admin;
      case 'System':
        return UserRole.system;
      default:
        throw ArgumentError('Invalid user role: $value');
    }
  }

  @override
  String toString() => value;
}
