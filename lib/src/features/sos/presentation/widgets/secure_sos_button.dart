import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../sos_notifier.dart';
import 'package:voz_segura_app/src/core/theme/app_theme.dart';
import 'package:voz_segura_app/src/features/map/presentation/manager/panic_alert_notifier.dart';

// Fases do botão: parado, segurando (anel de progresso) e enviando.
// Segurar por 3 segundos dispara o SOS direto — sem confirmação adicional,
// pois em emergência cada segundo importa. Soltar antes cancela.
enum _SosPhase { idle, holding, dispatching }

class SecureSOSButton extends StatefulWidget {
  const SecureSOSButton({super.key});

  @override
  State<SecureSOSButton> createState() => _SecureSOSButtonState();
}

class _SecureSOSButtonState extends State<SecureSOSButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  _SosPhase _phase = _SosPhase.idle;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..addStatusListener((status) {
        // reverse() termina em dismissed, então só o forward completo dispara
        if (status == AnimationStatus.completed) {
          _fire();
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _fire() async {
    if (_phase == _SosPhase.dispatching) return;
    final sos = context.read<SOSNotifier>();
    if (sos.isSending) return;

    setState(() => _phase = _SosPhase.dispatching);
    HapticFeedback.heavyImpact();

    // Notifica contatos (WhatsApp) E registra o alerta no mapa.
    context.read<PanicAlertNotifier>().createAlert();
    await sos.sendSOSAlert(context);

    if (mounted) {
      _controller.reset();
      // Botão re-trava após o envio: novo disparo exige segurar 3s de novo
      setState(() => _phase = _SosPhase.idle);
    }
  }

  void _onHoldStart(LongPressStartDetails details) {
    if (_phase == _SosPhase.dispatching) return;
    if (context.read<SOSNotifier>().isSending) return;
    HapticFeedback.selectionClick();
    setState(() => _phase = _SosPhase.holding);
    _controller.forward();
  }

  void _onHoldEnd(LongPressEndDetails details) {
    if (_phase != _SosPhase.holding) return;
    setState(() => _phase = _SosPhase.idle);
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
            child: _buildInnerButton(sos, buttonSize),
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
                        color: AppColors.ruby
                            .withOpacity(0.2 + (_controller.value * 0.25)),
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
                      // Anel de progresso dos 3 segundos
                      SizedBox(
                        width: buttonSize * 0.92,
                        height: buttonSize * 0.92,
                        child: CircularProgressIndicator(
                          value: _controller.value,
                          strokeWidth: 8,
                          backgroundColor: AppColors.rose.withOpacity(0.2),
                          strokeCap: StrokeCap.round,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.ruby),
                        ),
                      ),

                      // Botão interno (reutilizado a cada frame da animação)
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

        // Instrução dinâmica conforme a fase
        if (!sos.isSending)
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => _buildHint(),
            ),
          ),

        // Botão "Estou Segura" — aparece apenas quando há um alerta ativo no mapa.
        Consumer<PanicAlertNotifier>(
          builder: (context, panic, _) {
            if (!panic.hasActiveAlert) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 24),
              child: ElevatedButton.icon(
                onPressed: panic.isProcessing
                    ? null
                    : () async {
                        await context.read<PanicAlertNotifier>().resolveAlert();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Situação marcada como resolvida.'),
                              backgroundColor: AppColors.primary,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                icon: panic.isProcessing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.verified_user_rounded, color: Colors.white),
                label: Text(
                  panic.isProcessing ? 'Processando...' : 'Estou Segura / Situação Resolvida',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildHint() {
    switch (_phase) {
      case _SosPhase.holding:
        final remaining = (3 * (1 - _controller.value)).ceil();
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.timer_rounded, size: 16, color: AppColors.ruby),
            const SizedBox(width: 8),
            Text(
              "Continue segurando... ${remaining}s",
              style: const TextStyle(
                color: AppColors.ruby,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        );
      case _SosPhase.dispatching:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.ruby),
            ),
            const SizedBox(width: 8),
            Text(
              "Enviando alerta...",
              style: TextStyle(
                color: AppColors.ruby.withOpacity(0.8),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
      case _SosPhase.idle:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.touch_app_rounded, size: 16, color: AppColors.textLight.withOpacity(0.6)),
            const SizedBox(width: 8),
            Text(
              "Segure por 3 segundos para enviar o SOS",
              style: TextStyle(color: AppColors.textLight.withOpacity(0.6), fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        );
    }
  }

  Widget _buildInnerButton(SOSNotifier sos, double size) {
    return Container(
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
    );
  }
}
