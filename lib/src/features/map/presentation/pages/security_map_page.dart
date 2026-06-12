import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:voz_segura_app/src/core/theme/app_theme.dart';
import '../../../sos/domain/services/location_service.dart';
import '../../domain/entities/panic_alert.dart';
import '../../domain/entities/support_point.dart';
import '../../domain/usecases/get_support_points.dart';
import '../manager/panic_alert_notifier.dart';

/// Mapa de Apoio e Segurança: localização da usuária em tempo real, pontos de
/// apoio (delegacias, hospitais, centros de apoio) e alertas de pânico ativos.
class SecurityMapPage extends StatefulWidget {
  const SecurityMapPage({super.key});

  @override
  State<SecurityMapPage> createState() => _SecurityMapPageState();
}

class _SecurityMapPageState extends State<SecurityMapPage> {
  static const LatLng _fallbackCenter = LatLng(-23.5505, -46.6333); // São Paulo
  static const String _lastCenterKey = 'map_last_center';

  final MapController _mapController = MapController();
  StreamSubscription<Position>? _positionSub;

  // Centro inicial resolvido SINCRONAMENTE (cache da última sessão) para o mapa
  // renderizar de imediato; o fix real do GPS refina via move() quando chegar.
  late LatLng _initialCenter;
  LatLng? _currentLatLng;
  LatLng? _poiCenter; // centro para o qual os POIs já foram carregados
  DateTime? _lastCenterSave;
  List<SupportPoint> _supportPoints = [];
  bool _loadingPoints = false;
  bool _mapReady = false;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _initialCenter = _readCachedCenter() ?? _fallbackCenter;
    _init();
  }

  LatLng? _readCachedCenter() {
    try {
      final raw = context.read<SharedPreferences>().getString(_lastCenterKey);
      if (raw == null) return null;
      final parts = raw.split(',');
      return LatLng(double.parse(parts[0]), double.parse(parts[1]));
    } catch (_) {
      return null;
    }
  }

  Future<void> _init() async {
    final locationService = context.read<LocationService>();

    // POIs da região conhecida carregam já, sem esperar o GPS
    if (_readCachedCenter() != null) {
      _maybeLoadPoints(_initialCenter);
    }

    // Última posição conhecida chega em milissegundos — refina o centro
    locationService.getLastKnownPosition().then((pos) {
      if (pos != null) _applyPosition(LatLng(pos.latitude, pos.longitude));
    });

    // Stream em tempo real desde já
    _subscribeToPosition(locationService);

    // Fix real do GPS (pode demorar até 10s) — em paralelo, sem bloquear nada
    try {
      final pos = await locationService.getCurrentPosition();
      _applyPosition(LatLng(pos.latitude, pos.longitude));
    } catch (e) {
      if (!mounted) return;
      if (_currentLatLng == null) {
        setState(() {
          _locationError = e.toString().contains('negada')
              ? 'Permissão de localização negada. Ative o GPS para ver o mapa centrado em você.'
              : 'Não foi possível obter sua localização.';
        });
      }
    }
  }

  /// Aplica uma nova posição real: marca a usuária, move o mapa no primeiro fix,
  /// carrega/atualiza POIs e persiste o centro para a próxima sessão.
  void _applyPosition(LatLng latLng) {
    if (!mounted) return;
    final firstFix = _currentLatLng == null;
    setState(() {
      _currentLatLng = latLng;
      _locationError = null; // qualquer posição obtida limpa o erro
    });
    if (firstFix && _mapReady) _mapController.move(latLng, 15);
    _maybeLoadPoints(latLng);
    _persistCenter(latLng);
  }

  // Carrega POIs apenas quando ainda não há, ou quando o centro mudou >2km
  void _maybeLoadPoints(LatLng center) {
    if (_poiCenter != null) {
      final meters = const Distance().as(LengthUnit.Meter, _poiCenter!, center);
      if (meters < 2000) return;
    }
    _poiCenter = center;
    _loadSupportPoints(center);
  }

  // Grava o centro com throttle de 30s para não spammar o SharedPreferences
  void _persistCenter(LatLng latLng) {
    final now = DateTime.now();
    if (_lastCenterSave != null &&
        now.difference(_lastCenterSave!) < const Duration(seconds: 30)) {
      return;
    }
    _lastCenterSave = now;
    context
        .read<SharedPreferences>()
        .setString(_lastCenterKey, '${latLng.latitude},${latLng.longitude}');
  }

  void _subscribeToPosition(LocationService locationService) {
    _positionSub = locationService.getPositionStream().listen(
      (pos) => _applyPosition(LatLng(pos.latitude, pos.longitude)),
      onError: (_) {},
    );
  }

  Future<void> _loadSupportPoints(LatLng center) async {
    setState(() => _loadingPoints = true);
    try {
      final points = await context
          .read<GetSupportPoints>()
          .execute(center.latitude, center.longitude);
      if (!mounted) return;
      setState(() {
        _supportPoints = points;
        _loadingPoints = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingPoints = false);
      debugPrint('Erro ao carregar pontos de apoio: $e');
    }
  }

  void _recenter() {
    final pos = _currentLatLng;
    if (pos != null && _mapReady) _mapController.move(pos, 15);
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final alerts = context.watch<PanicAlertNotifier>().activeAlerts;

    return Scaffold(
      backgroundColor: context.appScaffoldBg,
      appBar: AppBar(
        title: const Text('Mapa de Segurança'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      // O mapa renderiza imediatamente com o último centro conhecido;
      // o fix do GPS apenas refina a posição quando chegar.
      body: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _currentLatLng ?? _initialCenter,
                    initialZoom: 15,
                    minZoom: 3,
                    maxZoom: 18,
                    onMapReady: () => _mapReady = true,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.voz_segura_app',
                      // Em telas de alta densidade, busca tiles em maior resolução
                      // e reduz a escala — deixa o mapa nítido (sem pixelização).
                      retinaMode: RetinaMode.isHighDensity(context),
                    ),
                    MarkerLayer(markers: _buildSupportMarkers()),
                    MarkerLayer(markers: _buildAlertMarkers(alerts)),
                    if (_currentLatLng != null)
                      MarkerLayer(markers: [_buildUserMarker(_currentLatLng!)]),
                  ],
                ),

                // Aviso de erro de localização
                if (_locationError != null) _buildLocationBanner(),

                // Indicador de carregamento dos pontos de apoio
                if (_loadingPoints)
                  Positioned(
                    top: 16,
                    left: 0,
                    right: 0,
                    child: Center(child: _buildLoadingChip()),
                  ),

                // Legenda dos tipos de pin
                Positioned(left: 16, bottom: 110, child: _buildLegend()),

                // Botão de recentralizar
                Positioned(
                  right: 16,
                  bottom: 110,
                  child: FloatingActionButton(
                    heroTag: 'recenter_map',
                    backgroundColor: context.appPrimary,
                    onPressed: _recenter,
                    child: const Icon(Icons.my_location_rounded, color: Colors.white),
                  ),
                ),
              ],
            ),
    );
  }

  // ─── Marcadores ──────────────────────────────────────────

  Marker _buildUserMarker(LatLng pos) {
    return Marker(
      point: pos,
      width: 26,
      height: 26,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blue,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(color: Colors.blue.withOpacity(0.4), blurRadius: 10, spreadRadius: 2),
          ],
        ),
      ),
    );
  }

  List<Marker> _buildSupportMarkers() {
    return _supportPoints.map((p) {
      final (icon, color) = _styleFor(p.type);
      return Marker(
        point: LatLng(p.latitude, p.longitude),
        width: 40,
        height: 40,
        child: GestureDetector(
          onTap: () => _showSupportInfo(p),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
              ],
            ),
            child: Icon(icon, color: color, size: 22),
          ),
        ),
      );
    }).toList();
  }

  List<Marker> _buildAlertMarkers(List<PanicAlert> alerts) {
    return alerts.map((a) {
      return Marker(
        point: LatLng(a.latitude, a.longitude),
        width: 48,
        height: 48,
        child: GestureDetector(
          onTap: () => _showAlertInfo(a),
          child: const _PulsingDangerMarker(),
        ),
      );
    }).toList();
  }

  (IconData, Color) _styleFor(SupportPointType type) {
    switch (type) {
      case SupportPointType.delegacia:
        return (Icons.local_police_rounded, Colors.indigo);
      case SupportPointType.delegaciaMulher:
        return (Icons.local_police_rounded, AppColors.primary);
      case SupportPointType.postoPM:
        return (Icons.shield_rounded, Colors.blue);
      case SupportPointType.hospital:
        return (Icons.local_hospital_rounded, Colors.red);
      case SupportPointType.centroApoio:
        return (Icons.volunteer_activism_rounded, Colors.teal);
      case SupportPointType.casaAcolhimento:
        return (Icons.night_shelter_rounded, Colors.deepPurple);
      case SupportPointType.outro:
        return (Icons.place_rounded, Colors.grey);
    }
  }

  // ─── Overlays e diálogos ─────────────────────────────────

  void _showSupportInfo(SupportPoint p) {
    final (icon, color) = _styleFor(p.type);
    showModalBottomSheet(
      context: context,
      backgroundColor: context.appCardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.type.label,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.appRose)),
                  const SizedBox(height: 4),
                  Text(p.name,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.appTextMain)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAlertInfo(PanicAlert a) {
    final hora = DateFormat("dd/MM/yyyy 'às' HH:mm").format(a.createdAt);
    final coords = '${a.latitude.toStringAsFixed(6)}, ${a.longitude.toStringAsFixed(6)}';
    final mapsUrl =
        'https://www.google.com/maps/search/?api=1&query=${a.latitude},${a.longitude}';

    showModalBottomSheet(
      context: context,
      backgroundColor: context.appCardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: AppColors.ruby, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Usuária em perigo',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.appRuby)),
                      const SizedBox(height: 4),
                      Text('Alerta acionado em $hora',
                          style: TextStyle(fontSize: 13, color: context.appTextLight)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text('LOCALIZAÇÃO',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: context.appRose, letterSpacing: 1)),
            const SizedBox(height: 8),
            // Texto da localização — tocar abre no Google Maps.
            InkWell(
              onTap: () => _abrirNoMaps(mapsUrl),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: context.appPrimary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.appPrimary.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.location_on_rounded, color: context.appPrimary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        coords,
                        style: TextStyle(
                          color: context.appPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    Icon(Icons.open_in_new_rounded, color: context.appPrimary, size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text('Toque na localização para abrir no Google Maps.',
                style: TextStyle(fontSize: 11, color: context.appTextLight)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _copiarLocalizacao(coords),
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: const Text('Copiar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.appRuby,
                      side: BorderSide(color: context.appRuby),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _abrirNoMaps(mapsUrl),
                    icon: const Icon(Icons.map_rounded, size: 18, color: Colors.white),
                    label: const Text('Abrir no Mapa', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.appPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _copiarLocalizacao(String coords) async {
    await Clipboard.setData(ClipboardData(text: coords));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Localização copiada!'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _abrirNoMaps(String url) async {
    final uri = Uri.parse(url);
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível abrir o Google Maps.'),
            backgroundColor: AppColors.ruby,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível abrir o Google Maps.'),
            backgroundColor: AppColors.ruby,
          ),
        );
      }
    }
  }

  Widget _buildLocationBanner() {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.ruby.withOpacity(0.95),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.location_off_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _locationError!,
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: context.appCardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2, color: context.appPrimary),
          ),
          const SizedBox(width: 10),
          Text('Buscando pontos de apoio...',
              style: TextStyle(fontSize: 12, color: context.appTextMain)),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    Widget item(IconData icon, Color color, String label) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(fontSize: 11, color: context.appTextMain)),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.appCardColor.withOpacity(0.92),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          item(Icons.local_police_rounded, AppColors.primary, 'Delegacia da Mulher'),
          item(Icons.local_police_rounded, Colors.indigo, 'Delegacia / Polícia'),
          item(Icons.local_hospital_rounded, Colors.red, 'Hospital'),
          item(Icons.volunteer_activism_rounded, Colors.teal, 'Centro de Apoio'),
          item(Icons.night_shelter_rounded, Colors.deepPurple, 'Casa de Acolhimento'),
          item(Icons.warning_amber_rounded, AppColors.ruby, 'Usuária em perigo'),
        ],
      ),
    );
  }
}

/// Pin vermelho de alerta com animação de pulso contínua.
class _PulsingDangerMarker extends StatefulWidget {
  const _PulsingDangerMarker();

  @override
  State<_PulsingDangerMarker> createState() => _PulsingDangerMarkerState();
}

class _PulsingDangerMarkerState extends State<_PulsingDangerMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        return Stack(
          alignment: Alignment.center,
          children: [
            // Halo pulsante
            Container(
              width: 48 * (0.6 + t * 0.4),
              height: 48 * (0.6 + t * 0.4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.ruby.withOpacity(0.25 * (1 - t)),
              ),
            ),
            child!,
          ],
        );
      },
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: AppColors.ruby,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 16),
      ),
    );
  }
}
