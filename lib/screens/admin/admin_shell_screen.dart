import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/admin_dashboard_provider.dart';
import '../../services/mongo_service.dart';
import '../login_screen.dart';
import 'admin_home_tab.dart';
import 'admin_all_reports_tab.dart';
import '../tabs/profile_tab.dart'; // Reuse the user's profile tab, or we can make a custom one if needed. Here we reuse it since logic is mostly the same.

class AdminShellScreen extends StatefulWidget {
  const AdminShellScreen({super.key});

  @override
  State<AdminShellScreen> createState() => _AdminShellScreenState();
}

class _AdminShellScreenState extends State<AdminShellScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F3EC),
      appBar: _selectedIndex == 0
          ? null
          : AppBar(
              title: Text(
                _selectedIndex == 1
                    ? 'Menunggu Tindakan'
                    : _selectedIndex == 2
                        ? 'Selesai Direview'
                        : 'Profil Saya',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
              ),
              backgroundColor: const Color(0xFF3B696D),
              iconTheme: const IconThemeData(color: Colors.white),
            ),
      body: ValueListenableBuilder<bool>(
        valueListenable: MongoService().isConnected,
        builder: (context, isConnected, child) {
          if (!isConnected) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Color(0xFFE09F3E),
                    strokeWidth: 3,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Menyambungkan ke database...',
                    style: TextStyle(
                      color: Color(0xFF335C67),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }
          return IndexedStack(
            index: _selectedIndex,
            children: const [
              AdminHomeTab(),
              AdminAllReportsTab(), // for Pending
              AdminAllReportsTab(), // for Reviewed
              ProfileTab(), // Reuse user's profile tab, or create AdminProfileTab if needed
            ],
          );
        },
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            final provider = context.read<AdminDashboardProvider>();
            if (index == 1) {
              provider.setAdminActionTab('Menunggu Tindakan');
            } else if (index == 2) {
              provider.setAdminActionTab('Selesai Direview');
            }
            setState(() {
              _selectedIndex = index;
            });
          },
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF3B696D),
          unselectedItemColor: Colors.grey,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.pending_actions_outlined),
              activeIcon: Icon(Icons.pending_actions),
              label: 'Menunggu',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.fact_check_outlined),
              activeIcon: Icon(Icons.fact_check),
              label: 'Selesai',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}
