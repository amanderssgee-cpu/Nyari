import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/photo_service.dart';

class CuratedPhotoAdminPage extends StatefulWidget {
  final String businessId;
  final List<String> allowedAdminEmails;
  const CuratedPhotoAdminPage({
    super.key,
    required this.businessId,
    required this.allowedAdminEmails,
  });

  @override
  State<CuratedPhotoAdminPage> createState() => _CuratedPhotoAdminPageState();
}

class _CuratedPhotoAdminPageState extends State<CuratedPhotoAdminPage> {
  final _urlCtrl = TextEditingController();
  final _captionCtrl = TextEditingController();
  final _priorityCtrl = TextEditingController(text: '100');

  bool get _isAllowed {
    final email = FirebaseAuth.instance.currentUser?.email?.toLowerCase() ?? '';
    return widget.allowedAdminEmails
        .map((e) => e.toLowerCase())
        .contains(email);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAllowed) {
      return Scaffold(
        appBar: AppBar(title: const Text('Admin')),
        body: const Center(child: Text('Not authorized')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Add Curated Photo')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _urlCtrl,
            decoration: const InputDecoration(
              labelText: 'Download URL (https://...)',
              hintText: 'Paste Firebase Storage download URL here',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _captionCtrl,
            decoration: const InputDecoration(labelText: 'Caption (optional)'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _priorityCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
                labelText: 'Priority (lower shows earlier)'),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () async {
              final url = _urlCtrl.text.trim();
              if (url.isEmpty) return;

              final p = int.tryParse(_priorityCtrl.text.trim());
              await PhotoService.addCuratedPhotoFromUrl(
                businessId: widget.businessId,
                url: url,
                caption: _captionCtrl.text.trim().isEmpty
                    ? null
                    : _captionCtrl.text.trim(),
                priority: p,
              );

              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Curated photo added')),
              );
              _urlCtrl.clear();
              _captionCtrl.clear();
              _priorityCtrl.text = '100';
            },
            child: const Text('Save'),
          ),
          const SizedBox(height: 24),
          const Text(
              'Tip: Upload files in Firebase Storage Console, copy the download URL, paste here.'),
        ],
      ),
    );
  }
}
