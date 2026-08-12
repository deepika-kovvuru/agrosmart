class User {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String? state;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.state,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      state: json['state'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'state': state,
    };
  }
}

class UserSession {
  static User? currentUser;

  static bool get isLoggedIn => currentUser != null;
}
