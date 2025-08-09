import 'package:flutter/material.dart';
import 'dart:ui';
import 'pages/home_page.dart';
import 'pages/menu_page.dart';
import 'pages/search_page.dart';

class BottomNavScaffold extends StatefulWidget {
  const BottomNavScaffold({super.key});

  @override
  State<BottomNavScaffold> createState() => _BottomNavScaffoldState();
}

class _BottomNavScaffoldState extends State<BottomNavScaffold> {
  void _onItemTapped(int index) async {
    if (index == 1) {
      // Menu: show as modal bottom sheet
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return const MenuPage();
        },
        transitionAnimationController: AnimationController(
          vsync: Navigator.of(context),
          duration: const Duration(milliseconds: 350),
        ),
      );
    } else if (index == 2) {
      // Search: show as modal bottom sheet
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return const SearchPage();
        },
        transitionAnimationController: AnimationController(
          vsync: Navigator.of(context),
          duration: const Duration(milliseconds: 350),
        ),
      );
    }
    // Home (index 0) does nothing, HomePage is always shown
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // This lets the bar float above the body
      body: Stack(
        children: [
          const HomePage(),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24), // More bottom padding for floating effect
              child: Container(
                width: MediaQuery.of(context).size.width * 0.30, // 1/4 of screen width
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(60),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: BottomAppBar(
                  color: Colors.transparent,
                  elevation: 0,
                  shape: const CircularNotchedRectangle(),
                  notchMargin: 8.0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: <Widget>[
                      IconButton(
                        icon: const Icon(Icons.home),
                        onPressed: () => _onItemTapped(0),
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      IconButton(
                        icon: const Icon(Icons.menu),
                        onPressed: () => _onItemTapped(1),
                        color: null,
                      ),
                      IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: () => _onItemTapped(2),
                        color: null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}