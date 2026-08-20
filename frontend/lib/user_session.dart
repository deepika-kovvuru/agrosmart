class User {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String? state;
  final String? district;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.state,
    this.district,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      state: json['state'],
      district: json['district'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'state': state,
      'district': district,
    };
  }
}

class UserSession {
  static User? currentUser;

  static bool get isLoggedIn => currentUser != null;
}
