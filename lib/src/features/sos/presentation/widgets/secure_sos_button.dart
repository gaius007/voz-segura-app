import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../sos_notifier.dart';
import 'package:voz_segura_app/src/core/theme/app_theme.dart';

class SecureSOSButton extends StatefulWidget {
  const SecureSOSButton({super.key});

  @override
  State<SecureSOSButton> createState() => _SecureSOSButtonState();
}

class _SecureSOSButtonState extends State<SecureSOSButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isHolding = false;
  bool _isUnlocked = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() => _isUnlocked = true);
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onHoldStart(LongPressStartDetails details) {
    if (_isUnlocked) return;
    setState(() => _isHolding = true);
    _controller.forward();
  }

  void _onHoldEnd(LongPressEndDetails details) {
    if (_isUnlocked) return;
    setState(() => _isHolding = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final sos = context.watch<SOSNotifier>();
    const buttonSize = 240.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onLongPressStart: _onHoldStart,
          onLongPressEnd: _onHoldEnd,
          child: AnimatedBuilder(
            animation: _controller,
            // O botão interno não depende de _controller.value; é passado como `child`
            // para ser construído uma única vez por build, e não a cada frame da animação.
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: _isUnlocked
                  ? _buildSOSReal(sos, buttonSize)
                  : _buildTrava(buttonSize),
            ),
            builder: (context, child) {
              double scale = 1.0 + (_controller.value * 0.05);
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: buttonSize,
                  height: buttonSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.4),
                    boxShadow: [
                      BoxShadow(
                        color: (_isUnlocked ? AppColors.ruby : AppColors.primary)
                            .withOpacity(0.2 + (_controller.value * 0.2)),
                        blurRadius: 40,
                        spreadRadius: 5,
                      ),
                    ],
                    border: Border.all(
                      color: Colors.white.withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Progress Ring
                      SizedBox(
                        width: buttonSize * 0.92,
                        height: buttonSize * 0.92,
                        child: CircularProgressIndicator(
                          value: _controller.value,
                          strokeWidth: 8,
                          backgroundColor: AppColors.rose.withOpacity(0.2),
                          strokeCap: StrokeCap.round,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _isUnlocked ? Colors.transparent : AppColors.primary,
                          ),
                        ),
                      ),

                      // Inner Button (reutilizado a cada frame da animação)
                      child!,
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 40),
        
        // Status Message with premium style
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          child: sos.statusMessage.isNotEmpty
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: AppStyles.glass(opacity: 0.5, blur: 10),
                  child: Text(
                    sos.statusMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: sos.statusMessage.contains("sucesso") ? Colors.green.shade700 : AppColors.ruby,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        
        if (!_isUnlocked && !sos.isSending)
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.touch_app_rounded, size: 16, color: AppColors.textLight.withOpacity(0.6)),
                const SizedBox(width: 8),
                Text(
                  "Segure para destravar o botão SOS",
                  style: TextStyle(color: AppColors.textLight.withOpacity(0.6), fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildTrava(double size) {
    return Column(
      key: const ValueKey('trava'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          _isHolding ? Icons.lock_open_rounded : Icons.lock_rounded,
          size: 60,
          color: _isHolding ? AppColors.primary : AppColors.rose,
        ),
        const SizedBox(height: 12),
        Text(
          _isHolding ? "DESTRAVANDO" : "PROTEGIDO",
          style: const TextStyle(
            color: AppColors.ruby,
            fontWeight: FontWeight.w900,
            fontSize: 14,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildSOSReal(SOSNotifier sos, double size) {
    return Material(
      key: const ValueKey('sos'),
      color: Colors.transparent,
      child: InkWell(
        onTap: sos.isSending ? null : () => sos.sendSOSAlert(context),
        borderRadius: BorderRadius.circular(size),
        child: Container(
          width: size * 0.8,
          height: size * 0.8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.ruby],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.ruby.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.warning_amber_rounded, size: 50, color: Colors.white),
              const SizedBox(height: 4),
              const Text(
                "SOCORRO",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              if (sos.isSending)
                const Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
