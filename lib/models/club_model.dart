import 'dart:typed_data';

class Club {
  final int id;
  final String name;
  final Uint8List? logo;
  final int leagueId;

  Club({
    required this.id,
    required this.name,
    this.logo,
    required this.leagueId,
  });

  factory Club.fromMap(Map<String, dynamic> map) {
    return Club(
      id: map['id'],
      name: map['name'],
      logo: map['logo'],
      leagueId: map['league_id'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'logo': null,
      'league_id': leagueId,
    };
  }
}
