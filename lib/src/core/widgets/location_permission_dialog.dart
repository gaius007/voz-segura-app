import 'package:flutter/material.dart';
import 'package:voz_segura_app/src/core/theme/app_theme.dart';
import 'package:voz_segura_app/src/features/sos/domain/services/location_service.dart';

// Diálogo explicativo para permissão de localização negada permanentemente.
// Compartilhado entre o onboarding pós-login e o fluxo de SOS.
void showLocationPermissionDeniedDialog(
  BuildContext context,
  LocationService locationService,
) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: const Row(
        children: [
          Icon(Icons.location_off_outlined, color: AppColors.ruby, size: 28),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Acesso à Localização',
              style: TextStyle(
                color: AppColors.textMain,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
      content: const Text(
        'A permissão de localização foi desativada para este aplicativo. Para utilizar recursos que dependem da sua localização, ative a permissão manualmente nas configurações do seu celular.',
        style: TextStyle(
          color: AppColors.textMain,
          fontSize: 14,
          height: 1.4,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar', style: TextStyle(color: AppColors.rose)),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(context);
            await locationService.openAppSettings();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.ruby,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text(
            'Abrir Configurações',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    ),
  );
}
