class AppUser {
  final String id;
  final String? email;
  final String? displayName;
  final String? photoURL;
  final bool isAnonymous;

  AppUser({
    required this.id,
    this.email,
    this.displayName,
    this.photoURL,
    this.isAnonymous = false,
  });
}
