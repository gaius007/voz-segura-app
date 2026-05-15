import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

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
import 'src/core/theme/app_theme.dart';

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
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: firebaseConfig);
  runApp(const VozSeguraApp());
}

class VozSeguraApp extends StatelessWidget {
  const VozSeguraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => AuthRepository()),
        Provider(create: (_) => ReportRepositoryImpl()),
        Provider(create: (_) => ContactRepository()),
        
        ProxyProvider<ReportRepositoryImpl, CreateReport>(
          update: (_, repo, __) => CreateReport(repo),
        ),
        ProxyProvider<ReportRepositoryImpl, GetReports>(
          update: (_, repo, __) => GetReports(repo),
        ),
        
        ChangeNotifierProxyProvider2<AuthRepository, ContactRepository, SOSNotifier>(
          create: (context) => SOSNotifier(
            authRepository: context.read<AuthRepository>(),
            contactRepository: context.read<ContactRepository>(),
          ),
          update: (_, auth, contacts, sos) => sos!,
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
        theme: AppTheme.lightTheme,
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authRepo = context.watch<AuthRepository>();
    
    return StreamBuilder<AppUser?>(
      stream: authRepo.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        
        if (snapshot.hasData) {
          return const MainNavigationPage();
        }
        
        return const LoginPage();
      },
    );
  }
}
