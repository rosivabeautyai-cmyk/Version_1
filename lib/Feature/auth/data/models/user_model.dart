import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a ROSIVA user document stored in the `users` collection.
///
/// Document ID = Firebase Auth `uid`.
class UserModel {
  final String uid;
  final String fullName;
  final String email;
  final String? photoUrl;
  final String? country;
  final String? language;
  final String? skinType;
  final List<String> favorites;
  final DateTime? createdAt;
  final DateTime? lastLogin;
  final bool isEmailVerified;

  /// When the user accepted the Terms of Service + Privacy Policy.
  /// `null` on legacy accounts created before consent was recorded.
  final DateTime? termsAcceptedAt;

  /// Tri-state on purpose:
  ///  * `true`  — registration finished (terms accepted, doc complete).
  ///  * `false` — a fresh social sign-in that still owes consent; the
  ///    app must route to the consent gate, NOT Home.
  ///  * `null`  — legacy account from before this field existed; treated
  ///    as complete so existing users are never bounced.
  final bool? registrationCompleted;

  /// Admin-set advisory flag. `true` marks the account disabled in the
  /// Admin panel. NOTE: on its own this does NOT block Firebase Auth
  /// sign-in — that still requires a Cloud Function / the console.
  final bool disabled;

  /// Access role for this account. Either `'user'` or `'admin'`.
  ///
  /// Every account is created as `'user'` — there is no public sign-up
  /// path that can produce an admin account. To promote an account,
  /// change this field to `'admin'` directly in the Firestore console
  /// (users/{uid} -> role). See also `firestore.rules`, which blocks
  /// clients from ever editing this field themselves.
  final String role;

  static const String roleAdmin = 'admin';
  static const String roleUser = 'user';

  const UserModel({
    required this.uid,
    required this.fullName,
    required this.email,
    this.photoUrl,
    this.country,
    this.language,
    this.skinType,
    this.favorites = const [],
    this.createdAt,
    this.lastLogin,
    this.isEmailVerified = false,
    this.disabled = false,
    this.role = roleUser,
    this.termsAcceptedAt,
    this.registrationCompleted,
  });

  bool get isAdmin => role == roleAdmin;

  /// The account may enter the app. Only an explicit `false` (a social
  /// sign-in that hasn't accepted the Terms yet) blocks Home; `null`
  /// (legacy) and `true` both pass.
  bool get isRegistrationComplete => registrationCompleted != false;

  /// Creates a new [UserModel] for first-time registration, using
  /// server timestamps for the date fields. Always created with the
  /// default `'user'` role — admin accounts are never self-assigned.
  factory UserModel.newUser({
    required String uid,
    required String fullName,
    required String email,
    String? photoUrl,
    bool isEmailVerified = false,
    bool registrationCompleted = false,
  }) {
    return UserModel(
      uid: uid,
      fullName: fullName,
      email: email,
      photoUrl: photoUrl,
      country: null,
      language: null,
      skinType: null,
      favorites: const [],
      createdAt: null,
      lastLogin: null,
      isEmailVerified: isEmailVerified,
      role: roleUser,
      registrationCompleted: registrationCompleted,
    );
  }

  /// Builds a [UserModel] from a Firestore document snapshot.
  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    return UserModel(
      uid: map['uid'] as String? ?? documentId,
      fullName: map['fullName'] as String? ?? '',
      email: map['email'] as String? ?? '',
      photoUrl: map['photoUrl'] as String?,
      country: map['country'] as String?,
      language: map['language'] as String?,
      skinType: map['skinType'] as String?,
      favorites:
          (map['favorites'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      createdAt: _toDateTime(map['createdAt']),
      lastLogin: _toDateTime(map['lastLogin']),
      isEmailVerified: map['isEmailVerified'] as bool? ?? false,
      disabled: map['disabled'] as bool? ?? false,
      role: map['role'] as String? ?? roleUser,
      termsAcceptedAt: _toDateTime(map['termsAcceptedAt']),
      // Absent key stays null (legacy = allowed); only a stored bool
      // is read through verbatim.
      registrationCompleted: map['registrationCompleted'] as bool?,
    );
  }

  factory UserModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return UserModel.fromMap(data, doc.id);
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  /// Converts this model to a map for creating a brand new document.
  /// Uses [FieldValue.serverTimestamp] for date fields.
  Map<String, dynamic> toCreateMap() {
    return {
      'uid': uid,
      'fullName': fullName,
      'email': email,
      'photoUrl': photoUrl,
      'country': country,
      'language': language,
      'skinType': skinType,
      'favorites': favorites,
      'createdAt': FieldValue.serverTimestamp(),
      'lastLogin': FieldValue.serverTimestamp(),
      'isEmailVerified': isEmailVerified,
      'role': role,
      // A social sign-in creates its doc with `false` and owes consent;
      // the email/password path passes `true` (the register form makes
      // the checkbox mandatory) and stamps the acceptance time.
      'registrationCompleted': registrationCompleted ?? false,
      if (registrationCompleted == true)
        'termsAcceptedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Converts this model to a plain map (used for updates/merges).
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'fullName': fullName,
      'email': email,
      'photoUrl': photoUrl,
      'country': country,
      'language': language,
      'skinType': skinType,
      'favorites': favorites,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'lastLogin': lastLogin != null ? Timestamp.fromDate(lastLogin!) : null,
      'isEmailVerified': isEmailVerified,
      'role': role,
      'termsAcceptedAt': termsAcceptedAt != null
          ? Timestamp.fromDate(termsAcceptedAt!)
          : null,
      'registrationCompleted': registrationCompleted,
    };
  }

  UserModel copyWith({
    String? uid,
    String? fullName,
    String? email,
    String? photoUrl,
    String? country,
    String? language,
    String? skinType,
    List<String>? favorites,
    DateTime? createdAt,
    DateTime? lastLogin,
    bool? isEmailVerified,
    bool? disabled,
    String? role,
    DateTime? termsAcceptedAt,
    bool? registrationCompleted,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      country: country ?? this.country,
      language: language ?? this.language,
      skinType: skinType ?? this.skinType,
      favorites: favorites ?? this.favorites,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      disabled: disabled ?? this.disabled,
      role: role ?? this.role,
      termsAcceptedAt: termsAcceptedAt ?? this.termsAcceptedAt,
      registrationCompleted:
          registrationCompleted ?? this.registrationCompleted,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.uid == uid;
  }

  @override
  int get hashCode => uid.hashCode;

  @override
  String toString() {
    return 'UserModel(uid: $uid, fullName: $fullName, email: $email, '
        'isEmailVerified: $isEmailVerified)';
  }
}
