import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../reports/presentation/pages/report_list_page.dart';
import '../../reports/presentation/pages/report_create_page.dart';
import '../../sos/presentation/home_page.dart';
import '../../sos/domain/services/location_service.dart';
import '../../contacts/presentation/emergency_contacts_page.dart';
import '../../settings/presentation/settings_page.dart';
import '../../map/presentation/pages/security_map_page.dart';
import 'package:voz_segura_app/src/core/theme/app_theme.dart';
import 'package:voz_segura_app/src/core/widgets/location_permission_dialog.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _indice = 0;

  static const _rationaleShownKey = 'loc_perm_rationale_shown';
  static const _settingsDialogShownKey = 'loc_perm_settings_dialog_shown';

  final List<Widget> _telas = [
    const HomePage(),
    const ReportListPage(),
    const EmergencyContactsPage(),
    const SecurityMapPage(),
    const SettingsPage(),
  ];

  @override
  void initState() {
    super.initState();
    // Pede a permissão de localização logo após o login, para que o SOS
    // não dependa de prompts de permissão na hora da emergência.
    WidgetsBinding.instance.addPostFrameCallback((_) => _requestLocationOnce());
  }

  Future<void> _requestLocationOnce() async {
    final locationService = context.read<LocationService>();
    final prefs = await SharedPreferences.getInstance();

    final status = await locationService.checkPermission();
    if (status == LocationPermission.always ||
        status == LocationPermission.whileInUse) {
      return;
    }

    if (!mounted) return;

    if (status == LocationPermission.deniedForever) {
      // Não importunar a cada abertura — mostra o caminho das configurações 1x
      if (prefs.getBool(_settingsDialogShownKey) == true) return;
      await prefs.setBool(_settingsDialogShownKey, true);
      showLocationPermissionDeniedDialog(context, locationService);
      return;
    }

    // status == denied: racional antes do prompt do sistema, 1x por instalação
    if (prefs.getBool(_rationaleShownKey) == true) return;

    final accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.my_location_rounded, color: AppColors.primary, size: 26),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Permitir localização',
                style: TextStyle(
                  color: AppColors.textMain,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          'Sua localização é usada apenas para enviar sua posição à sua rede de apoio durante um SOS e para mostrar pontos de ajuda próximos no mapa.\n\nPermitir agora garante que o socorro seja imediato numa emergência.',
          style: TextStyle(color: AppColors.textMain, fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Agora não', style: TextStyle(color: AppColors.rose)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Permitir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    await prefs.setBool(_rationaleShownKey, true);
    if (accepted == true) {
      await locationService.requestPermission();
    }
  }

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
