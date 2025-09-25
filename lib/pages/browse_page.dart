import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../i18n.dart';
import '../language_provider.dart';
import 'category_browse_page.dart';

class BrowsePage extends StatefulWidget {
  const BrowsePage({super.key});

  @override
  State<BrowsePage> createState() => _BrowsePageState();
}

class _BrowsePageState extends State<BrowsePage> {
  // Base (English) list. We’ll translate labels at build time with tr().
  final List<Map<String, dynamic>> allCategories = [
    {
      'title': 'Wellness 🧘',
      'subcategories': ['Massage', 'Bodywork', 'Healers & Mindful Practices'],
    },
    {
      'title': 'Fitness 💪',
      'subcategories': [
        'Gyms / Weight Training',
        'CrossFit',
        'Boxing / MMA',
        'Calisthenics',
        'Yoga',
        'Pilates',
        'Aerials',
      ],
    },
    {
      'title': 'Food & Drink 🍽',
      'subcategories': [
        '▶️ By Cuisine',
        'Indonesian',
        'Italian',
        'Mexican',
        'Japanese',
        'Chinese',
        'Indian',
        'Middle Eastern',
        'Western / American',
        'Vegan / Plant-Based',
        'Fusion / Contemporary',
        '▶️ By Style',
        'Warung',
        'Fine Dining',
        'Street Food',
        'Dessert & Bakeries',
        'Cafes & Coffee',
        'Smoothies & Juice Bars',
        'Beachfront Restaurants',
        'Late-Night Eats',
        'All-You-Can-Eat',
      ],
    },
    {
      'title': 'Beauty 💅',
      'subcategories': [
        'Hair',
        'Nails',
        'Lashes & Brows',
        'Waxing & Sugaring',
        'Laser & Skin',
        'Injectables / Aesthetics',
        'Facials / Skincare',
      ],
    },
    {
      'title': 'Shopping 🛖',
      'subcategories': [
        'Boutiques',
        'Jewelry',
        'Art & Home Decor',
        'Markets & Souvenirs',
        'Malls',
      ],
    },
    {
      'title': 'Experiences 🌴',
      'subcategories': [
        'Surf Lessons',
        'Cooking Classes',
        'ATV / Adventure Tours',
        'Temple Visits',
        'Selfie Museums / Studios',
        'Waterfalls & Nature Walks',
        'Horseback Riding',
        'Unique Rides / Views',
      ],
    },
    {
      'title': 'Nightlife 🎉',
      'subcategories': [
        'Beach Clubs',
        'Bars & Lounges',
        'Dance Clubs',
        'Late-Night Eateries',
      ],
    },
    {
      'title': 'Services 🚠',
      'subcategories': [
        'Coworking Spaces',
        'SIM Cards & Phone Services',
        'Tech Repair',
        'Scooter Rental',
        'Transportation / Drivers',
        'Laundry & Dry Cleaning',
        'Visa & Immigration Help',
        'Tailors & Alterations',
        'Banks & ATMs',
      ],
    },
    {
      'title': 'Stay 🏡',
      'subcategories': ['Hotels', 'Hostels'],
    },
    {'title': 'Tattoos 🕋', 'subcategories': []},
  ];

  String searchQuery = '';

  // 🧼 Utility to strip emojis/symbols from category title (used for navigation param)
  String cleanCategory(String raw) {
    return raw.replaceAll(RegExp(r'[^\w\s/&-]'), '').trim();
  }

  // Simple translation map for subcategory “headers”
  String translateSub(String s, BuildContext ctx) {
    switch (s) {
      case '▶️ By Cuisine':
        return tr(ctx, en: '▶️ By Cuisine', id: '▶️ Masakan');
      case '▶️ By Style':
        return tr(ctx, en: '▶️ By Style', id: '▶️ Gaya');
      default:
        return s; // keep raw subcat names for now (can localize later)
    }
  }

  @override
  Widget build(BuildContext context) {
    final language = context.watch<LanguageProvider>().language;

    // Build a localized copy of the categories for display
    final localized =
        allCategories.map((cat) {
          final title = cat['title'] as String;
          final subs = List<String>.from(
            (cat['subcategories'] as List),
          ); // <-- cast List
          final localizedTitle = title
              .replaceFirst(
                'Wellness',
                tr(context, en: 'Wellness', id: 'Kesehatan'),
              )
              .replaceFirst(
                'Fitness',
                tr(context, en: 'Fitness', id: 'Kebugaran'),
              )
              .replaceFirst(
                'Food & Drink',
                tr(context, en: 'Food & Drink', id: 'Makanan & Minuman'),
              )
              .replaceFirst(
                'Beauty',
                tr(context, en: 'Beauty', id: 'Kecantikan'),
              )
              .replaceFirst(
                'Shopping',
                tr(context, en: 'Shopping', id: 'Belanja'),
              )
              .replaceFirst(
                'Experiences',
                tr(context, en: 'Experiences', id: 'Pengalaman'),
              )
              .replaceFirst(
                'Nightlife',
                tr(context, en: 'Nightlife', id: 'Hiburan Malam'),
              )
              .replaceFirst(
                'Services',
                tr(context, en: 'Services', id: 'Layanan'),
              )
              .replaceFirst('Stay', tr(context, en: 'Stay', id: 'Penginapan'))
              .replaceFirst('Tattoos', tr(context, en: 'Tattoos', id: 'Tato'));
          final localizedSubs =
              subs.map((s) => translateSub(s, context)).toList();

          return {
            'title': localizedTitle,
            'subcategories': localizedSubs,
            // keep a clean English version for query param
            'cleanTitle': cleanCategory(title),
          };
        }).toList();

    final filtered =
        localized.where((cat) {
          final title = (cat['title'] as String).toLowerCase();
          final subcats =
              List<String>.from(
                (cat['subcategories'] as List),
              ).map((s) => s.toLowerCase()).toList(); // <-- cast List
          return title.contains(searchQuery.toLowerCase()) ||
              subcats.any((sub) => sub.contains(searchQuery.toLowerCase()));
        }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(tr(context, en: 'Categories', id: 'Kategori')),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: tr(
                  context,
                  en: 'Search categories...',
                  id: 'Cari kategori...',
                ),
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) => setState(() => searchQuery = value),
            ),
          ),
          Expanded(
            child:
                filtered.isEmpty
                    ? Center(
                      child: Text(
                        tr(
                          context,
                          en: 'No categories found.',
                          id: 'Kategori tidak ditemukan.',
                        ),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                        ),
                      ),
                    )
                    : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 3 / 2,
                          ),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final category = filtered[index];
                        final displayTitle = category['title'] as String;
                        final subcategories = List<String>.from(
                          (category['subcategories'] as List), // <-- cast List
                        );
                        final cleanTitle = category['cleanTitle'] as String;

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => CategoryBrowsePage(
                                      category:
                                          cleanTitle, // clean base for queries
                                      subcategories: subcategories,
                                      language: language,
                                    ),
                              ),
                            );
                          },
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 4,
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text(
                                  displayTitle,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
