import 'dart:typed_data';

List activa = [1, 2, 3, 5, 7, 8, 30, 91];

class League {
  final int id;
  final String name;
  final Uint8List logo;
  final int isActive;

  League(
      {required this.id,
      required this.name,
      required this.logo,
      required this.isActive});

  // Method to convert a map from the database to a League object
  factory League.fromMap(Map<String, dynamic> map) {
    return League(
      id: map['id'],
      name: map['name'],
      logo: map['logo'],
      isActive: activa.contains(map['id']) ? 1 : 0,
    );
  }

  // Method to convert a League object to a map to store in the database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'logo': logo,
      'isActive': isActive,
    };
  }
}
