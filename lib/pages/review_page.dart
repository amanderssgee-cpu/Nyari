import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:google_mlkit_language_id/google_mlkit_language_id.dart';

import '../language_provider.dart';
import '../i18n.dart';

class ReviewPage extends StatefulWidget {
  final String businessId;
  final String selectedLanguage; // kept for back-compat; we also read provider

  const ReviewPage({
    super.key,
    required this.businessId,
    required this.selectedLanguage,
  });

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  double _rating = 3;
  final _commentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  final _langId = LanguageIdentifier(confidenceThreshold: 0.5);

  @override
  void dispose() {
    _commentController.dispose();
    _langId.close();
    super.dispose();
  }

  Future<void> _submitReview() async {
    final user = FirebaseAuth.instance.currentUser;
    final isIndo = context.read<LanguageProvider>().isIndo;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              context,
              en: 'You must be signed in to leave a review.',
              id: 'Kamu harus masuk untuk menulis ulasan.',
            ),
          ),
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final rawComment = _commentController.text.trim();
    if (rawComment.isEmpty) return;

    setState(() => _isSubmitting = true);

    // Build initials & name
    String reviewerName = user.displayName?.trim() ?? '';
    String initials = '';
    if (reviewerName.isNotEmpty) {
      final parts = reviewerName.split(RegExp(r'\s+'));
      if (parts.length >= 2) {
        initials =
            (parts[0].isNotEmpty ? parts[0][0] : '') +
            (parts[1].isNotEmpty ? parts[1][0] : '');
      } else {
        initials = parts[0].isNotEmpty ? parts[0][0] : '';
      }
    } else if (user.email != null && user.email!.isNotEmpty) {
      initials = user.email![0].toUpperCase();
    }
    initials = initials.toUpperCase();

    // Detect the comment language (fallback to UI toggle if undetermined)
    String detectedLang = 'und';
    try {
      detectedLang = await _langId.identifyLanguage(rawComment); // "en", "id"
    } catch (_) {
      /* ignore, fallback below */
    }

    String langCode;
    if (detectedLang == 'en' || detectedLang == 'id' || detectedLang == 'in') {
      langCode = (detectedLang == 'in') ? 'id' : detectedLang;
    } else {
      langCode = isIndo ? 'id' : 'en';
    }

    // Prepare fields (match your Firestore rules!)
    final Map<String, dynamic> reviewData = {
      'rating': _rating, // number 1..5
      'comment': rawComment, // legacy fallback
      'lang': langCode,
      'timestamp': FieldValue.serverTimestamp(),
      'initials': initials,
      'reviewerName': reviewerName,
      'reviewerEmail': user.email,

      // ✅ KEY FIX: rules expect userId (not uid)
      'userId': user.uid,

      // keep if your rules check businessId == path bizId
      'businessId': widget.businessId,
    };

    // Bilingual comment fields
    if (langCode == 'id') {
      reviewData['comment_id'] = rawComment;
    } else {
      reviewData['comment_en'] = rawComment;
    }

    try {
      final reviewsRef = FirebaseFirestore.instance
          .collection('businesses')
          .doc(widget.businessId)
          .collection('reviews');

      await reviewsRef.add(reviewData);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(context, en: 'Review submitted ✅', id: 'Ulasan terkirim ✅'),
          ),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              context,
              en: 'Failed to submit review.',
              id: 'Gagal mengirim ulasan.',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isIndo = context.watch<LanguageProvider>().isIndo;

    final labels = [
      tr(context, en: 'Very Bad', id: 'Sangat Buruk'),
      tr(context, en: 'Bad', id: 'Buruk'),
      tr(context, en: 'Okay', id: 'Biasa'),
      tr(context, en: 'Good', id: 'Bagus'),
      tr(context, en: 'Great', id: 'Luar Biasa'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(tr(context, en: 'Write a Review', id: 'Tulis Ulasan')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  tr(context, en: 'Your Rating', id: 'Penilaian Anda'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Slider(
                value: _rating,
                onChanged: (val) => setState(() => _rating = val),
                min: 1,
                max: 5,
                divisions: 4,
                label: labels[_rating.round() - 1],
                activeColor: const Color(0xFF201E50),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  labels[_rating.round() - 1],
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _commentController,
                maxLines: 4,
                maxLength: 1000,
                decoration: InputDecoration(
                  hintText: tr(
                    context,
                    en: 'Write your comment here...',
                    id: 'Tulis komentar Anda di sini...',
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (val) {
                  final v = (val ?? '').trim();
                  if (v.isEmpty) {
                    return tr(
                      context,
                      en: 'Please enter a comment.',
                      id: 'Silakan tulis komentar.',
                    );
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitReview,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF201E50),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child:
                      _isSubmitting
                          ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                          : Text(tr(context, en: 'Submit', id: 'Kirim')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
