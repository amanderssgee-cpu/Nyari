import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:url_launcher/url_launcher.dart';

import '../language_provider.dart';
import '../i18n.dart';
import 'review_page.dart';
import '../services/translation_service.dart';

class BusinessProfilePage extends StatelessWidget {
  final String businessId;
  final Map<String, dynamic>? businessData; // optional pre-fetched doc

  const BusinessProfilePage({
    super.key,
    required this.businessId,
    this.businessData,
  });

  @override
  Widget build(BuildContext context) {
    final isIndo = context.watch<LanguageProvider>().isIndo;

    if (businessData != null) {
      return _ScaffoldWithContent(
        businessId: businessId,
        biz: businessData!,
        isIndo: isIndo,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(tr(context, en: 'Business', id: 'Bisnis')),
        backgroundColor: const Color(0xFF201E50),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('businesses')
                .doc(businessId)
                .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData || !snap.data!.exists) {
            return Center(
              child: Text(
                tr(
                  context,
                  en: 'Business not found',
                  id: 'Bisnis tidak ditemukan',
                ),
              ),
            );
          }
          final biz = snap.data!.data() as Map<String, dynamic>;
          return _ScaffoldWithContent(
            businessId: businessId,
            biz: biz,
            isIndo: isIndo,
          );
        },
      ),
    );
  }
}

class _ScaffoldWithContent extends StatelessWidget {
  final String businessId;
  final Map<String, dynamic> biz;
  final bool isIndo;

  const _ScaffoldWithContent({
    required this.businessId,
    required this.biz,
    required this.isIndo,
  });

  String _str(dynamic v) => (v ?? '').toString();
  bool _truthy(dynamic v) {
    if (v is bool) return v;
    if (v is String) return v.toLowerCase() == 'true';
    if (v is num) return v != 0;
    return false;
  }

  Future<void> _launch(Uri uri) async {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _openWebsite(String url) {
    if (url.isEmpty) return;
    final fixed = url.startsWith('http') ? url : 'https://$url';
    _launch(Uri.parse(fixed));
  }

  void _openInstagram(String handleOrUrl) {
    if (handleOrUrl.isEmpty) return;
    final url =
        handleOrUrl.startsWith('http')
            ? handleOrUrl
            : 'https://instagram.com/${handleOrUrl.replaceAll('@', '')}';
    _launch(Uri.parse(url));
  }

  void _openWhatsApp(String phoneOrLink) {
    if (phoneOrLink.isEmpty) return;
    final url =
        phoneOrLink.contains('wa.me')
            ? phoneOrLink
            : 'https://wa.me/${phoneOrLink.replaceAll(RegExp(r'[^0-9+]'), '')}';
    _launch(Uri.parse(url));
  }

  String _fmtAvg(double v) =>
      v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 1);

  @override
  Widget build(BuildContext context) {
    // exact field names from your schema
    final name = _str(biz['name']);
    final imageUrl = _str(biz['imageUrl']);
    final location = _str(biz['location']);
    final hours = _str(biz['hours']);

    // SHOW ONLY AVERAGE (prefer ratingAvg; fallback to rating)
    final double ratingAvg =
        ((biz['ratingAvg'] ?? biz['rating'] ?? 0) as num).toDouble();

    final website = _str(biz['website']);
    final whatsapp = _str(biz['whatsapp']);
    final instagram = _str(biz['instagram']);
    final wifi = _truthy(biz['wifi']);

    // payment methods (support both "payment method" and legacy "v\payment method")
    final List<dynamic> payments = [
      ...(((biz['payment method'] as List?) ?? const [])).cast<dynamic>(),
      ...(((biz['v\\payment method'] as List?) ?? const [])).cast<dynamic>(),
    ];
    final hasCard = payments.any(
      (p) => (p?.toString().toLowerCase() ?? '').contains('card'),
    );
    final hasCash = payments.any(
      (p) => (p?.toString().toLowerCase() ?? '').contains('cash'),
    );

    // description (bilingual fields you already store)
    final descEN = _str(biz['description']);
    final descID = _str(biz['description_id']);
    final showDesc =
        isIndo
            ? (descID.isNotEmpty ? descID : '')
            : (descEN.isNotEmpty ? descEN : '');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          name.isNotEmpty ? name : tr(context, en: 'Business', id: 'Bisnis'),
        ),
        backgroundColor: const Color(0xFF201E50),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header image
            if (imageUrl.isNotEmpty)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(imageUrl, fit: BoxFit.cover),
              ),

            // Title
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Address
            if (location.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 2,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        location,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),

            // Hours
            if (hours.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 2,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(hours, style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),

            // Rating — star + number only (from ratingAvg)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              child: Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    _fmtAvg(ratingAvg),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Action icons: Website • Instagram • WhatsApp
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  if (website.isNotEmpty)
                    _CircleAction(
                      icon: Icons.public,
                      tooltip: tr(context, en: 'Website', id: 'Situs'),
                      onTap: () => _openWebsite(website),
                    ),
                  if (instagram.isNotEmpty)
                    _CircleAction(
                      icon: Icons.photo_camera,
                      tooltip: 'Instagram',
                      onTap: () => _openInstagram(instagram),
                    ),
                  if (whatsapp.isNotEmpty)
                    _CircleAction(
                      icon: Icons.chat_bubble,
                      tooltip: 'WhatsApp',
                      onTap: () => _openWhatsApp(whatsapp),
                    ),
                ],
              ),
            ),

            // Icon pill row: Wi-Fi (blue), Card (blue), Cash (green)
            if (wifi || hasCard || hasCash)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                child: Row(
                  children: [
                    if (wifi)
                      const _IconPill(
                        icon: Icons.wifi,
                        bg: Color(0xFF3B82F6), // blue-500
                        fg: Colors.white,
                      ),
                    if (hasCard)
                      const _IconPill(
                        icon: Icons.credit_card,
                        bg: Color(0xFF3B82F6), // blue-500
                        fg: Colors.white,
                      ),
                    if (hasCash)
                      const _IconPill(
                        icon: Icons.attach_money,
                        bg: Color(0xFF22C55E), // green-500
                        fg: Colors.white,
                      ),
                  ],
                ),
              ),

            const SizedBox(height: 12),

            // Description
            if (showDesc.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  showDesc,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
                    height: 1.35,
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Write a Review
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF201E50),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => ReviewPage(
                              businessId: businessId,
                              selectedLanguage: isIndo ? 'id' : 'en',
                            ),
                      ),
                    );
                  },
                  child: Text(
                    tr(context, en: 'Write a Review', id: 'Tulis Ulasan'),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Latest Reviews
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                tr(context, en: 'Latest Reviews', id: 'Ulasan Terbaru'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),

            StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('businesses')
                      .doc(businessId)
                      .collection('reviews')
                      .orderBy('timestamp', descending: true)
                      .limit(10)
                      .snapshots(),
              builder: (context, revSnap) {
                if (revSnap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                final docs = revSnap.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Text(
                      tr(
                        context,
                        en: 'No reviews yet.',
                        id: 'Belum ada ulasan.',
                      ),
                      style: const TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    return _ReviewTile(data: data);
                  },
                );
              },
            ),

            Center(
              child: TextButton(
                onPressed: () {},
                child: Text(
                  tr(context, en: 'See All Reviews', id: 'Lihat Semua Ulasan'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconPill extends StatelessWidget {
  final IconData icon;
  final Color bg;
  final Color fg;

  const _IconPill({
    required this.icon,
    required this.bg,
    required this.fg,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 16, color: fg),
    );
  }
}

class _CircleAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _CircleAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Tooltip(
          message: tooltip,
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFEDEBFF),
              borderRadius: BorderRadius.circular(21),
            ),
            child: Icon(icon, color: const Color(0xFF201E50)),
          ),
        ),
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final Map<String, dynamic> data;
  const _ReviewTile({required this.data});

  @override
  Widget build(BuildContext context) {
    final isIndoUI = context.watch<LanguageProvider>().isIndo;
    final targetLang = isIndoUI ? 'id' : 'en';

    final rating = ((data['rating'] ?? 0) as num).toDouble();
    final ts = (data['timestamp'] as Timestamp?);
    final initials = (data['initials'] ?? '').toString().toUpperCase();
    final reviewerName = (data['reviewerName'] ?? '').toString();

    // Original text & language from your review doc
    String sourceLang;
    String sourceText;
    if ((data['comment_en'] ?? '').toString().isNotEmpty) {
      sourceLang = 'en';
      sourceText = data['comment_en'];
    } else if ((data['comment_id'] ?? '').toString().isNotEmpty) {
      sourceLang = 'id';
      sourceText = data['comment_id'];
    } else {
      final detected =
          ((data['lang'] ?? 'en') as String) == 'in'
              ? 'id'
              : (data['lang'] ?? 'en');
      sourceLang = (detected == 'id' || detected == 'en') ? detected : 'en';
      sourceText = (data['comment'] ?? '').toString();
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: const Color(0xFFF7F3FF),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: const Color(0xFF201E50),
                  child: Text(
                    (initials.isNotEmpty ? initials : '•'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (reviewerName.isNotEmpty)
                        Text(
                          reviewerName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      Text(
                        ts != null ? timeago.format(ts.toDate()) : '',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: List.generate(
                    5,
                    (i) => Icon(
                      i < rating.round() ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Comment with translation (no fallback)
            if (sourceLang == targetLang)
              Text(sourceText, style: const TextStyle(fontSize: 14))
            else
              FutureBuilder<String>(
                future: TranslationService().translate(
                  text: sourceText,
                  fromCode: sourceLang,
                  toCode: targetLang,
                ),
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    );
                  }
                  if (snap.hasError) {
                    return Text(
                      tr(
                        context,
                        en: 'Translation unavailable.',
                        id: 'Terjemahan tidak tersedia.',
                      ),
                      style: const TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    );
                  }
                  return Text(
                    snap.data ?? '',
                    style: const TextStyle(fontSize: 14),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
