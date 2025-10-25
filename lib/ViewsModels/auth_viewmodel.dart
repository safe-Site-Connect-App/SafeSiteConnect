import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _authRepo = AuthRepository();

  bool _isLoading = false;
  String? _errorMessage;
  UserModel? _user;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  UserModel? get user => _user;
  UserModel? get currentUser => _user;
  bool get isAuthenticated => _user != null;

  /// ✅ MÉTHODE CRITIQUE: Charger les données utilisateur depuis SharedPreferences
  Future<void> loadUserFromStorage() async {
    try {
      print('🔍 [AUTH_VM] Chargement utilisateur depuis storage...');

      final userInfo = await _authRepo.getUserInfo();

      if (userInfo != null && userInfo['id'] != null) {
        _user = UserModel(
          id: userInfo['id']!,
          nom: userInfo['nom'] ?? '',
          email: userInfo['email'] ?? '',
          role: userInfo['role'] ?? '',
          poste: userInfo['poste'],
          departement: userInfo['departement'],
        );

        print('✅ [AUTH_VM] Utilisateur chargé: ${_user?.id} - ${_user?.nom}');
        notifyListeners();
      } else {
        print('⚠️ [AUTH_VM] Aucune donnée utilisateur trouvée');
        _user = null;
        notifyListeners();
      }
    } catch (e) {
      print('❌ [AUTH_VM] Erreur chargement utilisateur: $e');
      _user = null;
      notifyListeners();
    }
  }

  /// ✅ Vérifier l'authentification et charger l'utilisateur
  Future<bool> checkAuthStatus() async {
    try {
      final isLoggedIn = await _authRepo.isLoggedIn();

      if (isLoggedIn) {
        await loadUserFromStorage();
        return _user != null;
      }

      return false;
    } catch (e) {
      print('❌ [AUTH_VM] Erreur vérification auth: $e');
      return false;
    }
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _authRepo.login(email, password);
      print('✅ [AUTH_VM] Login réussi: ${_user?.id} - ${_user?.nom}');
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      print('❌ [AUTH_VM] Erreur login: $_errorMessage');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> forgotPassword(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final userId = await _authRepo.forgotPassword(email);
      return userId;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> verifyOtp(String userId, String otp) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authRepo.verifyOtp(userId, otp);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> resetPassword(String userId, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authRepo.resetPassword(userId, password);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> logout() async {
    _user = null;
    _errorMessage = null;
    await _authRepo.logout();
    notifyListeners();
  }
}

