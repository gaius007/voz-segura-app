import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/support_point.dart';
import '../../domain/repositories/support_point_repository.dart';

/// Decorator que cacheia os POIs por região em SharedPreferences.
/// Reabrir o mapa na mesma área fica instantâneo e poupa a Overpass API
/// (que tem rate limit por ser gratuita).
class CachedSupportPointRepository implements SupportPointRepository {
  CachedSupportPointRepository(this._inner, this._prefs);

  final SupportPointRepository _inner;
  final SharedPreferences _prefs;

  static const Duration _ttl = Duration(hours: 24);

  // Chave por região: lat/lon arredondados a 2 casas (~1,1 km) + raio.
  // Prefixo versionado: mudar o formato/tipos invalida caches antigos.
  String _cacheKey(double lat, double lon, double radius) =>
      'poi_v2_${lat.toStringAsFixed(2)}_${lon.toStringAsFixed(2)}_${radius.round()}';

  @override
  Future<List<SupportPoint>> getNearbySupportPoints(
    double latitude,
    double longitude, {
    double radiusMeters = 5000,
  }) async {
    final key = _cacheKey(latitude, longitude, radiusMeters);

    final cached = _readCache(key);
    if (cached != null) return cached;

    final points = await _inner.getNearbySupportPoints(
      latitude,
      longitude,
      radiusMeters: radiusMeters,
    );
    await _writeCache(key, points);
    return points;
  }

  List<SupportPoint>? _readCache(String key) {
    try {
      final raw = _prefs.getString(key);
      if (raw == null) return null;
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final ts = DateTime.fromMillisecondsSinceEpoch(data['ts'] as int);
      if (DateTime.now().difference(ts) > _ttl) return null;
      return (data['points'] as List)
          .map((p) => SupportPoint.fromJson((p as Map).cast<String, dynamic>()))
          .toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeCache(String key, List<SupportPoint> points) async {
    try {
      await _prefs.setString(
        key,
        jsonEncode({
          'ts': DateTime.now().millisecondsSinceEpoch,
          'points': points.map((p) => p.toJson()).toList(),
        }),
      );
    } catch (_) {}
  }
}
