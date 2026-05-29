import '../../../contacts/domain/repositories/contact_repository.dart';
import '../repositories/sos_sender_repository.dart';
import '../services/location_service.dart';

// Orquestrador puro da regra de negócio do SOS:
// obtém o GPS, busca os contatos de emergência e dispara os canais em paralelo.
// Não conhece UI, hardware nem detalhes de rede — só abstrações.
class SendSOSAlert {
  final LocationService locationService;
  final ContactRepository contactRepository;
  final SosSenderRepository sender;

  SendSOSAlert({
    required this.locationService,
    required this.contactRepository,
    required this.sender,
  });

  // Retorna false quando não há contatos cadastrados para notificar.
  Future<bool> execute(String userId) async {
    final position = await locationService.getCurrentPosition();
    final mapLink =
        "https://www.google.com/maps?q=${position.latitude},${position.longitude}";

    final contacts = await contactRepository.watchContacts(userId).first;
    if (contacts.isEmpty) return false;

    // Dispara SMS, WhatsApp e E-mails de forma assíncrona concorrente (paralela)
    final List<Future<void>> sendFutures = [];
    for (var contact in contacts) {
      for (var method in contact.methods) {
        if (method.type == 'WhatsApp') {
          sendFutures.add(sender.sendWhatsApp(method.value, mapLink));
        } else if (method.type == 'Telefone') {
          sendFutures.add(sender.sendSMS(method.value, mapLink));
        } else if (method.type == 'E-mail') {
          sendFutures.add(sender.sendEmail(method.value, mapLink));
        }
      }
    }

    await Future.wait(sendFutures);
    return true;
  }
}
