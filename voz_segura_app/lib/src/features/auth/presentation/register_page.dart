import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_controller.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _onRegister() async {
    final success = await ref.read(authControllerProvider.notifier).register(
      _emailController.text.trim(),
      _passwordController.text.trim(),
      _nameController.text.trim(),
    );

    if (success && mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    } else if (mounted) {
      final error = ref.read(authControllerProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error?.toString() ?? "Erro ao registrar"),
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
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      extendBodyBehindAppBar: true,
      body: Container(
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.deepPurple.shade50, Colors.white],
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 80),
              const Text(
                "Criar Conta",
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              const SizedBox(height: 8),
              const Text("Junte-se ao Voz Segura e comece agora."),
              const SizedBox(height: 48),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "Nome Completo",
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 16),
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
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: isLoading ? null : _onRegister,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF815A68),
                ),
                child: isLoading 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text("Registrar", style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Já tem uma conta? Faça login"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
