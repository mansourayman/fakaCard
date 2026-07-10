class AuthSession {
  const AuthSession({
    required this.seamlessToken,
    required this.accessToken,
    required this.msisdn,
  });

  final String seamlessToken;
  final String accessToken;
  final String msisdn;

  AuthSession copyWith({
    String? seamlessToken,
    String? accessToken,
    String? msisdn,
  }) {
    return AuthSession(
      seamlessToken: seamlessToken ?? this.seamlessToken,
      accessToken: accessToken ?? this.accessToken,
      msisdn: msisdn ?? this.msisdn,
    );
  }
}
