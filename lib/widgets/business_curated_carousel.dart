import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/photo_service.dart';
import '../pages/business_photos_page.dart';

class BusinessCuratedCarousel extends StatelessWidget {
  final String businessId;
  const BusinessCuratedCarousel({super.key, required this.businessId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: PhotoService.curatedPhotosStream(businessId, limit: 5),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 180,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final items = snap.data ?? const [];
        if (items.isEmpty) {
          return Container(
            height: 140,
            alignment: Alignment.center,
            child: Text('No photos yet',
                style: Theme.of(context).textTheme.bodyMedium),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 220,
              child: PageView.builder(
                controller: PageController(viewportFraction: 0.88),
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final url = (items[i]['url'] ?? '') as String;
                  final caption = (items[i]['caption'] ?? '') as String;
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CachedNetworkImage(
                            imageUrl: url,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => const Center(
                                child: CircularProgressIndicator()),
                            errorWidget: (_, __, ___) =>
                                const Center(child: Icon(Icons.broken_image)),
                          ),
                          if (caption.isNotEmpty)
                            Align(
                              alignment: Alignment.bottomLeft,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                color: Colors.black54,
                                child: Text(
                                  caption,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          BusinessPhotosPage(businessId: businessId),
                    ),
                  );
                },
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('See all photos'),
              ),
            ),
          ],
        );
      },
    );
  }
}
