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
  });

  final String id;
  final String email;
  final String username;
  final String displayName;
  final String bio;
  final String? country;
  final int rating;
  final bool emailVerified;

  factory Account.fromJson(Map<String, dynamic> json) => Account(
    id: json['id'] as String,
    email: json['email'] as String,
    username: json['username'] as String,
    displayName: json['display_name'] as String,
    bio: (json['bio'] as String?) ?? '',
    country: json['country'] as String?,
    rating: (json['rating'] as num?)?.toInt() ?? 1200,
    emailVerified: json['email_verified'] == true,
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
  });

  final String id;
  final String username;
  final String displayName;
  final String bio;
  final String? country;
  final int rating;

  factory Player.fromJson(Map<String, dynamic> json) => Player(
    id: json['id'] as String,
    username: json['username'] as String,
    displayName: json['display_name'] as String,
    bio: (json['bio'] as String?) ?? '',
    country: json['country'] as String?,
    rating: (json['rating'] as num?)?.toInt() ?? 1200,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'display_name': displayName,
    'bio': bio,
    'country': country,
    'rating': rating,
  };
}
