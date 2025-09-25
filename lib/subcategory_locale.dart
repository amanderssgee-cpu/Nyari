// lib/subcategory_locale.dart
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'language_provider.dart';

/// Returns a localized label for a subcategory key (English base).
/// Keep using EN keys for queries; show localized label in UI.
String subLabel(BuildContext ctx, String key) {
  final isIndo = ctx.read<LanguageProvider>().isIndo;
  if (!isIndo) return key;

  // 🔤 English key -> Indonesian label
  const idMap = <String, String>{
    // --- Wellness ---
    'Massage': 'Pijat',
    'Bodywork': 'Bodywork',
    'Healers & Mindful Practices': 'Penyembuhan & Praktik Mindfulness',

    // --- Fitness ---
    'Gyms / Weight Training': 'Gym / Angkat Beban',
    'CrossFit': 'CrossFit',
    'Boxing / MMA': 'Tinju / MMA',
    'Calisthenics': 'Kalistenik',
    'Yoga': 'Yoga',
    'Pilates': 'Pilates',
    'Aerials': 'Aerial',

    // --- Food (By Cuisine) ---
    'Indonesian': 'Masakan Indonesia',
    'Italian': 'Italia',
    'Mexican': 'Meksiko',
    'Japanese': 'Jepang',
    'Chinese': 'Tiongkok',
    'Indian': 'India',
    'Middle Eastern': 'Timur Tengah',
    'Western / American': 'Barat / Amerika',
    'Vegan / Plant-Based': 'Vegan / Nabati',
    'Fusion / Contemporary': 'Fusi / Kontemporer',

    // --- Food (By Style) ---
    'Warung': 'Warung',
    'Fine Dining': 'Fine Dining',
    'Street Food': 'Kaki Lima',
    'Dessert & Bakeries': 'Dessert & Toko Roti',
    'Cafes & Coffee': 'Kafe & Kopi',
    'Smoothies & Juice Bars': 'Smoothies & Bar Jus',
    'Beachfront Restaurants': 'Restoran Tepi Pantai',
    'Late-Night Eats': 'Makan Larut Malam',
    'All-You-Can-Eat': 'Prasmanan / AYCE',

    // --- Beauty ---
    'Hair': 'Rambut',
    'Nails': 'Kuku',
    'Lashes & Brows': 'Bulu Mata & Alis',
    'Waxing & Sugaring': 'Waxing & Sugaring',
    'Laser & Skin': 'Laser & Kulit',
    'Injectables / Aesthetics': 'Suntik / Estetika',
    'Facials / Skincare': 'Perawatan Wajah / Skincare',

    // --- Shopping ---
    'Boutiques': 'Butik',
    'Jewelry': 'Perhiasan',
    'Art & Home Decor': 'Seni & Dekorasi Rumah',
    'Markets & Souvenirs': 'Pasar & Suvenir',
    'Malls': 'Mal',

    // --- Experiences ---
    'Surf Lessons': 'Les Selancar',
    'Cooking Classes': 'Kelas Memasak',
    'ATV / Adventure Tours': 'ATV / Tur Petualangan',
    'Temple Visits': 'Kunjungan Pura',
    'Selfie Museums / Studios': 'Museum/Studio Selfie',
    'Waterfalls & Nature Walks': 'Air Terjun & Jalan Alam',
    'Horseback Riding': 'Berkuda',
    'Unique Rides / Views': 'Wahana / Pemandangan Unik',

    // --- Nightlife ---
    'Beach Clubs': 'Klub Pantai',
    'Bars & Lounges': 'Bar & Lounge',
    'Dance Clubs': 'Klub Dansa',
    'Late-Night Eateries': 'Kuliner Larut Malam',

    // --- Services ---
    'Coworking Spaces': 'Ruang Kerja Bersama',
    'SIM Cards & Phone Services': 'Kartu SIM & Layanan Telepon',
    'Tech Repair': 'Servis Teknologi',
    'Scooter Rental': 'Sewa Skuter',
    'Transportation / Drivers': 'Transportasi / Sopir',
    'Laundry & Dry Cleaning': 'Laundry & Cuci Kering',
    'Visa & Immigration Help': 'Bantuan Visa & Imigrasi',
    'Tailors & Alterations': 'Penjahit & Permak',
    'Banks & ATMs': 'Bank & ATM',

    // --- Stay ---
    'Hotels': 'Hotel',
    'Hostels': 'Hostel',
  };

  return idMap[key] ?? key;
}
