import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:voz_segura_app/src/core/theme/app_theme.dart';

// Tela de sucesso exibida logo apos a criacao da conta.
// O Firebase Auth ja loga a usuaria automaticamente, entao o AuthWrapper
// (rota raiz) ja trocou para a home por baixo desta rota — ao fechar,
// a usuaria cai direto no app logada.
class RegisterSuccessPage extends StatefulWidget {
  const RegisterSuccessPage({super.key});

  @override
  State<RegisterSuccessPage> createState() => _RegisterSuccessPageState();
}

class _RegisterSuccessPageState extends State<RegisterSuccessPage> {
  Timer? _autoCloseTimer;

  @override
  void initState() {
    super.initState();
    HapticFeedback.mediumImpact();
    _autoCloseTimer = Timer(const Duration(milliseconds: 2500), _goToHome);
  }

  @override
  void dispose() {
    _autoCloseTimer?.cancel();
    super.dispose();
  }

  void _goToHome() {
    if (!mounted) return;
    // Revela a rota raiz (AuthWrapper), que ja esta exibindo a home logada
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(gradient: context.appBackgroundGradient),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 800),
                curve: Curves.elasticOut,
                builder: (context, value, child) =>
                    Transform.scale(scale: value, child: child),
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: context.appPrimary.withValues(alpha: 0.12),
                  ),
                  child: Icon(
                    Icons.check_circle_rounded,
                    size: 110,
                    color: context.appPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOut,
                builder: (context, value, child) => Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 16 * (1 - value)),
                    child: child,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'Conta criada com sucesso!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: context.appRuby,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        'Você já está logada. Bem-vinda ao Voz Segura!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: context.appTextMain.withValues(alpha: 0.7),
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    TextButton.icon(
                      onPressed: _goToHome,
                      icon: Icon(Icons.arrow_forward_rounded,
                          size: 18, color: context.appPrimary),
                      label: Text(
                        'Começar agora',
                        style: TextStyle(
                          color: context.appPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
