import 'dart:ui';
import 'package:flutter/material.dart';
import '../../reports/presentation/pages/report_list_page.dart';
import '../../reports/presentation/pages/report_create_page.dart';
import '../../sos/presentation/home_page.dart';
import '../../contacts/presentation/emergency_contacts_page.dart';

// Tela principal com o menu de vidro e o botao que nao cobre nada
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
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: _telas[_indice],
      
      // O botao agora fica aqui na Main pra gente controlar melhor
      // Ele so aparece se estivermos na aba de Relatos
      floatingActionButton: _indice == 1 
        ? FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ReportCreatePage()),
              );
            },
            backgroundColor: const Color(0xFFFF4081),
            foregroundColor: Colors.white,
            shape: const CircleBorder(),
            child: const Icon(Icons.add_photo_alternate_rounded),
          )
        : null,
      
      // Usei o centerFloat e dei um padding pro botao ficar ACIMA da barra
      // Assim ele nao tampa nenhum icone e fica centralizado bonitinho
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: BottomNavigationBar(
                currentIndex: _indice,
                onTap: (index) => setState(() => _indice = index),
                backgroundColor: Colors.transparent,
                elevation: 0,
                selectedItemColor: const Color(0xFFFF4081),
                unselectedItemColor: Colors.grey,
                showUnselectedLabels: false,
                type: BottomNavigationBarType.fixed,
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
