import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/language_service.dart';

class LanguageProvider extends ChangeNotifier {
  final LanguageService _languageService = LanguageService();
  bool _isInitialized = false;
  bool _isDisposed = false;

  bool get isInitialized => _isInitialized;
  String get currentLanguage => _languageService.currentLanguage;
  bool get isUrdu => _languageService.isUrdu;
  bool get isEnglish => _languageService.isEnglish;

  // Initialize language service
  Future<void> init() async {
    await _languageService.init();
    _isInitialized = true;
    // Avoid notifying during provider bootstrap to prevent lifecycle race conditions.
  }

  // Change language
  Future<void> setLanguage(String language) async {
    await _languageService.setLanguage(language);
    _safeNotifyListeners();
  }

  // Toggle between English and Urdu
  Future<void> toggleLanguage() async {
    await _languageService.toggleLanguage();
    _safeNotifyListeners();
  }

  void _safeNotifyListeners() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  // Get translated text
  String translate(String key) {
    return AppTranslations.get(key, currentLanguage);
  }

  // Helper method - pass English and Urdu text directly
  String t(String englishText, String urduText) {
    return _languageService.translate(englishText, urduText);
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
