// lib/pages/review_page.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:google_mlkit_language_id/google_mlkit_language_id.dart';
import 'package:confetti/confetti.dart';
import '../language_provider.dart';
import '../i18n.dart';

class ReviewPage extends StatefulWidget {
  final String businessId;
  final String selectedLanguage; // kept for back-compat

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

  // 🎉 Confetti (hearts)
  late final ConfettiController _confetti =
      ConfettiController(duration: const Duration(seconds: 2));

  @override
  void dispose() {
    _commentController.dispose();
    _langId.close();
    _confetti.dispose();
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
        initials = (parts[0].isNotEmpty ? parts[0][0] : '') +
            (parts[1].isNotEmpty ? parts[1][0] : '');
      } else {
        initials = parts[0].isNotEmpty ? parts[0][0] : '';
      }
    } else if (user.email != null && user.email!.isNotEmpty) {
      initials = user.email![0].toUpperCase();
    }
    initials = initials.toUpperCase();

    // Detect language of the comment (fallback to UI language)
    String detectedLang = 'und';
    try {
      detectedLang = await _langId.identifyLanguage(rawComment); // "en", "id"
    } catch (_) {}
    String langCode;
    if (detectedLang == 'en' || detectedLang == 'id' || detectedLang == 'in') {
      langCode = (detectedLang == 'in') ? 'id' : detectedLang;
    } else {
      langCode = isIndo ? 'id' : 'en';
    }

    // Base review data
    final Map<String, dynamic> reviewData = {
      'rating': _rating,
      'comment': rawComment,
      'lang': langCode,
      'timestamp': FieldValue.serverTimestamp(), // createdAt (immutable)
      'initials': initials,
      'reviewerName': reviewerName,
      'reviewerEmail': user.email,
      'uid': user.uid,
      'userId': user.uid,
      'businessId': widget.businessId,
    };

    // Bilingual copies
    if (langCode == 'id') {
      reviewData['comment_id'] = rawComment;
    } else {
      reviewData['comment_en'] = rawComment;
    }

    try {
      final db = FirebaseFirestore.instance;
      final docRef = db
          .collection('businesses')
          .doc(widget.businessId)
          .collection('reviews')
          .doc(user.uid); // one-per-user-per-business

      await db.runTransaction((tx) async {
        final snap = await tx.get(docRef);
        if (snap.exists) {
          final prev = snap.data() as Map<String, dynamic>;
          final updated = Map<String, dynamic>.from(reviewData)
            ..remove('timestamp') // keep original
            ..['updatedAt'] = FieldValue.serverTimestamp()
            ..['edited'] = true;

          final historyEntry = {
            'rating': prev['rating'],
            'comment': prev['comment'],
            'imageUrls': prev['imageUrls'] ?? [],
            'timestamp': prev['timestamp'],
            'updatedAt': prev['updatedAt'],
            'reviewerName': prev['reviewerName'],
            'reviewerEmail': prev['reviewerEmail'],
          };
          updated['history'] = FieldValue.arrayUnion([historyEntry]);

          tx.update(docRef, updated);
        } else {
          final first = {
            ...reviewData,
            'updatedAt': FieldValue.serverTimestamp(),
            'edited': false,
            'history': [],
            'imageUrls': <String>[],
          };
          tx.set(docRef, first);
        }
      });

      if (!mounted) return;

      // Fire confetti and show Thank You screen
      _confetti.play();
      await Navigator.push(
        context,
        PageRouteBuilder(
          opaque: false,
          barrierColor: Colors.black54,
          pageBuilder: (_, __, ___) => ThankYouScreen(
            onDone: () => Navigator.pop(context), // close thank-you
          ),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      );

      Navigator.pop(context); // leave review page
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

  // ❤️ custom heart path for confetti particles
  Path _heartPath(Size size) {
    final Path path = Path();
    final w = size.width;
    final h = size.height;
    final s = min(w, h);
    final r = s / 4;

    path.moveTo(s / 2, s / 1.25);
    path.cubicTo(s * 0.2, s * 0.9, s * 0.0, s * 0.55, s * 0.25, s * 0.35);
    path.cubicTo(s * 0.4, s * 0.2, s * 0.6, s * 0.2, s * 0.75, s * 0.35);
    path.cubicTo(s, s * 0.55, s * 0.8, s * 0.9, s / 2, s / 1.25);
    path.close();
    return path;
  }

  @override
  Widget build(BuildContext context) {
    final labels = [
      tr(context, en: 'Very Bad', id: 'Sangat Buruk'),
      tr(context, en: 'Bad', id: 'Buruk'),
      tr(context, en: 'Okay', id: 'Biasa'),
      tr(context, en: 'Good', id: 'Bagus'),
      tr(context, en: 'Great', id: 'Luar Biasa'),
    ];

    // 💖 Hearts set
    final hearts = ['💔', '💙', '💜', '💛', '❤️‍🔥'];

    return Stack(
      children: [
        Scaffold(
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
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Slider
                  Slider(
                    value: _rating,
                    onChanged: (val) => setState(() => _rating = val),
                    min: 1,
                    max: 5,
                    divisions: 4,
                    label: labels[_rating.round() - 1],
                    activeColor: const Color(0xFF201E50),
                  ),

                  // Label + Heart emoji
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        labels[_rating.round() - 1],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 150),
                        transitionBuilder: (c, a) =>
                            ScaleTransition(scale: a, child: c),
                        child: Text(
                          hearts[_rating.round() - 1],
                          key: ValueKey(_rating.round()),
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Comment
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

                  // Submit
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitReview,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF201E50),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                      child: _isSubmitting
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
        ),

        // 🎉 Heart confetti layer (center burst)
        Align(
          alignment: Alignment.center,
          child: ConfettiWidget(
            confettiController: _confetti,
            blastDirectionality: BlastDirectionality.explosive,
            maxBlastForce: 30,
            minBlastForce: 10,
            emissionFrequency: 0.02,
            numberOfParticles: 18,
            gravity: 0.6,
            createParticlePath: (size) => _heartPath(size),
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Thank-you overlay
class ThankYouScreen extends StatelessWidget {
  final VoidCallback onDone;
  const ThankYouScreen({super.key, required this.onDone});

  @override
  Widget build(BuildContext context) {
    final isIndo = context.read<LanguageProvider>().isIndo;
    return Scaffold(
      backgroundColor: const Color(0xFF201E50),
      body: SafeArea(
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 18,
                  color: Colors.black26,
                  offset: Offset(0, 8),
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('❤️', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 8),
                Text(
                  isIndo ? 'Terima kasih!' : 'Thank you!',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isIndo
                      ? 'Ulasanmu membantu orang lain menemukan tempat yang hebat.'
                      : 'Your review helps others find great places.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black54, height: 1.3),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onDone,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF201E50),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(isIndo ? 'Selesai' : 'Done'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
