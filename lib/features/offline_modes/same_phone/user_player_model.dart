class UserPlayer {
  String name;
  String? team; // Track which team the player belongs to

  UserPlayer({required this.name, this.team});

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'team': team,
    };
  }
}
