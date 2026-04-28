import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart'; 
import 'complete_profile_screen.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Login Pelaporan Polban')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.school, size: 100, color: Colors.blue),
              const SizedBox(height: 32),
              const Text(
                'Aplikasi Pelaporan Terpadu\nKampus Polban',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 48),
              
              // Tombol Login Google
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      final ap = context.read<AuthProvider>();
                      await ap.loginWithGoogle();
                  
                      if (context.mounted) {
                        if (ap.isLoggedIn) {
                          // Jika Admin atau Pelapor lama -> Langsung ke Dashboard
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => DashboardScreen(role: ap.role)),
                          );
                        } else {
                          // Jika Pelapor baru (NIM/NIP belum ada) -> Ke Complete Profile
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const CompleteProfileScreen()),
                          );
                        }
                      }
                    } catch (e) {
                      // Menampilkan pesan error jika bukan email @polban.ac.id atau gagal
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(e.toString()), 
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  icon: authProvider.isLoading 
                    ? const SizedBox.shrink() 
                    : const Icon(Icons.login),
                  label: authProvider.isLoading 
                    ? const SizedBox(
                        height: 20, 
                        width: 20, 
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                      ) 
                    : const Text('Masuk dengan Email Polban', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}