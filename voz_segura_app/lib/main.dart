import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/core/theme/app_theme.dart';
import 'src/features/auth/presentation/login_page.dart';
import 'src/features/auth/presentation/register_page.dart';
import 'src/features/contacts/presentation/emergency_contacts_page.dart';
import 'src/features/sos/presentation/home_page.dart';

// Configurações do projeto Firebase
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
  
  runApp(
    const ProviderScope(
      child: MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Voz Segura',
      theme: AppTheme.lightTheme,
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/registro': (context) => const RegisterPage(),
        '/contacts': (context) => const EmergencyContactsPage(),
        '/home': (context) => const HomePage(),
      },
    );
  }
}
