import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

        // --- PROSES VALIDASI ROLE (EKSKLUSIF) ---
        
        // 1. Cek apakah email ada di koleksi admin_whitelist?
        final adminDoc = await _db.collection('admin_whitelist').doc(user.email).get();

        if (adminDoc.exists) {
          // 🎉 DIA ADALAH PENANGGUNG JAWAB (ADMIN)
          _role = 'Admin';
          _isLoggedIn = true;
          
          // Simpan status admin di SharedPreferences agar tidak hilang saat restart
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('userRole', 'Admin');
          await prefs.setBool('isLoggedIn', true);
          
          print("Login sebagai Admin terdeteksi!");
        } else {
          // 👤 DIA ADALAH PELAPOR (MAHASISWA/DOSEN)
          // Cek apakah dia sudah pernah mengisi profil (NIM/NIP)?
          final userDoc = await _db.collection('users').doc(user.uid).get();

          if (userDoc.exists) {
            _role = userDoc.data()?['role'] ?? 'Mahasiswa';
            _isLoggedIn = true;
            
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('userRole', _role!);
            await prefs.setBool('isLoggedIn', true);
          } else {
            // User baru, role belum ditentukan (nanti di CompleteProfileScreen)
            _isLoggedIn = false; 
            _role = 'user';
          }
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
        // Simpan ke Firestore
        await _db.collection('users').doc(user.uid).set({
          'role': role, // Bisa 'Mahasiswa' atau 'Dosen'
          'isStaff': false, // Keduanya bukan staf admin, jadi false
          'id_kampus': identitas, // Ganti nama field jadi id_kampus agar fleksibel
          'prodi': prodi,
          'angkatan': angkatan,
          'email': user.email,
          'displayName': user.displayName,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Simpan Sesi Lokal
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('userRole', role);

        _isLoggedIn = true;
        _role = role;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fungsi Logout
  Future<void> logout() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    
    _isLoggedIn = false;
    _role = 'user';
    notifyListeners();
  }
}