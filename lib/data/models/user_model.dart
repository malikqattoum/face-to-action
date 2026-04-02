class User {
  final int id;
  final String name;
  final String email;
  final String? businessType;
  final DateTime createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.businessType,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      businessType: json['business_type'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'business_type': businessType,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
