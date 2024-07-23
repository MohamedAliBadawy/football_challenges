import 'package:flutter/material.dart';

class ButtonState with ChangeNotifier {
  bool _showFirstButtons = false;
  bool _showSecondButtons = true;

  bool get showFirstButtons => _showFirstButtons;
  bool get showSecondButtons => _showSecondButtons;

  void showFirst() {
    _showFirstButtons = true;
    _showSecondButtons = false;

    notifyListeners();
  }

  void showSecond() {
    _showFirstButtons = true;
    _showSecondButtons = true;
    notifyListeners();
  }

  void resetButtons() {
    _showFirstButtons = false;
    _showSecondButtons = false;

    notifyListeners();
  }
}
