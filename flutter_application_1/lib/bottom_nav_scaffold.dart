import 'package:flutter/material.dart';
import 'dart:ui';
import 'pages/home_page.dart';
import 'pages/menu_page.dart';
import 'pages/search_page.dart';

class NavBar extends StatelessWidget {
  final void Function(int) onItemTapped;
  const NavBar({required this.onItemTapped, super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: <Widget>[
        IconButton(
          icon: const Icon(Icons.home),
          onPressed: () => onItemTapped(0),
          color: Theme.of(context).colorScheme.primary,
        ),
        IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => onItemTapped(1),
          color: null,
        ),
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () => onItemTapped(2),
          color: null,
        ),
      ],
    );
  }
}

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
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;
    final barWidth = isMobile ? width - 24 : width * 0.5;
    final barRadius = isMobile ? 32.0 : 48.0;
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          const HomePage(),
          // Floating glass nav bar at the top
          Positioned(
            top: isMobile ? 16 : 32,
            left: (width - barWidth) / 2,
            child: SizedBox(
              width: barWidth,
              child: Stack(
                children: [
                  // Iridescent gradient border overlay
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(barRadius),
                          border: Border.all(
                            width: 2.5,
                            style: BorderStyle.solid,
                            color: Colors.transparent,
                          ),
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFFff3b3b).withOpacity(0.45), // red
                              Color(0xFF3bff3b).withOpacity(0.45), // green
                              Color(0xFF3b3bff).withOpacity(0.45), // blue
                              Color(0xFFff3bff).withOpacity(0.35), // magenta
                              Color(0xFF3bffff).withOpacity(0.35), // cyan
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                    ),
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(barRadius),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: isMobile ? 10 : 18, horizontal: isMobile ? 16 : 32),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.60),
                          borderRadius: BorderRadius.circular(barRadius),
                          boxShadow: [
                            // Stronger RGB edge effect, layered
                            BoxShadow(
                              color: const Color(0xFFff3b3b).withOpacity(0.32), // red
                              blurRadius: 16,
                              spreadRadius: 1.5,
                              offset: const Offset(-3, 3),
                            ),
                            BoxShadow(
                              color: const Color(0xFF3bff3b).withOpacity(0.32), // green
                              blurRadius: 16,
                              spreadRadius: 1.5,
                              offset: const Offset(3, 3),
                            ),
                            BoxShadow(
                              color: const Color(0xFF3b3bff).withOpacity(0.32), // blue
                              blurRadius: 16,
                              spreadRadius: 1.5,
                              offset: const Offset(0, -3),
                            ),
                            // Subtle magenta/cyan for realism
                            BoxShadow(
                              color: const Color(0xFFff3bff).withOpacity(0.18), // magenta
                              blurRadius: 12,
                              spreadRadius: 0.5,
                              offset: const Offset(-2, -2),
                            ),
                            BoxShadow(
                              color: const Color(0xFF3bffff).withOpacity(0.18), // cyan
                              blurRadius: 12,
                              spreadRadius: 0.5,
                              offset: const Offset(2, -2),
                            ),
                            // Soft shadow
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 20,
                              offset: Offset(0, 6),
                            ),
                          ],
                          border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
                        ),
                        child: NavBar(onItemTapped: _onItemTapped),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}