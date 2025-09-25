import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../i18n.dart';
import '../language_provider.dart';
import '../subcategory_locale.dart'; // 👈 add this
import 'filtered_business_list_page.dart';

class CategoryBrowsePage extends StatefulWidget {
  final String category;
  final List<String> subcategories; // English base values
  final String language;

  const CategoryBrowsePage({
    super.key,
    required this.category,
    required this.subcategories,
    required this.language,
  });

  @override
  State<CategoryBrowsePage> createState() => _CategoryBrowsePageState();
}

class _CategoryBrowsePageState extends State<CategoryBrowsePage> {
  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';
  bool showCuisine = true;

  // Food “By Cuisine” and “By Style” stay as EN keys;
  // we'll localize labels via subLabel(ctx, key)
  final cuisineKeys = const [
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
  ];

  final styleKeys = const [
    'Warung',
    'Fine Dining',
    'Street Food',
    'Dessert & Bakeries',
    'Cafes & Coffee',
    'Smoothies & Juice Bars',
    'Beachfront Restaurants',
    'Late-Night Eats',
    'All-You-Can-Eat',
  ];

  String cleanCategory(String raw) {
    return raw.replaceAll(RegExp(r'[^\w\s/&-]'), '').trim();
  }

  @override
  void initState() {
    super.initState();
    if (widget.subcategories.isEmpty) {
      Future.microtask(() {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (_) => FilteredBusinessListPage(
                  category: cleanCategory(widget.category),
                  subcategory: cleanCategory(widget.category),
                  selectedLanguage: widget.language,
                ),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isIndo = context.watch<LanguageProvider>().isIndo;
    final categoryLower = widget.category.toLowerCase();
    final isFood =
        categoryLower.contains('food') || categoryLower.contains('makanan');

    // Build the list of maps { key: EN, label: localized-for-display }
    List<Map<String, String>> currentList;
    if (isFood) {
      final baseKeys = showCuisine ? cuisineKeys : styleKeys;
      currentList =
          baseKeys
              .map((k) => {'key': k, 'label': subLabel(context, k)})
              .toList();
    } else {
      currentList =
          widget.subcategories
              .map((k) => {'key': k, 'label': subLabel(context, k)})
              .toList();
    }

    // Search against the label in the current language
    final filteredList =
        currentList.where((m) {
          final label = (m['label'] ?? '').toLowerCase();
          return label.contains(searchQuery.toLowerCase());
        }).toList();

    final cleanCat = cleanCategory(widget.category);

    return Scaffold(
      appBar: AppBar(title: Text(widget.category)),
      body:
          widget.subcategories.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (isFood)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ChoiceChip(
                            label: Text(
                              tr(context, en: 'By Cuisine', id: 'Masakan'),
                            ),
                            selected: showCuisine,
                            onSelected:
                                (_) => setState(() => showCuisine = true),
                            selectedColor: Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(.12),
                            labelStyle: TextStyle(
                              color:
                                  showCuisine
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(width: 12),
                          ChoiceChip(
                            label: Text(
                              tr(context, en: 'By Style', id: 'Gaya'),
                            ),
                            selected: !showCuisine,
                            onSelected:
                                (_) => setState(() => showCuisine = false),
                            selectedColor: Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(.12),
                            labelStyle: TextStyle(
                              color:
                                  !showCuisine
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: tr(
                          context,
                          en: 'Search subcategories...',
                          id: 'Cari subkategori...',
                        ),
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (value) => setState(() => searchQuery = value),
                    ),
                    const SizedBox(height: 16),
                    filteredList.isEmpty
                        ? Text(
                          tr(
                            context,
                            en: 'No subcategories found.',
                            id: 'Tidak ada subkategori ditemukan.',
                          ),
                        )
                        : Expanded(
                          child: GridView.builder(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 12,
                                  crossAxisSpacing: 12,
                                  childAspectRatio: 1,
                                ),
                            itemCount: filteredList.length,
                            itemBuilder: (context, index) {
                              final map = filteredList[index];
                              final key = map['key']!;
                              final label = map['label']!;

                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => FilteredBusinessListPage(
                                            category: cleanCat,
                                            subcategory:
                                                key, // EN key for query
                                            selectedLanguage:
                                                isIndo ? 'id' : 'en',
                                          ),
                                    ),
                                  );
                                },
                                child: Card(
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Text(
                                        label, // Localized label for display
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 14,
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
              ),
    );
  }
}
