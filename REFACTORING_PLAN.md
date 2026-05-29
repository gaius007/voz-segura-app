# Plano de Refatoração Arquitetural - Voz Segura 🚀

Este documento serve como um guia técnico detalhado e roadmap para a refatoração do aplicativo **Voz Segura**. Ele descreve os pontos de acoplamento atuais (dívida técnica do MVP) e prescreve **o que**, **como** e **com base em que princípios** cada módulo deve ser refatorado para atingir 100% de alinhamento com a **Feature-First Clean Architecture**.

---

## 1. Mapeamento Geral do Estado Atual

| Funcionalidade | Estado Atual | Classificação | Objetivo de Destino |
| :--- | :--- | :--- | :--- |
| **`reports` (Relatos)** | Clean Architecture completa, mas com leve acoplamento na injeção. | 🟢 **Gabarito** | Purismo total na Inversão de Dependência. |
| **`auth` (Login)** | Possui interface no Domain, mas a classe concreta de Data não a assina e é consumida diretamente. | 🟡 **Desvio Leve** | Renomear para `AuthRepositoryImpl`, implementar o contrato do Domain e refatorar as chamadas. |
| **`contacts` (Contatos)**| Sem camada Domain de repositório/usecases. Classe de dados consumida diretamente. | 🔴 **Acoplamento Médio** | Introduzir contratos no Domain e criar Casos de Uso individuais. |
| **`sos` (Pânico)** | Sem camada Domain. Lógica pesada de GPS, APIs e MethodChannels rodando direto na UI (Notifier). | 🔴 **Acoplamento Alto** | Extrair lógica para Casos de Uso e isolar conexões de hardware em Serviços do Data. |

---

## 2. Roteiro Detalhado de Refatoração por Módulo

### 🔑 Módulo 1: `auth` (Autenticação)
* **Princípio Violado:** Ocultação de Implementação e Programação Voltada à Interface. A camada de Apresentação e Notifiers conhecem a classe concreta do Firebase (`AuthRepository` de Data).
* **Como Refatorar:**
  1. No arquivo [auth_repository.dart (Data)](file:///mnt/HD/Fatec/5° Semestre/Programação para Disp./voz-segura-app/lib/src/features/auth/data/auth_repository.dart), renomeie a classe de `AuthRepository` para `AuthRepositoryImpl`.
  2. Importe a interface abstrata do Domain e faça a assinatura do contrato:
     ```dart
     import '../domain/auth_repository.dart';
     
     class AuthRepositoryImpl implements AuthRepository {
       // ...
     }
     ```
  3. Renomeie os métodos da implementação concreta para coincidir exatamente com as assinaturas exigidas na interface do Domain (ex: mudar `signIn` para `signInWithEmailAndPassword`).
  4. No arquivo de injeção de dependências [main.dart](file:///mnt/HD/Fatec/5° Semestre/Programação para Disp./voz-segura-app/lib/main.dart), altere o tipo exposto pelo Provider para expor a abstração:
     ```dart
     // Antes: Provider(create: (_) => AuthRepository())
     // Depois:
     Provider<AuthRepository>(create: (_) => AuthRepositoryImpl()),
     ```
  5. Nas páginas (`login_page.dart`, `register_page.dart`) e nos outros Notifiers, altere os `imports` para importar apenas a pasta `domain` de autenticação. A UI nunca mais deve tocar na pasta `data/auth_repository.dart` diretamente.

---

### 👥 Módulo 2: `contacts` (Contatos de Emergência)
* **Princípio Violado:** Isolamento de Regras de Negócio (Camada Domain inexistente para repositório).
* **Como Refatorar:**
  1. Crie a pasta `lib/src/features/contacts/domain/repositories/`.
  2. Crie o arquivo `contact_repository.dart` no Domain contendo a interface abstrata com os contratos necessários:
     ```dart
     import '../entities/contact.dart';
     
     abstract class ContactRepository {
       Stream<List<Contact>> watchContacts(String userId);
       Future<void> addContact(String userId, Contact contact);
       Future<void> updateContact(String userId, Contact contact);
       Future<void> deleteContact(String userId, String contactId);
     }
     ```
  3. Mova o repositório de dados atual de `contacts/data/contact_repository.dart` para `contacts/data/repositories/contact_repository_impl.dart`.
  4. Faça o repositório concreto assinar a interface:
     ```dart
     import '../../domain/repositories/contact_repository.dart';
     
     class ContactRepositoryImpl implements ContactRepository {
       // ...
     }
     ```
  5. Crie a pasta `lib/src/features/contacts/domain/usecases/` e extraia a lógica de manipulação para casos de uso atômicos (ex: `AddContactUseCase`, `DeleteContactUseCase`).
  6. Altere a injeção no `main.dart` para prover a interface:
     ```dart
     Provider<ContactRepository>(create: (_) => ContactRepositoryImpl()),
     ```

---

### 🚨 Módulo 3: `sos` (Botão de Pânico / Emergência)
* **Princípio Violado:** Princípio da Responsabilidade Única (SRP). O `sos_notifier.dart` é uma *God Class* que gerencia estado de tela, lê GPS, chama MethodChannels nativos de SMS e consome APIs de rede em paralelo.
* **Como Refatorar:**
  1. **Isolar Geolocalização (GPS):**
     * Crie um contrato de serviço no Domain: `lib/src/features/sos/domain/services/location_service.dart` (`abstract class LocationService`).
     * Crie a implementação concreta usando a biblioteca Geolocator em Data: `lib/src/features/sos/data/services/location_service_impl.dart`.
  2. **Isolar Envio de Alertas (Rede/Nativo):**
     * Crie uma interface abstrata de envio: `lib/src/features/sos/domain/repositories/sos_sender_repository.dart` com os métodos `sendWhatsApp`, `sendSMS` e `sendEmail`.
     * Mova as conexões HTTP (Brevo API), integrações silenciosas (Evolution API) e o canal nativo Android/iOS (`MethodChannel('com.example.voz_segura_app/sms')`) para a implementação concreta em Data: `lib/src/features/sos/data/repositories/sos_sender_repository_impl.dart`.
  3. **Criar Caso de Uso no Domain:**
     * Crie a classe `SendSOSAlert` em `lib/src/features/sos/domain/usecases/send_sos_alert.dart`.
     * Este Usecase será o orquestrador puro da regra de negócio: ele chamará o `LocationService` para obter o GPS, buscará os contatos de emergência e disparará a execução concorrente usando o `SOSSenderRepository`.
  4. **Limpar a Apresentação (`sos_notifier.dart`):**
     * Remova todas as importações de Geolocator, HTTP, MethodChannel e Permission Handler do Notifier.
     * O Notifier deve apenas receber o Usecase via construtor e executá-lo, atualizando as variáveis de UI `isLoading` e `statusMessage` de forma reativa e limpa.

---

## 3. Ajuste Fino Globais (Inversão de Dependência no `main.dart`)

Mesmo no módulo de **Relatos (Reports)** que é o mais maduro, existe um acoplamento na injeção que precisa ser corrigido para respeitar o **DIP (Dependency Inversion Principle)**:

* **Como está hoje (main.dart):**
  ```dart
  Provider(create: (_) => ReportRepositoryImpl()),
  ProxyProvider<ReportRepositoryImpl, CreateReport>(
    update: (_, repo, __) => CreateReport(repo),
  ),
  ```
* **Como deve ficar após a refatoração:**
  ```dart
  Provider<ReportRepository>(create: (_) => ReportRepositoryImpl()),
  ProxyProvider<ReportRepository, CreateReport>(
    update: (_, repo, __) => CreateReport(repo),
  ),
  ```
  *(Dessa forma, o Usecase `CreateReport` é alimentado com a abstração `ReportRepository`, permitindo a substituição por mocks de teste com facilidade absoluta).*

---

## 4. O que ganhamos com essa refatoração? (Justificativa para a Banca)

1. **Testabilidade Absoluta:** Conseguimos simular disparos de SOS em testes unitários sem abrir apps nativos, sem precisar de permissões de hardware no computador de desenvolvimento e sem gastar créditos de APIs REST de e-mail.
2. **Resiliência a Mudanças de Bibliotecas:** Se decidirmos trocar o pacote `geolocator` por outra biblioteca de GPS, alteraremos apenas o arquivo `location_service_impl.dart`. O cérebro do SOS e a UI do botão de pânico permanecerão intactos.
3. **Legibilidade de Código:** O arquivo `sos_notifier.dart` reduzirá seu tamanho de **400 linhas para menos de 60 linhas**, facilitando imensamente a identificação de bugs visuais.
