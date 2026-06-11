import 'package:cloud_firestore/cloud_firestore.dart';

/// Alerta de pânico ativo de uma usuária, exibido como pin no mapa.
/// Anônimo na exibição: outras usuárias só veem localização + horário.
/// O [ownerUid] é usado apenas para regras (criar/resolver), nunca exibido.
class PanicAlert {
  final String id;
  final double latitude;
  final double longitude;
  final DateTime createdAt;
  final String ownerUid;

  PanicAlert({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
    required this.ownerUid,
  });

  // Converte o documento do Firestore (GeoPoint + Timestamp) em entidade.
  factory PanicAlert.fromMap(Map<String, dynamic> map, String docId) {
    final geo = map['location'] as GeoPoint?;
    final ts = map['createdAt'] as Timestamp?;
    return PanicAlert(
      id: docId,
      latitude: geo?.latitude ?? 0,
      longitude: geo?.longitude ?? 0,
      createdAt: ts?.toDate() ?? DateTime.now(),
      ownerUid: map['ownerUid'] as String? ?? '',
    );
  }
}
