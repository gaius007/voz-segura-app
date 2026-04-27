import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'login_page.dart';
import 'register_page.dart';

// Configurações do projeto Firebase (obtidas do Console do Firebase)
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
  // Garante que o Flutter esteja inicializado antes de rodar o Firebase
  WidgetsFlutterBinding.ensureInitialized();
  
  // Conecta o aplicativo ao Firebase com as configurações acima
  await Firebase.initializeApp(options: firebaseConfig);
  
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Voz Segura',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // Define a rota que abrirá primeiro ao iniciar o app
      initialRoute: '/login',
      
      // Mapeamento das telas do aplicativo
      routes: {
        '/login': (context) => const LoginPage(),       // Tela de Login
        '/registro': (context) => const RegisterPage(), // Tela de Cadastro
        '/home': (context) => const HomePage(),         // Tela Principal (pós-login)
      },
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Início"),
        actions: [
          IconButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
            icon: const Icon(Icons.logout),
          )
        ],
      ),
      body: const Center(
        child: Text("Bem-vindo ao Voz Segura!"),
      ),
    );
  }
}
