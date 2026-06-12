import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'src/features/auth/data/auth_repository.dart';
import 'src/features/auth/domain/auth_repository.dart';
import 'src/features/auth/domain/app_user.dart';
import 'src/features/auth/presentation/login_page.dart';
import 'src/features/contacts/data/repositories/contact_repository_impl.dart';
import 'src/features/contacts/domain/repositories/contact_repository.dart';
import 'src/features/contacts/domain/usecases/watch_contacts.dart';
import 'src/features/contacts/domain/usecases/add_contact.dart';
import 'src/features/contacts/domain/usecases/update_contact.dart';
import 'src/features/contacts/domain/usecases/delete_contact.dart';
import 'src/features/reports/data/repositories/report_repository_impl.dart';
import 'src/features/reports/data/repositories/comment_repository_impl.dart';
import 'src/features/reports/domain/repositories/report_repository.dart';
import 'src/features/reports/domain/repositories/comment_repository.dart';
import 'src/features/reports/domain/usecases/create_report.dart';
import 'src/features/reports/domain/usecases/get_reports.dart';
import 'src/features/reports/domain/usecases/update_report.dart';
import 'src/features/reports/domain/usecases/delete_report.dart';
import 'src/features/reports/domain/usecases/add_comment.dart';
import 'src/features/reports/domain/usecases/watch_comments.dart';
import 'src/features/reports/domain/usecases/delete_comment.dart';
import 'src/features/reports/presentation/manager/report_notifier.dart';
import 'src/features/sos/data/services/location_service_impl.dart';
import 'src/features/sos/domain/services/location_service.dart';
import 'src/features/sos/data/repositories/sos_sender_repository_impl.dart';
import 'src/features/sos/domain/repositories/sos_sender_repository.dart';
import 'src/features/sos/domain/usecases/send_sos_alert.dart';
import 'src/features/sos/presentation/sos_notifier.dart';
import 'src/features/map/data/repositories/panic_alert_repository_impl.dart';
import 'src/features/map/domain/repositories/panic_alert_repository.dart';
import 'src/features/map/data/repositories/support_point_repository_impl.dart';
import 'src/features/map/data/repositories/cached_support_point_repository.dart';
import 'src/features/map/domain/repositories/support_point_repository.dart';
import 'src/features/map/domain/usecases/create_panic_alert.dart';
import 'src/features/map/domain/usecases/resolve_panic_alert.dart';
import 'src/features/map/domain/usecases/watch_active_alerts.dart';
import 'src/features/map/domain/usecases/get_support_points.dart';
import 'src/features/map/presentation/manager/panic_alert_notifier.dart';
import 'src/features/shared/navigation/main_navigation_page.dart';
import 'src/core/security/local_auth_service.dart';
import 'src/core/theme/app_theme.dart';
import 'src/core/theme/theme_notifier.dart';
import 'src/features/shared/camouflage/camouflage_notifier.dart';
import 'src/features/shared/camouflage/camouflage_view.dart';

import 'src/core/config/app_config.dart';

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

  final prefs = await SharedPreferences.getInstance();

  // Resolve dinamicamente a URL do servidor proxy local rodando em tunnel público.
  // Roda em background (sem bloquear o primeiro frame): a URL de fallback local já é
  // o valor padrão, então o comportamento é idêntico — a resolução apenas conclui depois.
  AppConfig.loadDynamicBackendUrl();

  runApp(
    MultiProvider(
      providers: [
        Provider<SharedPreferences>.value(value: prefs),
        ChangeNotifierProvider(create: (_) => CamouflageNotifier(prefs)),
        ChangeNotifierProvider(create: (_) => ThemeNotifier(prefs)),
      ],
      child: const VozSeguraApp(),
    ),
  );
}

class VozSeguraApp extends StatelessWidget {
  const VozSeguraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthRepository>(create: (_) => AuthRepositoryImpl()),
        Provider<LocalAuthService>(create: (_) => LocalAuthService()),
        Provider<ReportRepository>(create: (_) => ReportRepositoryImpl()),
        Provider<ContactRepository>(create: (_) => ContactRepositoryImpl()),
        Provider<LocationService>(create: (_) => LocationServiceImpl()),
        Provider<SosSenderRepository>(create: (_) => SosSenderRepositoryImpl()),
        Provider<PanicAlertRepository>(create: (_) => PanicAlertRepositoryImpl()),
        // POIs com cache local por região (Overpass é gratuita e tem rate limit)
        Provider<SupportPointRepository>(
          create: (context) => CachedSupportPointRepository(
            SupportPointRepositoryImpl(),
            context.read<SharedPreferences>(),
          ),
        ),

        ProxyProvider<ContactRepository, WatchContacts>(
          update: (_, repo, __) => WatchContacts(repo),
        ),
        ProxyProvider<ContactRepository, AddContact>(
          update: (_, repo, __) => AddContact(repo),
        ),
        ProxyProvider<ContactRepository, UpdateContact>(
          update: (_, repo, __) => UpdateContact(repo),
        ),
        ProxyProvider<ContactRepository, DeleteContact>(
          update: (_, repo, __) => DeleteContact(repo),
        ),

        ProxyProvider<ReportRepository, CreateReport>(
          update: (_, repo, __) => CreateReport(repo),
        ),
        ProxyProvider<ReportRepository, GetReports>(
          update: (_, repo, __) => GetReports(repo),
        ),
        ProxyProvider<ReportRepository, UpdateReport>(
          update: (_, repo, __) => UpdateReport(repo),
        ),
        ProxyProvider<ReportRepository, DeleteReport>(
          update: (_, repo, __) => DeleteReport(repo),
        ),

        Provider<CommentRepository>(create: (_) => CommentRepositoryImpl()),
        ProxyProvider<CommentRepository, AddComment>(
          update: (_, repo, __) => AddComment(repo),
        ),
        ProxyProvider<CommentRepository, WatchComments>(
          update: (_, repo, __) => WatchComments(repo),
        ),
        ProxyProvider<CommentRepository, DeleteComment>(
          update: (_, repo, __) => DeleteComment(repo),
        ),

        ProxyProvider3<LocationService, ContactRepository, SosSenderRepository, SendSOSAlert>(
          update: (_, location, contacts, sender, __) => SendSOSAlert(
            locationService: location,
            contactRepository: contacts,
            sender: sender,
          ),
        ),

        ProxyProvider<PanicAlertRepository, CreatePanicAlert>(
          update: (_, repo, __) => CreatePanicAlert(repo),
        ),
        ProxyProvider<PanicAlertRepository, ResolvePanicAlert>(
          update: (_, repo, __) => ResolvePanicAlert(repo),
        ),
        ProxyProvider<PanicAlertRepository, WatchActiveAlerts>(
          update: (_, repo, __) => WatchActiveAlerts(repo),
        ),
        ProxyProvider<SupportPointRepository, GetSupportPoints>(
          update: (_, repo, __) => GetSupportPoints(repo),
        ),
        ChangeNotifierProvider<SOSNotifier>(
          create: (context) => SOSNotifier(
            sendSOSAlertUseCase: context.read<SendSOSAlert>(),
            locationService: context.read<LocationService>(),
            authRepository: context.read<AuthRepository>(),
          ),
        ),
        ChangeNotifierProvider<ReportNotifier>(
          create: (context) => ReportNotifier(
            createReportUseCase: context.read<CreateReport>(),
            getReportsUseCase: context.read<GetReports>(),
            updateReportUseCase: context.read<UpdateReport>(),
            deleteReportUseCase: context.read<DeleteReport>(),
          ),
        ),
        ChangeNotifierProvider<PanicAlertNotifier>(
          create: (context) => PanicAlertNotifier(
            createPanicAlert: context.read<CreatePanicAlert>(),
            resolvePanicAlert: context.read<ResolvePanicAlert>(),
            watchActiveAlerts: context.read<WatchActiveAlerts>(),
            locationService: context.read<LocationService>(),
            authRepository: context.read<AuthRepository>(),
          ),
        ),
      ],
      child: Builder(
        builder: (context) {
          final themeNotifier = context.watch<ThemeNotifier>();
          return MaterialApp(
            title: 'Voz Segura App',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeNotifier.themeMode,
            home: const AuthWrapper(),
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authRepo = context.watch<AuthRepository>();
    final isCamouflaged = context.watch<CamouflageNotifier>().isCamouflaged;

    if (isCamouflaged) {
      return const CamouflageView();
    }
    
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
