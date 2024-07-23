import 'dart:typed_data';

class Player {
  final int id;
  final String name;
  final String? nameInHomeCountry;
  final String? fullName;
  final Uint8List? image;

  Player(
      {required this.id,
      required this.nameInHomeCountry,
      required this.fullName,
      required this.name,
      this.image});

  factory Player.fromMap(Map<String, dynamic> map) {
    return Player(
      id: map['id'],
      name: map['name'],
      image: map['image'],
      nameInHomeCountry: map['name_in_home_country'],
      fullName: map['full_name'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'image': null,
      'full_name': fullName,
      'name_in_home_country': nameInHomeCountry,
    };
  }
}
