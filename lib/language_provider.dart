import 'package:flutter/foundation.dart';

class LanguageProvider extends ChangeNotifier {
  LanguageProvider([String initial = 'en']) : _language = initial;

  String _language; // 'en' or 'id'
  String get language => _language;
  bool get isIndo => _language == 'id';

  void toggleLanguage() {
    setLanguage(_language == 'en' ? 'id' : 'en');
  }

  void setLanguage(String langCode) {
    if (_language != langCode) {
      _language = langCode;
      notifyListeners(); // ⟵ rebuilds the whole app
    }
  }
}
