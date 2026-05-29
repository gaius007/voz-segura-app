// Contrato de envio de alertas de emergência por múltiplos canais.
// Isola conexões de rede (Evolution/Brevo) e canais nativos (MethodChannel/SMS)
// por trás de uma abstração, permitindo simular disparos em testes.
abstract class SosSenderRepository {
  Future<void> sendWhatsApp(String phone, String link);
  Future<void> sendSMS(String phone, String link);
  Future<void> sendEmail(String email, String link);
}
