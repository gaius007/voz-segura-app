import 'dart:ui';
import 'package:flutter/material.dart';
import '../../reports/presentation/pages/report_list_page.dart';
import '../../sos/presentation/home_page.dart';
import '../../contacts/presentation/emergency_contacts_page.dart';

// Tela de navegacao com efeito de vidro (Glassmorphism)
// Fiz assim pq fica muito mais moderno e bonito
class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _indice = 0;

  // Agora temos 3 abas: Home, Relatos e Contatos
  final List<Widget> _telas = [
    const HomePage(),
    const ReportListPage(),
    const EmergencyContactsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Estende o corpo pra tras da barra de navegacao pra dar o efeito de vidro
      extendBody: true,
      body: _telas[_indice],
      
      // Barra de navegacao com efeito Glassmorphism
      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            // O blur eh o segredo do efeito de vidro
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2), // transparencia
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: BottomNavigationBar(
                currentIndex: _indice,
                onTap: (index) => setState(() => _indice = index),
                backgroundColor: Colors.transparent, // deixa transparente pro container mostrar
                elevation: 0,
                selectedItemColor: const Color(0xFFFF4081), // rosa principal
                unselectedItemColor: Colors.grey,
                showUnselectedLabels: false,
                items: const [
                  BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
                  BottomNavigationBarItem(icon: Icon(Icons.assignment_rounded), label: 'Relatos'),
                  BottomNavigationBarItem(icon: Icon(Icons.people_rounded), label: 'Contatos'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
