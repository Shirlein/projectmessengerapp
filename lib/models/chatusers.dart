class ChatUser {
  ChatUser({
    required this.image,
    required this.about,
    required this.fullName,
    required this.createdAt,
    required this.id,
    required this.lastActive,
    required this.isOnline,
    required this.pushToken,
    required this.email,
    required this.username,
    required this.bio,
  });
  late String image;
  late String about;
  late String fullName;
  late String createdAt;
  late String id;
  late String lastActive;
  late bool isOnline;
  late String pushToken;
  late String email;
  late String username;
  late String bio;

  ChatUser.fromJson(Map<String, dynamic> json) {
    image = json['image'] ?? '';
    about = json['about'] ?? '';
    fullName = json['fullName'] ?? '';
    createdAt = json['created_at'] ?? '';
    id = json['id'] ?? '';
    lastActive = json['last_active'] ?? '';
    isOnline = json['is_online'] ?? '';
    pushToken = json['push_token'] ?? '';
    email = json['email'] ?? '';
    username = json['username'] ?? '';
    bio = json['bio'] ?? '';
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['image'] = image;
    data['about'] = about;
    data['fullName'] = fullName;
    data['created_at'] = createdAt;
    data['id'] = id;
    data['last_active'] = lastActive;
    data['is_online'] = isOnline;
    data['push_token'] = pushToken;
    data['email'] = email;
    data['username'] = username;
    data['bio'] = bio;
    return data;
  }
}
