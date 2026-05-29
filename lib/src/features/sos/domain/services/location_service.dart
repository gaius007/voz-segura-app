import 'package:geolocator/geolocator.dart';

// Contrato de geolocalização. Isola o pacote de GPS por trás de uma abstração,
// permitindo simular posições em testes sem hardware real.
abstract class LocationService {
  Future<Position> getCurrentPosition();
  Future<void> openAppSettings();
}
