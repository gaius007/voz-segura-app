import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

// Importando as partes do nosso projeto
import 'src/features/auth/data/auth_repository.dart';
import 'src/features/auth/domain/app_user.dart';
import 'src/features/auth/presentation/login_page.dart';
import 'src/features/contacts/data/contact_repository.dart';
import 'src/features/reports/data/repositories/report_repository_impl.dart';
import 'src/features/reports/domain/usecases/create_report.dart';
import 'src/features/reports/domain/usecases/get_reports.dart';
import 'src/features/reports/presentation/manager/report_notifier.dart';
import 'src/features/sos/presentation/sos_notifier.dart';
import 'src/features/shared/navigation/main_navigation_page.dart';

// Essa eh a config que o Firebase deu pra gente conectar o app na nuvem
const firebaseConfig = FirebaseOptions(
  apiKey: "AIzaSyAv46EF0QnhCbF83aRuvSzmezfUikmPToU",
  authDomain: "voz-segura---database.firebaseapp.com",
  projectId: "voz-segura---database",
  storageBucket: "voz-segura---database.firebasestorage.app",
  messagingSenderId: "466608093989",
  appId: "1:466608093989:web:29a210c58cfea4f48778cc",
  measurementId: "G-SY25L0GWHK"
);

void main() async {
  // Isso aqui eh obrigatorio pra iniciar o Firebase e outros plugins
  WidgetsFlutterBinding.ensureInitialized();
  
  // Conectando com o servidor do Google
  await Firebase.initializeApp(options: firebaseConfig);
  
  runApp(const VozSeguraApp());
}

class VozSeguraApp extends StatelessWidget {
  const VozSeguraApp({super.key});

  @override
  Widget build(BuildContext context) {
    // To usando o MultiProvider pra gerenciar tudo de um lugar so
    return MultiProvider(
      providers: [
        // Repositorios que cuidam da logica de salvar dados
        Provider(create: (_) => AuthRepository()),
        Provider(create: (_) => ReportRepositoryImpl()),
        Provider(create: (_) => ContactRepository()),
        
        // Casos de uso do Relato (ajuda a deixar o codigo limpo)
        ProxyProvider<ReportRepositoryImpl, CreateReport>(
          update: (_, repo, __) => CreateReport(repo),
        ),
        ProxyProvider<ReportRepositoryImpl, GetReports>(
          update: (_, repo, __) => GetReports(repo),
        ),
        
        // Notifiers que avisam as telas quando os dados mudam
        ChangeNotifierProxyProvider<AuthRepository, SOSNotifier>(
          create: (context) => SOSNotifier(authRepository: context.read<AuthRepository>()),
          update: (_, auth, sos) => sos!,
        ),
        ChangeNotifierProxyProvider2<CreateReport, GetReports, ReportNotifier>(
          create: (context) => ReportNotifier(
            createReportUseCase: context.read<CreateReport>(),
            getReportsUseCase: context.read<GetReports>(),
          ),
          update: (_, create, get, notifier) => notifier!,
        ),
      ],
      child: MaterialApp(
        title: 'Voz Segura App',
        debugShowCheckedModeBanner: false,
        // Escolhi o tema rosa pra ficar com um visual bem clean e moderno
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFFF4081),
            primary: const Color(0xFFFF4081),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          ),
        ),
        // O Wrapper decide se mostra o Login ou a Home
        home: const AuthWrapper(),
      ),
    );
  }
}

// Essa classe fica "escutando" se o usuario ta logado ou nao
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authRepo = context.watch<AuthRepository>();
    
    return StreamBuilder<AppUser?>(
      stream: authRepo.authStateChanges(),
      builder: (context, snapshot) {
        // Se o Firebase ainda ta carregando o usuario
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        
        // Se tem alguem logado, vai pro app principal
        if (snapshot.hasData) {
          return const MainNavigationPage();
        }
        
        // Se nao tiver ninguem, mostra a tela de login bonitona
        return const LoginPage();
      },
    );
  }
}
