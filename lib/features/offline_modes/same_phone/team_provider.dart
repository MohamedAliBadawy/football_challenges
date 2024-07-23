import 'package:flutter/material.dart';
import 'package:football_challenges/features/offline_modes/same_phone/user_player_model.dart';

class TeamProvider with ChangeNotifier {
  List<UserPlayer> _teamA = [];
  List<UserPlayer> _teamB = [];
  Set<String> _playerNames = {}; // Track player names to enforce uniqueness

  List<UserPlayer> get teamA => _teamA;
  List<UserPlayer> get teamB => _teamB;

  void emptyTeams() {
    _teamA.clear();
    _teamB.clear();
    _playerNames.clear();
  }

  void addPlayerToTeam(UserPlayer player, String team) {
    if (team == 'A') {
      _teamA.add(player);
    } else if (team == 'B') {
      _teamB.add(player);
    }

    _playerNames.add(player.name);
    player.team = team;
    notifyListeners();
  }

  void movePlayerToTeam(UserPlayer player, String newTeam) {
    if (player.team == newTeam) return;

    if (player.team == 'A') {
      _teamA.remove(player);
    } else if (player.team == 'B') {
      _teamB.remove(player);
    }

    addPlayerToTeam(player, newTeam);
    notifyListeners();
  }

  void removePlayer(UserPlayer player) {
    if (player.team == 'A') {
      _teamA.remove(player);
    } else if (player.team == 'B') {
      _teamB.remove(player);
    }
    _playerNames.remove(player.name);
    notifyListeners();
  }

  void addPlayers(List<UserPlayer> players) {
    emptyTeams();
    for (var player in players) {
      if (!_playerNames.contains(player.name)) {
        if (_teamA.length <= _teamB.length) {
          addPlayerToTeam(player, 'A');
        } else {
          addPlayerToTeam(player, 'B');
        }
      }
    }
  }
}
