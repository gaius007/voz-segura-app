import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voz_segura_app/src/core/services/app_icon_service.dart';

class CamouflageNotifier extends ChangeNotifier {
  static const _keyIsCamouflaged = 'is_camouflaged';
  static const _keySecretWord = 'secret_word';
  static const _keyShowExplanation = 'show_explanation';

  final SharedPreferences _prefs;

  bool _isCamouflaged = false;
  String _secretWord = 'seguranca';
  bool _showExplanation = true;

  CamouflageNotifier(this._prefs) {
    _isCamouflaged = _prefs.getBool(_keyIsCamouflaged) ?? false;
    _secretWord = _prefs.getString(_keySecretWord) ?? 'seguranca';
    _showExplanation = _prefs.getBool(_keyShowExplanation) ?? true;
  }

  bool get isCamouflaged => _isCamouflaged;
  String get secretWord => _secretWord;
  bool get showExplanation => _showExplanation;

  Future<void> setCamouflaged(bool value) async {
    _isCamouflaged = value;
    await _prefs.setBool(_keyIsCamouflaged, value);
    notifyListeners();
    // Alterna o ícone do launcher para acompanhar o disfarce (Android).
    if (value) {
      await AppIconService.setNewsIcon();
    } else {
      await AppIconService.setDefaultIcon();
    }
  }

  Future<void> setSecretWord(String word) async {
    _secretWord = word;
    await _prefs.setString(_keySecretWord, word);
    notifyListeners();
  }

  Future<void> setShowExplanation(bool value) async {
    _showExplanation = value;
    await _prefs.setBool(_keyShowExplanation, value);
    notifyListeners();
  }

  Future<void> toggleCamouflage() async {
    await setCamouflaged(!_isCamouflaged);
  }
}
