// lib/widgets/translated_text.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:google_mlkit_language_id/google_mlkit_language_id.dart';

/// Shows [originalText] translated to [targetLang] ("en" or "id").
/// Detects source language automatically, caches results, and falls back
/// to the original on any error.
class TranslatedText extends StatefulWidget {
  final String originalText;
  final String targetLang; // "en" or "id"
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final bool softWrap;

  const TranslatedText({
    super.key,
    required this.originalText,
    required this.targetLang,
    this.style,
    this.textAlign,
    this.maxLines,
    this.softWrap = true,
  });

  @override
  State<TranslatedText> createState() => _TranslatedTextState();
}

class _TranslatedTextState extends State<TranslatedText> {
  static final Map<String, String> _cache = {}; // key: "$hash|$target"
  String? _translated;
  bool _isLoading = false;

  OnDeviceTranslator? _translator;
  final _identifier = LanguageIdentifier(confidenceThreshold: 0.5);
  final _modelManager = OnDeviceTranslatorModelManager();

  @override
  void initState() {
    super.initState();
    _translateIfNeeded();
  }

  @override
  void didUpdateWidget(covariant TranslatedText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.originalText != widget.originalText ||
        oldWidget.targetLang != widget.targetLang) {
      _translated = null;
      _translateIfNeeded();
    }
  }

  Future<void> _translateIfNeeded() async {
    final text = widget.originalText.trim();
    if (text.isEmpty) return;

    final cacheKey = "${text.hashCode}|${widget.targetLang}";
    final cached = _cache[cacheKey];
    if (cached != null) {
      setState(() => _translated = cached);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1) Detect source language ("en", "id", "und", etc.)
      final detected = await _identifier.identifyLanguage(text);
      final srcCode = (detected == 'und' || detected.isEmpty) ? 'en' : detected;
      final tgtCode = widget.targetLang.toLowerCase();

      // If same language, just show original
      if (_sameLang(srcCode, tgtCode)) {
        _cache[cacheKey] = text;
        if (!mounted) return;
        setState(() {
          _translated = text;
          _isLoading = false;
        });
        return;
      }

      final srcLang = _toTranslateLanguage(srcCode);
      final tgtLang = _toTranslateLanguage(tgtCode);
      if (srcLang == null || tgtLang == null) {
        _cache[cacheKey] = text;
        if (!mounted) return;
        setState(() {
          _translated = text;
          _isLoading = false;
        });
        return;
      }

      // 2) Ensure models exist (manager is idempotent; it won’t re-download)
      // Some devices need only target model; others may require both.
      try {
        await _modelManager.downloadModel(tgtLang.bcpCode);
      } catch (_) {}
      try {
        await _modelManager.downloadModel(srcLang.bcpCode);
      } catch (_) {}

      // 3) Translate
      _translator?.close();
      _translator = OnDeviceTranslator(
        sourceLanguage: srcLang,
        targetLanguage: tgtLang,
      );

      final out = await _translator!.translateText(text);

      _cache[cacheKey] = out;
      if (!mounted) return;
      setState(() {
        _translated = out;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _translated = text; // graceful fallback: show original
        _isLoading = false;
      });
    }
  }

  bool _sameLang(String a, String b) {
    String norm(String s) =>
        s.toLowerCase().substring(0, s.length >= 2 ? 2 : 1);
    // Android sometimes returns "in" for Indonesian; normalize to "id".
    final na = norm(a == 'in' ? 'id' : a);
    final nb = norm(b == 'in' ? 'id' : b);
    return na == nb;
  }

  TranslateLanguage? _toTranslateLanguage(String code) {
    switch (code.toLowerCase()) {
      case 'en':
        return TranslateLanguage.english;
      case 'id':
      case 'in': // old Android code for Indonesian
        return TranslateLanguage.indonesian;
      default:
        return null;
    }
  }

  @override
  void dispose() {
    _translator?.close();
    _identifier.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final display = _translated ?? widget.originalText;

    if (_isLoading) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              display,
              style:
                  widget.style?.copyWith(color: Colors.black54) ??
                  const TextStyle(color: Colors.black54),
              maxLines: widget.maxLines,
              softWrap: widget.softWrap,
              textAlign: widget.textAlign,
              overflow: TextOverflow.fade,
            ),
          ),
          const SizedBox(width: 6),
          const SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ],
      );
    }

    return Text(
      display,
      style: widget.style,
      maxLines: widget.maxLines,
      softWrap: widget.softWrap,
      textAlign: widget.textAlign,
    );
  }
}
