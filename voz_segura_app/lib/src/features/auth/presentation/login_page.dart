import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/auth_repository.dart';
import 'package:voz_segura_app/src/core/theme/app_theme.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  bool _carregando = false;

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
          SnackBar(
            content: Text('Erro ao entrar: $e'),
            backgroundColor: AppColors.ruby,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.sakura, Colors.white, AppColors.blush],
              ),
            ),
          ),
          
          // Decorative Blurred Elements
          Positioned(
            top: -100,
            left: -100,
            child: _buildBlurCircle(AppColors.rose.withOpacity(0.3), 300),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: _buildBlurCircle(AppColors.lilac.withOpacity(0.4), 250),
          ),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated Logo
                    TweenAnimationBuilder(
                      duration: const Duration(seconds: 1),
                      curve: Curves.easeOutBack,
                      tween: Tween<double>(begin: 0, end: 1),
                      builder: (context, double val, child) {
                        return Transform.scale(scale: val, child: child);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: AppStyles.softShadow,
                        ),
                        child: Image.asset(
                          'assets/voz_segura_icon.png',
                          width: 80,
                          height: 80,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text('VOZ SEGURA', style: AppStyles.h1),
                    const SizedBox(height: 8),
                    const Text('Seu porto seguro digital', style: AppStyles.subtitle),
                    const SizedBox(height: 48),
                    
                    // Glassmorphic Login Card
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppStyles.borderRadius),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(AppStyles.borderRadius),
                            border: Border.all(color: Colors.white.withOpacity(0.5)),
                            boxShadow: AppStyles.softShadow,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextFormField(
                                controller: _emailController,
                                decoration: const InputDecoration(
                                  labelText: 'E-mail',
                                  prefixIcon: Icon(Icons.email_outlined, color: AppColors.primary),
                                ),
                              ),
                              const SizedBox(height: 20),
                              TextFormField(
                                controller: _passController,
                                obscureText: true,
                                decoration: const InputDecoration(
                                  labelText: 'Senha',
                                  prefixIcon: Icon(Icons.lock_outline_rounded, color: AppColors.primary),
                                ),
                              ),
                              const SizedBox(height: 32),
                              _carregando 
                                ? const Center(child: CircularProgressIndicator())
                                : ElevatedButton(
                                    onPressed: _entrar,
                                    style: ElevatedButton.styleFrom(
                                      minimumSize: const Size(double.infinity, 60),
                                      backgroundColor: AppColors.primary,
                                      elevation: 8,
                                      shadowColor: AppColors.primary.withOpacity(0.3),
                                    ),
                                    child: const Text(
                                      'ENTRAR AGORA',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                  ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegisterPage(),
                          ),
                        );
                      },
                      child: Text(
                        'Primeira vez aqui? Crie uma conta',
                        style: TextStyle(color: AppColors.ruby.withOpacity(0.7), fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlurCircle(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: Container(color: Colors.transparent),
      ),
    );
  }
}
