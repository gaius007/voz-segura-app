import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_controller.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _onLogin() async {
    final success = await ref.read(authControllerProvider.notifier).login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (success && mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    } else if (mounted) {
      final error = ref.read(authControllerProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error?.toString() ?? "Erro ao entrar"),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.deepPurple.shade50, Colors.white],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Image.asset("assets/icon.png", height: 100),
            const SizedBox(height: 32),
            const Text(
              "Seja bem-vinda!",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            const SizedBox(height: 48),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: "E-mail",
                prefixIcon: Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Senha",
                prefixIcon: Icon(Icons.password_outlined),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: isLoading ? null : _onLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF815A68),
              ),
              child: isLoading 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text("Entrar", style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/registro'),
              child: const Text("Não tem uma conta? Registre-se"),
            ),
          ],
        ),
      ),
    );
  }
}
