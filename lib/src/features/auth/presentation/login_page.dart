import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../domain/auth_repository.dart';
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
      await context.read<AuthRepository>().signInWithEmailAndPassword(
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

  void _showForgotPasswordDialog() {
    final resetEmailController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppStyles.borderRadius),
              ),
              title: const Row(
                children: [
                  Icon(Icons.lock_reset_rounded, color: AppColors.primary),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Recuperar Senha',
                      style: TextStyle(
                        color: AppColors.ruby,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Informe o e-mail cadastrado e enviaremos um link para redefinir sua senha.',
                      style: TextStyle(color: AppColors.textLight, fontSize: 14),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: resetEmailController,
                      keyboardType: TextInputType.emailAddress,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'E-mail',
                        prefixIcon: Icon(Icons.email_outlined, color: AppColors.primary),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Informe seu e-mail';
                        }
                        if (!value.contains('@') || !value.contains('.')) {
                          return 'Insira um e-mail v\u00e1lido';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(dialogContext),
                  child: Text(
                    'Cancelar',
                    style: TextStyle(color: AppColors.textLight),
                  ),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;

                          setDialogState(() => isLoading = true);

                          try {
                            await context
                                .read<AuthRepository>()
                                .sendPasswordResetEmail(
                                  resetEmailController.text.trim(),
                                );

                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                            }
                            if (mounted) {
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                const SnackBar(
                                  content: Row(
                                    children: [
                                      Icon(Icons.check_circle_outline, color: Colors.white),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'Link de recupera\u00e7\u00e3o enviado para o seu e-mail!',
                                        ),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: Color(0xFF4CAF50),
                                  behavior: SnackBarBehavior.floating,
                                  duration: Duration(seconds: 5),
                                ),
                              );
                            }
                          } on FirebaseAuthException catch (e) {
                            String message;
                            switch (e.code) {
                              case 'user-not-found':
                                message = 'Nenhuma conta encontrada com este e-mail.';
                                break;
                              case 'invalid-email':
                                message = 'O e-mail informado \u00e9 inv\u00e1lido.';
                                break;
                              case 'too-many-requests':
                                message = 'Muitas tentativas. Aguarde alguns minutos e tente novamente.';
                                break;
                              default:
                                message = 'Erro ao enviar e-mail de recupera\u00e7\u00e3o. Tente novamente.';
                            }
                            if (mounted) {
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(Icons.error_outline, color: Colors.white),
                                      const SizedBox(width: 12),
                                      Expanded(child: Text(message)),
                                    ],
                                  ),
                                  backgroundColor: AppColors.ruby,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                SnackBar(
                                  content: Text('Erro inesperado: $e'),
                                  backgroundColor: AppColors.ruby,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          } finally {
                            if (dialogContext.mounted) {
                              setDialogState(() => isLoading = false);
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Enviar', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient (theme-aware)
          Container(
            decoration: BoxDecoration(
              gradient: context.appBackgroundGradient,
            ),
          ),
          
          // Decorative Blurred Elements
          Positioned(
            top: -100,
            left: -100,
            child: _buildBlurCircle(context.appRose.withOpacity(0.3), 300),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: _buildBlurCircle(context.appLilac.withOpacity(0.4), 250),
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
                          color: context.appCardColor,
                          shape: BoxShape.circle,
                          boxShadow: context.appSoftShadow,
                        ),
                        child: Image.asset(
                          'assets/voz_segura_icon.png',
                          width: 80,
                          height: 80,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text('VOZ SEGURA', style: AppStyles.h1.copyWith(color: context.appRuby)),
                    const SizedBox(height: 8),
                    Text('Seu porto seguro digital', style: AppStyles.subtitle.copyWith(color: context.appTextLight)),
                    const SizedBox(height: 48),
                    
                    // Glassmorphic Login Card
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppStyles.borderRadius),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: context.appGlassColor,
                            borderRadius: BorderRadius.circular(AppStyles.borderRadius),
                            border: Border.all(color: context.appGlassBorder),
                            boxShadow: context.appSoftShadow,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextFormField(
                                controller: _emailController,
                                decoration: InputDecoration(
                                  labelText: 'E-mail',
                                  prefixIcon: Icon(Icons.email_outlined, color: context.appPrimary),
                                ),
                              ),
                              const SizedBox(height: 20),
                              TextFormField(
                                controller: _passController,
                                obscureText: true,
                                decoration: InputDecoration(
                                  labelText: 'Senha',
                                  prefixIcon: Icon(Icons.lock_outline_rounded, color: context.appPrimary),
                                ),
                              ),
                              const SizedBox(height: 32),
                              _carregando 
                                ? const Center(child: CircularProgressIndicator())
                                : ElevatedButton(
                                    onPressed: _entrar,
                                    style: ElevatedButton.styleFrom(
                                      minimumSize: const Size(double.infinity, 60),
                                      backgroundColor: context.appPrimary,
                                      elevation: 8,
                                      shadowColor: context.appPrimary.withOpacity(0.3),
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
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _showForgotPasswordDialog,
                        child: Text(
                          'Esqueci minha senha',
                          style: TextStyle(
                            color: context.appRuby.withOpacity(0.8),
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
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
                        style: TextStyle(color: context.appRuby.withOpacity(0.7), fontWeight: FontWeight.w600),
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
