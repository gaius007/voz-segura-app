// Contrato de envio de alertas de emergência.
// O WhatsApp é o único canal do app: envio silencioso via Evolution API
// com fallback para o WhatsApp nativo (wa.me).
abstract class SosSenderRepository {
  Future<void> sendWhatsApp(String phone, String link);
}
