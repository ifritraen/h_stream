import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum StealthMode { normal, calculatorDecoy, panicMute }

class StealthProvider extends ChangeNotifier {
  StealthMode _currentMode = StealthMode.normal;
  String _unlockPasscode = "7777";
  bool _panicGestureEnabled = true;
  bool _isPanicActive = false;

  StealthMode get currentMode => _currentMode;
  String get unlockPasscode => _unlockPasscode;
  bool get panicGestureEnabled => _panicGestureEnabled;
  bool get isPanicActive => _isPanicActive;

  StealthProvider() {
    _loadSettings();
  }

  void activateCalculatorDecoy() {
    _currentMode = StealthMode.calculatorDecoy;
    notifyListeners();
  }

  bool unlockFromDecoy(String inputCode) {
    if (inputCode == _unlockPasscode) {
      _currentMode = StealthMode.normal;
      _isPanicActive = false;
      notifyListeners();
      return true;
    }
    return false;
  }

  void triggerPanicEmergency() {
    if (!_panicGestureEnabled) return;
    _isPanicActive = true;
    _currentMode = StealthMode.calculatorDecoy;
    notifyListeners();
  }

  void dismissPanic() {
    _isPanicActive = false;
    _currentMode = StealthMode.normal;
    notifyListeners();
  }

  void setUnlockPasscode(String code) {
    _unlockPasscode = code;
    _saveSettings();
    notifyListeners();
  }

  void togglePanicGesture() {
    _panicGestureEnabled = !_panicGestureEnabled;
    _saveSettings();
    notifyListeners();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _unlockPasscode = prefs.getString('stealth_code') ?? "7777";
    _panicGestureEnabled = prefs.getBool('stealth_panic_gesture') ?? true;
    notifyListeners();
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('stealth_code', _unlockPasscode);
    await prefs.setBool('stealth_panic_gesture', _panicGestureEnabled);
  }
}
