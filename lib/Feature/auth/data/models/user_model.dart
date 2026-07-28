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
  });

  /// Creates a new [UserModel] for first-time registration, using
  /// server timestamps for the date fields.
  factory UserModel.newUser({
    required String uid,
    required String fullName,
    required String email,
    String? photoUrl,
    bool isEmailVerified = false,
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
      favorites: (map['favorites'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      createdAt: _toDateTime(map['createdAt']),
      lastLogin: _toDateTime(map['lastLogin']),
      isEmailVerified: map['isEmailVerified'] as bool? ?? false,
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
