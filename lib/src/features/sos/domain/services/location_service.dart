import 'package:geolocator/geolocator.dart';

// Contrato de geolocalização. Isola o pacote de GPS por trás de uma abstração,
// permitindo simular posições em testes sem hardware real.
abstract class LocationService {
  Future<Position> getCurrentPosition();
  Future<void> openAppSettings();

  // Stream contínuo de posições para acompanhar a localização em tempo real no mapa.
  Stream<Position> getPositionStream();
}
