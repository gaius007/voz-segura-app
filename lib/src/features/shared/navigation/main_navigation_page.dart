import 'dart:ui';
import 'package:flutter/material.dart';
import '../../reports/presentation/pages/report_list_page.dart';
import '../../reports/presentation/pages/report_create_page.dart';
import '../../sos/presentation/home_page.dart';
import '../../contacts/presentation/emergency_contacts_page.dart';
import '../../settings/presentation/settings_page.dart';
import '../../map/presentation/pages/security_map_page.dart';
import 'package:voz_segura_app/src/core/theme/app_theme.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _indice = 0;

  final List<Widget> _telas = [
    const HomePage(),
    const ReportListPage(),
    const EmergencyContactsPage(),
    const SecurityMapPage(),
    const SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Crucial for glass navigation effect
      body: Stack(
        children: [
          // Background Gradient base (theme-aware)
          Container(
            decoration: BoxDecoration(
              gradient: context.appBackgroundGradient,
            ),
          ),
          // Content
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.05, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: _telas[_indice],
          ),
        ],
      ),
      
      floatingActionButton: _indice == 1 
        ? FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ReportCreatePage()),
              );
            },
            backgroundColor: context.appPrimary,
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: const Icon(Icons.add_photo_alternate_rounded, color: Colors.white),
          )
        : null,
      
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                height: 75,
                decoration: BoxDecoration(
                  color: context.appGlassColor,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: context.appGlassBorder),
                  boxShadow: [
                    BoxShadow(
                      color: context.isDark
                          ? Colors.black.withOpacity(0.3)
                          : Colors.pink.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(0, Icons.home_rounded, 'Home'),
                    _buildNavItem(1, Icons.assignment_rounded, 'Relatos'),
                    _buildNavItem(2, Icons.people_rounded, 'Contatos'),
                    _buildNavItem(3, Icons.map_rounded, 'Mapa'),
                    _buildNavItem(4, Icons.settings_rounded, 'Ajustes'),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    bool selected = _indice == index;
    return GestureDetector(
      onTap: () => setState(() => _indice = index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? context.appPrimary.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              icon,
              color: selected
                  ? context.appPrimary
                  : (context.isDark ? Colors.grey.shade600 : Colors.grey.shade400),
              size: 28,
            ),
          ),
          if (selected)
            Container(
              margin: const EdgeInsets.only(top: 4),
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: context.appPrimary,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}
