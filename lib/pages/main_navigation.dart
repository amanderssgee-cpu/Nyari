import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../language_provider.dart';
import 'home_with_map_page.dart';
import 'browse_page.dart';
import 'profile_page.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context).language;

    final List<Widget> _widgetOptions = <Widget>[
      const HomeWithMapPage(),
      const BrowsePage(),
      const ProfilePage(),
    ];

    return Scaffold(
      body: _widgetOptions[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color(0xFF201E50),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.category),
            label: 'Categories',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
