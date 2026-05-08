import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/auth_repository.dart';

// Tela de login bem bonita e moderna
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  bool _carregando = false;

  // Funcao pra entrar no sistema
  Future<void> _entrar() async {
    setState(() => _carregando = true);
    try {
      await context.read<AuthRepository>().signIn(
        _emailController.text,
        _passController.text,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao entrar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          // Gradiente pra ficar com as cores do app
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.pink.shade100, Colors.white, Colors.pink.shade50],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400), // Maximo de largura pro login
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animacao de entrada pro icone
                  TweenAnimationBuilder(
                    duration: const Duration(seconds: 1),
                    tween: Tween<double>(begin: 0, end: 1),
                    builder: (context, val, child) {
                      return Opacity(
                        opacity: val,
                        child: Transform.scale(scale: val, child: child),
                      );
                    },
                    child: Image.asset(
                      'assets/voz_segura_icon.png', // O icone que a gente colocou
                      width: 120,
                      height: 120,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'VOZ SEGURA',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFFF4081),
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // Card com efeito de vidro (Glassmorphism)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.white.withOpacity(0.4)),
                        ),
                        child: Column(
                          children: [
                            TextField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                labelText: 'E-mail',
                                prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFFFF4081)),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.5),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _passController,
                              obscureText: true,
                              decoration: InputDecoration(
                                labelText: 'Senha',
                                prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFFFF4081)),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.5),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                            _carregando 
                              ? const CircularProgressIndicator()
                              : ElevatedButton(
                                  onPressed: _entrar,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFF4081),
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size(double.infinity, 55),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                  ),
                                  child: const Text(
                                    'ENTRAR',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () {
                      // Aqui a gente pode por pra criar conta depois
                    },
                    child: const Text(
                      'Não tem conta? Crie uma agora',
                      style: TextStyle(color: Color(0xFFFF4081), fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
