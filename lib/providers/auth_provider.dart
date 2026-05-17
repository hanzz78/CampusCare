import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/mongo_service.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  bool _isLoading = false;
  bool _isLoggedIn = false;
  String _role = 'user'; // Default role
  String? _userId;
  String? _profileImageUrl;
  String? _cachedEmail;
  String? _cachedName;

  // Getters supaya bisa dibaca oleh UI
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  String get role => _role;
  String? get userId => _userId;
  String? get profileImageUrl => _profileImageUrl;
  String? get email => _auth.currentUser?.email ?? _cachedEmail;
  String? get displayName => _auth.currentUser?.displayName ?? _cachedName;

  // Cek apakah user sudah login sebelumnya saat aplikasi dibuka
  Future<void> checkSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      _role = prefs.getString('userRole') ?? 'user';
      _userId = prefs.getString('userId');
      _cachedEmail = prefs.getString('cachedEmail');
      _cachedName = prefs.getString('cachedName');
      final savedProfileImg = prefs.getString('profileImageUrl');
      if (savedProfileImg != null && savedProfileImg.isNotEmpty) {
        _profileImageUrl = savedProfileImg;
      }
    } catch (e) {
      debugPrint('checkSession error: $e');
      _isLoggedIn = false;
      _role = 'user';
      _userId = null;
      _profileImageUrl = null;
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
          _userId = (userDoc['_id'] as ObjectId).toHexString();
          _role = userDoc['role'] ?? 'User';
          _profileImageUrl = userDoc['profileImageUrl'];
          _isLoggedIn = true;
          
          // Simpan status di SharedPreferences agar tidak hilang saat restart
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('userRole', _role);
          await prefs.setString('userId', _userId!);
          if (_profileImageUrl != null) await prefs.setString('profileImageUrl', _profileImageUrl!);
          await prefs.setBool('isLoggedIn', true);
          
          print("Login berhasil via MongoDB! Role: $_role");
        } else {
          // 👤 USER BELUM ADA DI MONGODB -> OTOMATIS DAFTAR
          final newObjectId = ObjectId();
          final newUserDoc = {
            '_id': newObjectId,
            'email': user.email,
            'nama': user.displayName ?? 'Pengguna',
            'prodi': 'Tidak Diketahui',
            'role': 'User', // Role bawaan
            'isActive': true,
            'lastLogin': DateTime.now(),
            'createdAt': DateTime.now(),
            'updatedAt': DateTime.now(),
          };

          await MongoService().createUser(newUserDoc);

          _userId = newObjectId.toHexString();
          _isLoggedIn = true; 
          _role = 'User';
          _profileImageUrl = null;

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('userRole', _role);
          await prefs.setString('userId', _userId!);
          await prefs.setString('profileImageUrl', '');
          await prefs.setBool('isLoggedIn', true);
          await prefs.setString('cachedEmail', user.email ?? '');
          await prefs.setString('cachedName', user.displayName ?? 'Pengguna');

          print("Pendaftaran otomatis berhasil via MongoDB! Role: $_role");
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
    await prefs.remove('isLoggedIn');
    await prefs.remove('userRole');
    await prefs.remove('userId');
    await prefs.remove('profileImageUrl');
    await prefs.remove('cachedEmail');
    await prefs.remove('cachedName');
    
    _isLoggedIn = false;
    _role = 'user';
    _userId = null;
    _profileImageUrl = null;
    notifyListeners();
  }

  // Fungsi Baru: Upload Foto Profil
  Future<void> updateProfileImage(File imageFile) async {
    if (_userId == null) throw Exception("User ID tidak ditemukan");
    
    _isLoading = true;
    notifyListeners();

    try {
      final supabase = Supabase.instance.client;
      final fileName = 'profile_$_userId-${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      // Upload ke bucket profile_image (seperti yang dibuat user)
      await supabase.storage.from('profile_image').uploadBinary(
            fileName,
            await imageFile.readAsBytes(),
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );
          
      final imageUrl = supabase.storage.from('profile_image').getPublicUrl(fileName);

      // Update MongoDB
      await MongoService().updateUser(_userId!, {'profileImageUrl': imageUrl});

      // Update local state & SharedPreferences
      _profileImageUrl = imageUrl;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profileImageUrl', imageUrl);

    } catch (e) {
      debugPrint("Error updating profile image: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}