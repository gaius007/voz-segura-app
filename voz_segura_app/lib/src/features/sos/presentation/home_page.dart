import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'sos_notifier.dart';

// Tela principal com o botao de panico. Tentei deixar bem chamativo!
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Fiz essa animacao pro botao ficar "pulsando" quando o SOS ta ligado
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final sosNotifier = context.watch<SOSNotifier>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Botão de Pânico'),
        centerTitle: true,
        actions: [
          // Botao pra deslogar do Firebase
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => sosNotifier.logout(),
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Colors.pink.shade50],
          ),
        ),
        child: Center( // Deixando centralizado pra telas grandes
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'VOCÊ ESTÁ SEGURA?',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFFFF4081), letterSpacing: 2),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Se sentir perigo, aperte o botão abaixo',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 60),
                
                GestureDetector(
                  onTap: () => sosNotifier.toggleSOS(),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Efeito de pulso vermelho se o SOS tiver ativo
                      if (sosNotifier.isSOSActive)
                        ScaleTransition(
                          scale: Tween(begin: 1.0, end: 1.2).animate(_controller),
                          child: Container(
                            width: 220,
                            height: 220,
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      // O botao principal
                      Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          color: sosNotifier.isSOSActive ? Colors.red : Colors.grey.shade300,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (sosNotifier.isSOSActive ? Colors.red : Colors.grey).withOpacity(0.4),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                sosNotifier.isSOSActive ? Icons.warning_rounded : Icons.shield_rounded,
                                color: Colors.white,
                                size: 60,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'SOS',
                                style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 60),
                // Avisando se o socorro ja foi pedido
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: sosNotifier.isSOSActive ? Colors.red.shade50 : Colors.blueGrey.shade50,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    sosNotifier.isSOSActive 
                      ? '⚠️ SOCORRO SOLICITADO!' 
                      : 'Proteção Ativada',
                    style: TextStyle(
                      color: sosNotifier.isSOSActive ? Colors.red : Colors.blueGrey,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
