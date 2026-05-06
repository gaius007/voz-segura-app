import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'sos_controller.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _animation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSOSToggle() {
    final notifier = ref.read(sOSControllerProvider.notifier);
    notifier.toggleSOS();
    
    final isActive = ref.read(sOSControllerProvider);
    if (isActive) {
      _controller.repeat();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("SOS Disparado! Enviando alerta para sua rede de apoio..."),
          backgroundColor: Colors.pink,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      _controller.stop();
      _controller.reset();
    }
  }

  Future<void> _logout() async {
    await ref.read(sOSControllerProvider.notifier).logout();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSOSActive = ref.watch(sOSControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Comando Central"),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          )
        ],
      ),
      body: Stack(
        children: [
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(color: Colors.pink.shade100.withValues(alpha: 0.3), shape: BoxShape.circle),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Precisa de ajuda?",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.pink),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Pressione o botão abaixo para alertar sua rede.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 60),
                
                GestureDetector(
                  onTap: _handleSOSToggle,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _animation,
                        builder: (context, child) {
                          return Container(
                            width: 160 * _animation.value,
                            height: 160 * _animation.value,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.pink.withValues(alpha: 0.2 * (1.5 - _animation.value)),
                            ),
                          );
                        },
                      ),
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSOSActive ? Colors.pink : Colors.pinkAccent,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.pink.withValues(alpha: 0.4),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            isSOSActive ? "ENVIANDO" : "SOS",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 80),
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/contacts'),
                    icon: const Icon(Icons.people_outline),
                    label: const Text("Gerenciar Rede de Apoio"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.pink,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: Colors.pink, width: 1),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
