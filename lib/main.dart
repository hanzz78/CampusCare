import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart'; // Import Firebase

// Import folder yang sudah kita buat tadi
import 'providers/auth_provider.dart';
import 'providers/admin_dashboard_provider.dart';
import 'providers/feed_provider.dart';
import 'providers/report_form_provider.dart';
import 'screens/landing_screen.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/admin/admin_shell_screen.dart';

import 'package:flutter/foundation.dart'; // import kDebugMode
import 'package:flutter_dotenv/flutter_dotenv.dart'; // import dotenv
import 'package:supabase_flutter/supabase_flutter.dart'; // import Supabase
import 'services/mongo_service.dart'; // import MongoService
import 'services/hive_service.dart';
import 'services/network_connectivity_service.dart';

// Global Navigator Key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  // Langsung jalankan inisialisasi dasar secepat mungkin
  WidgetsFlutterBinding.ensureInitialized();

  // Load lokal yang sangat cepat (<10ms)
  await dotenv.load(fileName: ".env");
  await HiveService().init();
  NetworkConnectivityService().startListening();

  // Firebase butuh di-await tapi biasanya sangat cepat
  try {
    await Firebase.initializeApp();
  } catch (e) {
    if (kDebugMode) print('Firebase init failed: $e');
  }

  // Supabase & MongoDB di-background agar tidak menahan layar utama
  Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  ).catchError((e) {
    if (kDebugMode) print('Supabase init failed: $e');
  });

  MongoService().connect().catchError((e) {
    if (kDebugMode) print('MongoDB connect failed: $e');
  });

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
      navigatorKey: navigatorKey,
      title: 'CampusCare Polban',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: Consumer<AuthProvider>(
        builder: (context, auth, child) {
          // Selama session sedang dicek, jangan tampilkan apa-apa agar terasa instant
          if (!auth.isSessionChecked) {
            return const Scaffold(backgroundColor: Colors.white);
          }

          // Auto Routing: Kalau udah login, lempar ke Dashboard. Kalau belum, ke Landing.
          if (auth.isLoggedIn) {
            if (auth.role == 'Penanggung Jawab') {
              return const AdminShellScreen();
            }
            return DashboardScreen(role: auth.role);
          }
          return const LandingScreen();
        },
      ),
    );
  }
}
