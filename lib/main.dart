import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart'; // Import Firebase

// Import folder yang sudah kita buat tadi
import 'providers/auth_provider.dart';
import 'providers/admin_dashboard_provider.dart';
import 'providers/feed_provider.dart';
import 'providers/report_form_provider.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/admin/admin_shell_screen.dart';

import 'package:flutter/foundation.dart'; // import kDebugMode
import 'package:flutter_dotenv/flutter_dotenv.dart'; // import dotenv
import 'services/mongo_service.dart'; // import MongoService

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Hubungkan ke MongoDB Atlas saat aplikasi menyala
  try {
    await MongoService().connect();
    if (kDebugMode) {
      print('✅ MongoDB Atlas Initialized in main()');
    }
  } catch (e) {
    if (kDebugMode) {
      print('❌ Failed to connect to MongoDB: $e');
    }
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..checkSession()),
        ChangeNotifierProvider(create: (_) => AdminDashboardProvider()),
        ChangeNotifierProvider(create: (_) => FeedProvider()),
        ChangeNotifierProvider(create: (_) => ReportFormProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CampusCare Polban',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: Consumer<AuthProvider>(
        builder: (context, auth, child) {
          // Auto Routing: Kalau udah login, lempar ke Dashboard. Kalau belum, ke Login.
          if (auth.isLoggedIn) {
            if (auth.role == 'Penanggung Jawab') {
              return const AdminShellScreen();
            }
            return DashboardScreen(role: auth.role);
          }
          return const LoginScreen();
        },
      ),
    );
  }
}