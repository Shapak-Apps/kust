import 'package:kust/core/net/server_config.dart';

class Account {
  const Account({
    required this.id,
    required this.email,
    required this.username,
    required this.displayName,
    required this.bio,
    required this.country,
    required this.rating,
    required this.emailVerified,
    this.avatarKey,
  });

  final String id;
  final String email;
  final String username;
  final String displayName;
  final String bio;
  final String? country;
  final int rating;
  final bool emailVerified;

  /// The profile photo in the server's bucket; see [avatarUrlFor].
  final String? avatarKey;

  factory Account.fromJson(Map<String, dynamic> json) => Account(
    id: json['id'] as String,
    email: json['email'] as String,
    username: json['username'] as String,
    displayName: json['display_name'] as String,
    bio: (json['bio'] as String?) ?? '',
    country: json['country'] as String?,
    rating: (json['rating'] as num?)?.toInt() ?? 1200,
    emailVerified: json['email_verified'] == true,
    avatarKey: json['avatar_key'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'username': username,
    'display_name': displayName,
    'bio': bio,
    'country': country,
    'rating': rating,
    'email_verified': emailVerified,
    'avatar_key': avatarKey,
  };
}

class Player {
  const Player({
    required this.id,
    required this.username,
    required this.displayName,
    required this.bio,
    required this.country,
    required this.rating,
    this.avatarKey,
    this.createdAt,
  });

  final String id;
  final String username;
  final String displayName;
  final String bio;
  final String? country;
  final int rating;

  /// The profile photo; see [avatarUrlFor].
  final String? avatarKey;

  /// When they joined.
  final DateTime? createdAt;

  factory Player.fromJson(Map<String, dynamic> json) => Player(
    id: json['id'] as String,
    username: json['username'] as String,
    displayName: json['display_name'] as String,
    bio: (json['bio'] as String?) ?? '',
    country: json['country'] as String?,
    rating: (json['rating'] as num?)?.toInt() ?? 1200,
    avatarKey: json['avatar_key'] as String?,
    createdAt: DateTime.tryParse((json['created_at'] as String?) ?? ''),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'avatar_key': avatarKey,
    'created_at': createdAt?.toIso8601String(),
    'display_name': displayName,
    'bio': bio,
    'country': country,
    'rating': rating,
  };
}

/// Where a profile photo is loaded from: the server answers with a short-
/// lived link into its bucket. Null when there is no photo.
String? avatarUrlFor(String? key) {
  if (key == null || key.isEmpty || !ServerConfig.enabled) return null;
  final base = ServerConfig.apiUrl.endsWith('/')
      ? ServerConfig.apiUrl.substring(0, ServerConfig.apiUrl.length - 1)
      : ServerConfig.apiUrl;
  return '$base/v1/$key';
}

/// How another player stands to the signed-in one.
enum Friendship {
  none,
  outgoing,
  incoming,
  friends;

  static Friendship parse(Object? value) => Friendship.values.firstWhere(
    (f) => f.name == value,
    orElse: () => Friendship.none,
  );
}
