import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'sos_notifier.dart';
import 'widgets/secure_sos_button.dart';
import 'package:voz_segura_app/src/core/theme/app_theme.dart';

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
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
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
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('VOZ SEGURA'),
        actions: [
          IconButton(
            icon: const Icon(Icons.power_settings_new_rounded),
            onPressed: () => sosNotifier.logout(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // Background decorative elements
          Positioned(
            top: -50,
            right: -50,
            child: _buildBlurCircle(AppColors.rose.withOpacity(0.4), 200),
          ),
          Positioned(
            bottom: 100,
            left: -100,
            child: _buildBlurCircle(AppColors.lilac.withOpacity(0.5), 300),
          ),
          
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated Header
                  TweenAnimationBuilder(
                    duration: const Duration(seconds: 1),
                    tween: Tween<double>(begin: 0, end: 1),
                    builder: (context, double val, child) {
                      return Opacity(
                        opacity: val,
                        child: Transform.translate(
                          offset: Offset(0, 20 * (1 - val)),
                          child: child,
                        ),
                      );
                    },
                    child: Column(
                      children: [
                        const Text(
                          'SENTE-SE SEGURA?',
                          style: AppStyles.h1,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Em caso de perigo, mantenha o botão\npressionado para alertar sua rede.',
                          textAlign: TextAlign.center,
                          style: AppStyles.subtitle,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 60),
                  
                  // The button
                  const SecureSOSButton(),
                  
                  const SizedBox(height: 60),
                  
                  // Visual feedback for active SOS
                  if (sosNotifier.isSOSActive)
                    _buildActiveSOSBadge(),
                ],
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
        filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
        child: Container(color: Colors.transparent),
      ),
    );
  }

  Widget _buildActiveSOSBadge() {
    return ScaleTransition(
      scale: Tween(begin: 1.0, end: 1.05).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.ruby,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: AppColors.ruby.withOpacity(0.3),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_active_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text(
              'ALERTAS ATIVOS',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.2),
            ),
          ],
        ),
      ),
    );
  }
}
