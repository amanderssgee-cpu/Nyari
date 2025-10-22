import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/photo_service.dart';

class BusinessPhotosPage extends StatelessWidget {
  final String businessId;
  const BusinessPhotosPage({super.key, required this.businessId});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Photos'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Curated'),
              Tab(text: 'Community'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _CuratedGrid(businessId: businessId),
            _CommunityGrid(businessId: businessId),
          ],
        ),
      ),
    );
  }
}

class _CuratedGrid extends StatelessWidget {
  final String businessId;
  const _CuratedGrid({required this.businessId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: PhotoService.curatedPhotosStream(businessId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snap.data ?? const [];
        if (items.isEmpty) {
          return const Center(child: Text('No curated photos yet'));
        }
        return _grid(items.map((m) => (m['url'] as String?) ?? '').toList());
      },
    );
  }
}

class _CommunityGrid extends StatelessWidget {
  final String businessId;
  const _CommunityGrid({required this.businessId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<String>>(
      stream: PhotoService.communityPhotoUrlsStream(businessId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final urls = snap.data ?? const [];
        if (urls.isEmpty) {
          return const Center(child: Text('No community photos yet'));
        }
        return _grid(urls);
      },
    );
  }
}

Widget _grid(List<String> urls) {
  return GridView.builder(
    padding: const EdgeInsets.all(12),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 3,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
    ),
    itemCount: urls.length,
    itemBuilder: (_, i) {
      final url = urls[i];
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.cover,
          placeholder: (_, __) =>
              const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          errorWidget: (_, __, ___) =>
              const Center(child: Icon(Icons.broken_image)),
        ),
      );
    },
  );
}
