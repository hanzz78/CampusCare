import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/mongo_service.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  bool _isLoading = false;
  bool _isLoggedIn = false;
  String _role = 'user'; // Default role

  // Getters supaya bisa dibaca oleh UI
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  String get role => _role;
  String? get email => _auth.currentUser?.email;
  String? get displayName => _auth.currentUser?.displayName;

  // Cek apakah user sudah login sebelumnya saat aplikasi dibuka
  Future<void> checkSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      _role = prefs.getString('userRole') ?? 'user';
    } catch (e) {
      debugPrint('checkSession error: $e');
      _isLoggedIn = false;
      _role = 'user';
    }
    notifyListeners();
  }

  // Fungsi Login SSO Google (Hanya otentikasi awal, belum set status login)
  Future<void> loginWithGoogle() async {
    _isLoading = true;
    notifyListeners();

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        // --- PROSES VALIDASI EMAIL ---
        if (user.email == null || !user.email!.endsWith('@polban.ac.id')) {
          await _googleSignIn.signOut();
          await _auth.signOut();
          throw 'Harus menggunakan email @polban.ac.id';
        }

        // --- PROSES VALIDASI ROLE VIA MONGODB ---
        
        // 1. Cek apakah email ada di koleksi users MongoDB
        final userDoc = await MongoService().findUserByEmail(user.email!);

        if (userDoc != null) {
          // 🎉 USER DITEMUKAN DI MONGODB
          _role = userDoc['role'] ?? 'User';
          _isLoggedIn = true;
          
          // Simpan status di SharedPreferences agar tidak hilang saat restart
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('userRole', _role);
          await prefs.setBool('isLoggedIn', true);
          
          print("Login berhasil via MongoDB! Role: $_role");
        } else {
          // 👤 USER BELUM ADA DI MONGODB
          // User baru, role belum ditentukan (nanti di CompleteProfileScreen)
          _isLoggedIn = false; 
          _role = 'user';
        }
      }
    } catch (e) {
      print("Error Login: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fungsi Baru: Simpan Data Mahasiswa ke Firestore & Resmikan Sesi
  Future<void> completeProfile({
    required String role,
    required String identitas, // Ini bisa NIM atau NIP
    required String prodi,
    required String angkatan,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = _auth.currentUser;
      if (user != null) {
        // --- SIMPAN KE MONGODB ATLAS ---
        final newUserDoc = {
          'email': user.email,
          'nama': user.displayName ?? 'Pengguna',
          'nip': identitas, // Mengikuti penamaan di Database.md (NIP/NIM)
          'prodi': prodi,
          'role': 'User', // Sesuai Database.md, Mahasiswa/Dosen secara default adalah "User"
          'isActive': true,
          'lastLogin': DateTime.now(),
          'createdAt': DateTime.now(),
          'updatedAt': DateTime.now(),
        };

        await MongoService().createUser(newUserDoc);

        // --- Simpan Sesi Lokal ---
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('userRole', 'User');

        _isLoggedIn = true;
        _role = 'User';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fungsi Logout
  Future<void> logout() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      debugPrint('Logout firebase error: $e');
    }
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    
    _isLoggedIn = false;
    _role = 'user';
    notifyListeners();
  }
}