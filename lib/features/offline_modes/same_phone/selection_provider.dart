import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class SelectionProvider extends ChangeNotifier {
  List<int> leagues = [];

  int? club;

  int selectedScore = 1;
  int selectedTime = 10;

  final TextEditingController roomNameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isPrivate = false;
  int numPlayers = 2;

  void setLeagues(List<int> league) {
    leagues = league;
    notifyListeners();
  }

  void setClub(int clb) {
    club = clb;
    notifyListeners();
  }

  void setScore(int score) {
    selectedScore = score;
    notifyListeners();
  }

  void setTime(int time) {
    selectedTime = time;
    notifyListeners();
  }
}
