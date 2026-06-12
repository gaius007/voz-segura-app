import 'package:geolocator/geolocator.dart';

// Contrato de geolocalização. Isola o pacote de GPS por trás de uma abstração,
// permitindo simular posições em testes sem hardware real.
abstract class LocationService {
  Future<Position> getCurrentPosition();
  Future<void> openAppSettings();

  // Stream contínuo de posições para acompanhar a localização em tempo real no mapa.
  Stream<Position> getPositionStream();

  // Estado e solicitação de permissão — usados no onboarding pós-login,
  // para que o SOS não dependa de prompts na hora da emergência.
  Future<LocationPermission> checkPermission();
  Future<LocationPermission> requestPermission();

  // Última posição conhecida (rápida, sem esperar fix de GPS); null se nunca houve.
  Future<Position?> getLastKnownPosition();
}
