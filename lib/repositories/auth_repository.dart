import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';
import '../utils/dio_client.dart';
import 'dart:convert';

class AuthRepository {
  final Dio _dio = DioClient.instance.dio;

  /// Signup - Créer un utilisateur
  Future<Map<String, dynamic>> signup({
    required String nom,
    required String email,
    required String motdepasse,
    required String confirmMotdepasse,
    required String role,
    required String poste,
    required String departement,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.signup,
        data: {
          'nom': nom,
          'email': email,
          'motdepasse': motdepasse,
          'confirmMotdepasse': confirmMotdepasse,
          'role': role,
          'poste': poste,
          'departement': departement,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Login - Connexion utilisateur
  Future<UserModel> login(String email, String motdepasse) async {
    try {
      print('🔐 Login attempt for: $email');

      final response = await _dio.post(
        ApiConstants.login,
        data: {'email': email, 'motdepasse': motdepasse},
      );

      final data = response.data;
      print('📥 Login response keys: ${data.keys}');

      // ⚠️ CORRECTION: Le backend retourne 'access_token' (underscore), pas 'accessToken' (camelCase)
      final accessToken = data['access_token'] ?? data['accessToken'];
      final refreshToken = data['refresh_token'] ?? data['refreshToken'];
      final userData = data['user'];

      if (accessToken == null) {
        throw Exception('Token non reçu du serveur');
      }

      if (userData == null) {
        throw Exception('Données utilisateur non reçues du serveur');
      }

      // Vérifier que le rôle est présent
      if (userData['role'] == null) {
        print('⚠️ WARNING: User data does not contain role!');
        print('⚠️ User data: $userData');
      }

      print('✅ Access token received: ${accessToken.substring(0, 20)}...');
      print('✅ User role: ${userData['role']}');

      // Sauvegarder le token dans DioClient (pour les requêtes futures)
      await DioClient.instance.saveToken(accessToken);

      // Sauvegarder aussi dans SharedPreferences pour compatibilité
      await _saveAuthData(
        accessToken: accessToken,
        refreshToken: refreshToken,
        userData: userData,
      );

      // Décoder et vérifier le token
      _verifyTokenContainsRole(accessToken);

      return UserModel.fromJson(userData);
    } on DioException catch (e) {
      print('❌ Login error: ${e.message}');
      throw _handleError(e);
    }
  }

  /// Sauvegarder les données d'authentification
  Future<void> _saveAuthData({
    required String accessToken,
    String? refreshToken,
    required Map<String, dynamic> userData,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Sauvegarder les tokens
      await prefs.setString(StorageKeys.accessToken, accessToken);
      if (refreshToken != null) {
        await prefs.setString(StorageKeys.refreshToken, refreshToken);
      }

      // Sauvegarder les infos utilisateur
      await prefs.setString(StorageKeys.userId, userData['id'] ?? userData['_id']);
      await prefs.setString(StorageKeys.userName, userData['nom'] ?? '');
      await prefs.setString(StorageKeys.userEmail, userData['email'] ?? '');
      await prefs.setString(StorageKeys.userRole, userData['role'] ?? '');

      if (userData['poste'] != null) {
        await prefs.setString('user_poste', userData['poste']);
      }
      if (userData['departement'] != null) {
        await prefs.setString('user_departement', userData['departement']);
      }

      await prefs.setBool(StorageKeys.isLoggedIn, true);

      print('✅ Auth data saved successfully');
    } catch (e) {
      print('❌ Error saving auth data: $e');
    }
  }

  /// Vérifier que le token contient le rôle
  void _verifyTokenContainsRole(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        print('⚠️ Invalid token format');
        return;
      }

      // Décoder le payload
      final payload = parts[1];
      final normalizedPayload = base64Url.normalize(payload);
      final payloadString = utf8.decode(base64Url.decode(normalizedPayload));
      final payloadMap = jsonDecode(payloadString);

      print('🔍 Token payload:');
      print('   - userId: ${payloadMap['userId'] ?? payloadMap['sub']}');
      print('   - email: ${payloadMap['email']}');
      print('   - nom: ${payloadMap['nom']}');
      print('   - role: ${payloadMap['role']}');
      print('   - poste: ${payloadMap['poste']}');

      if (payloadMap['role'] == null) {
        print('⚠️⚠️⚠️ CRITICAL: Token does NOT contain role!');
        print('⚠️ Full payload: $payloadMap');
        print('⚠️ You need to update your backend to include role in JWT');
      } else {
        print('✅ Token contains role: ${payloadMap['role']}');
      }
    } catch (e) {
      print('⚠️ Could not decode token: $e');
    }
  }

  /// Forgot Password
  Future<String> forgotPassword(String email) async {
    try {
      final response = await _dio.post(
        '/auth/forgot-password',
        data: {'email': email},
      );
      return response.data['userId'];
    } on DioException catch (e) {
      throw Exception(
          e.response?.data['message'] ?? 'Erreur lors de la demande de réinitialisation'
      );
    }
  }

  /// Verify OTP
  Future<void> verifyOtp(String userId, String otp) async {
    try {
      await _dio.post(
        '/auth/verify-otp/$userId',
        data: {'otp': otp},
      );
    } on DioException catch (e) {
      throw Exception(
          e.response?.data['message'] ?? 'Code OTP invalide ou expiré'
      );
    }
  }

  /// Reset Password
  Future<void> resetPassword(String userId, String password) async {
    try {
      await _dio.post(
        '/auth/reset-password/$userId',
        data: {'password': password},
      );
    } on DioException catch (e) {
      throw Exception(
          e.response?.data['message'] ?? 'Erreur lors du changement de mot de passe'
      );
    }
  }

  /// Refresh Token
  Future<String> refreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString(StorageKeys.refreshToken);

      if (refreshToken == null) {
        throw Exception('Aucun refresh token disponible');
      }

      final response = await _dio.post(
        ApiConstants.refreshToken,
        data: {'refresh_token': refreshToken},
      );

      final newAccessToken = response.data['access_token'] ?? response.data['accessToken'];

      if (newAccessToken == null) {
        throw Exception('Nouveau token non reçu');
      }

      // Sauvegarder le nouveau token
      await DioClient.instance.saveToken(newAccessToken);
      await prefs.setString(StorageKeys.accessToken, newAccessToken);

      return newAccessToken;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Récupérer les infos utilisateur stockées
  Future<Map<String, dynamic>?> getUserInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(StorageKeys.userId);

      if (userId == null) return null;

      return {
        'id': userId,
        'nom': prefs.getString(StorageKeys.userName),
        'email': prefs.getString(StorageKeys.userEmail),
        'role': prefs.getString(StorageKeys.userRole),
        'poste': prefs.getString('user_poste'),
        'departement': prefs.getString('user_departement'),
      };
    } catch (e) {
      print('❌ Error getting user info: $e');
      return null;
    }
  }

  /// Vérifier si l'utilisateur est connecté
  Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(StorageKeys.isLoggedIn) ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Déconnexion
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Supprimer toutes les données
      await prefs.remove(StorageKeys.accessToken);
      await prefs.remove(StorageKeys.refreshToken);
      await prefs.remove(StorageKeys.userId);
      await prefs.remove(StorageKeys.userName);
      await prefs.remove(StorageKeys.userEmail);
      await prefs.remove(StorageKeys.userRole);
      await prefs.remove('user_poste');
      await prefs.remove('user_departement');
      await prefs.setBool(StorageKeys.isLoggedIn, false);

      // Nettoyer le token dans DioClient
      await DioClient.instance.clearToken();

      print('✅ Logout successful');
    } catch (e) {
      print('❌ Error during logout: $e');
    }
  }

  /// Gestion des erreurs
  Exception _handleError(DioException e) {
    if (e.response != null) {
      final message = e.response?.data['message'] ?? 'Erreur inconnue';

      // Log détaillé pour debug
      print('❌ API Error:');
      print('   Status: ${e.response?.statusCode}');
      print('   Message: $message');
      print('   Data: ${e.response?.data}');

      return Exception(message);
    }

    print('❌ Network Error: ${e.message}');
    return Exception('Erreur réseau : ${e.message}');
  }
}