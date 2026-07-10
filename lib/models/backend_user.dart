class BackendUser {
  const BackendUser({
    required this.id,
    required this.username,
    required this.role,
  });

  final int id;
  final String username;
  final String role;

  factory BackendUser.fromMap(Map<String, dynamic> map) {
    return BackendUser(
      id: map['id'] as int,
      username: map['username'] as String,
      role: map['role'] as String,
    );
  }
}

class BackendAuthSession {
  const BackendAuthSession({
    required this.accessToken,
    required this.user,
  });

  final String accessToken;
  final BackendUser user;
}
