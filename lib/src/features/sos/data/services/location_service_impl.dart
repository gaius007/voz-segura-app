import 'package:geolocator/geolocator.dart';
import '../../domain/services/location_service.dart';

// Implementação concreta de geolocalização usando o pacote geolocator.
// Trocar de biblioteca de GPS afeta apenas este arquivo.
class LocationServiceImpl implements LocationService {
  // Lógica do GPS com permissões robustas e detalhadas
  @override
  Future<Position> getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return Future.error('GPS desativado.');

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Permissão de localização negada.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Permissão negada permanentemente.');
    }

    // Em ambiente fechado o fix de GPS pode demorar indefinidamente — num SOS
    // é melhor enviar a última posição conhecida do que travar sem enviar nada.
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (_) {
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) return lastKnown;
      return Future.error('Não foi possível obter a localização (GPS sem sinal).');
    }
  }

  @override
  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  @override
  Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    );
  }
}
