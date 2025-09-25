import 'package:google_mlkit_translation/google_mlkit_translation.dart';

class TranslationService {
  static final TranslationService _i = TranslationService._();
  factory TranslationService() => _i;
  TranslationService._();

  final Map<String, String> _cache = {};

  String _key(String t, String from, String to) => '$from->$to::$t';

  // Map app codes to enum (for the translator) and to BCP-47 (for the model manager)
  TranslateLanguage _enumLang(String code) {
    switch (code) {
      case 'id':
      case 'in':
        return TranslateLanguage.indonesian;
      case 'en':
      default:
        return TranslateLanguage.english;
    }
  }

  String _bcp47(String code) {
    switch (code) {
      case 'id':
      case 'in':
        return 'id';
      case 'en':
      default:
        return 'en';
    }
  }

  Future<void> _ensureModel(String code) async {
    final mm = OnDeviceTranslatorModelManager();
    final tag = _bcp47(code); // v0.13.0 expects String tags here
    final has = await mm.isModelDownloaded(tag);
    if (!has) {
      await mm.downloadModel(tag);
    }
  }

  /// Strict translation to the requested language (no fallback text).
  Future<String> translate({
    required String text,
    required String fromCode, // 'en' | 'id'
    required String toCode, // 'en' | 'id'
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || fromCode == toCode) return trimmed;

    final cacheKey = _key(trimmed, fromCode, toCode);
    final cached = _cache[cacheKey];
    if (cached != null) return cached;

    // Ensure models (string tags for manager)
    await _ensureModel(fromCode);
    await _ensureModel(toCode);

    // Do translation (enum for translator)
    final translator = OnDeviceTranslator(
      sourceLanguage: _enumLang(fromCode),
      targetLanguage: _enumLang(toCode),
    );

    try {
      final out = await translator.translateText(trimmed);
      _cache[cacheKey] = out;
      return out;
    } finally {
      translator.close();
    }
  }
}
