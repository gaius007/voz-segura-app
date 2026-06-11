import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/panic_alert.dart';
import '../../domain/repositories/panic_alert_repository.dart';

class PanicAlertRepositoryImpl implements PanicAlertRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _collection = 'panic_alerts';
  // Alertas expiram automaticamente 24h após o acionamento.
  static const Duration _ttl = Duration(hours: 24);

  @override
  Future<void> createAlert(String ownerUid, double latitude, double longitude) async {
    final now = DateTime.now();
    await _firestore.collection(_collection).add({
      'location': GeoPoint(latitude, longitude),
      'createdAt': FieldValue.serverTimestamp(),
      // expiresAt pronto para uma política de TTL do Firestore (limpeza física).
      'expiresAt': Timestamp.fromDate(now.add(_ttl)),
      'ownerUid': ownerUid,
      'status': 'active',
    });
  }

  @override
  Future<void> resolveActiveAlertsFor(String ownerUid) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('ownerUid', isEqualTo: ownerUid)
        .get();

    if (snapshot.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  @override
  Stream<List<PanicAlert>> watchActiveAlerts() {
    final cutoff = Timestamp.fromDate(DateTime.now().subtract(_ttl));
    // Filtro de inequação em campo único (createdAt) — não exige índice composto.
    return _firestore
        .collection(_collection)
        .where('createdAt', isGreaterThan: cutoff)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PanicAlert.fromMap(doc.data(), doc.id))
            .toList());
  }
}
