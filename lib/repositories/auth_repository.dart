import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';
import '../utils/dio_client.dart';
import 'dart:convert';

class AuthRepository {
  final Dio _dio = DioClient.instance.dio;

  /// Login - Connexion utilisateur
  Future<UserModel> login(String email, String motdepasse) async {
    try {
      print('========================================');
      print('🔐 [AUTH_REPO] Login attempt for: $email');

      final response = await _dio.post(
        ApiConstants.login,
        data: {'email': email, 'motdepasse': motdepasse},
      );

      final data = response.data;
      print('📥 [AUTH_REPO] Response status: ${response.statusCode}');
      print('📥 [AUTH_REPO] Response data: $data');

      // ⚠️ CORRECTION: Le backend retourne 'access_token' (underscore)
      final accessToken = data['access_token'] ?? data['accessToken'];
      final refreshToken = data['refresh_token'] ?? data['refreshToken'];
      final userData = data['user'];

      print('🔍 [AUTH_REPO] accessToken présent: ${accessToken != null}');
      print('🔍 [AUTH_REPO] userData présent: ${userData != null}');

      if (accessToken == null) {
        throw Exception('Token non reçu du serveur');
      }

      if (userData == null) {
        throw Exception('Données utilisateur non reçues du serveur');
      }

      // 🔍 IMPORTANT: Afficher TOUT le userData pour debug
      print('📦 [AUTH_REPO] userData complet: $userData');
      print('📦 [AUTH_REPO] userData keys: ${userData.keys}');

      // 🔥 CRITIQUE: Extraire l'userId - tester TOUTES les possibilités
      String? userId = userData['id'] ??
          userData['_id'] ??
          userData['userId'] ??
          userData['sub'];

      print('🔍 [AUTH_REPO] userId extrait de userData: $userId');

      // Si userId n'est pas dans userData, essayer de l'extraire du JWT
      if (userId == null || userId.isEmpty) {
        print('⚠️ [AUTH_REPO] userId non trouvé dans userData, extraction du JWT...');
        userId = _extractUserIdFromToken(accessToken);
        print('🔍 [AUTH_REPO] userId extrait du JWT: $userId');
      }

      // Si toujours null, c'est une erreur critique
      if (userId == null || userId.isEmpty) {
        print('❌ [AUTH_REPO] ERREUR CRITIQUE: Impossible d\'extraire userId');
        print('❌ [AUTH_REPO] userData: $userData');
        print('❌ [AUTH_REPO] Veuillez vérifier votre backend!');
        throw Exception('Impossible d\'extraire l\'ID utilisateur. Vérifiez le backend.');
      }

      print('✅ [AUTH_REPO] UserId final: $userId');
      print('✅ [AUTH_REPO] User role: ${userData['role']}');
      print('✅ [AUTH_REPO] User nom: ${userData['nom']}');

      // Sauvegarder le token dans DioClient
      await DioClient.instance.saveToken(accessToken);

      // 🔥 CRITIQUE: Sauvegarder dans SharedPreferences AVANT de créer le UserModel
      await _saveAuthData(
        accessToken: accessToken,
        refreshToken: refreshToken,
        userId: userId,
        userData: userData,
      );

      // Vérifier immédiatement après sauvegarde
      await _verifyStoredData();

      print('========================================');

      // Créer et retourner le UserModel
      final userModel = UserModel(
        id: userId,
        nom: userData['nom'] ?? '',
        email: userData['email'] ?? '',
        role: userData['role'] ?? 'user',
        poste: userData['poste'],
        departement: userData['departement'],
      );

      print('✅ [AUTH_REPO] UserModel créé: ${userModel.toString()}');
      return userModel;

    } on DioException catch (e) {
      print('❌ [AUTH_REPO] Login error: ${e.message}');
      throw _handleError(e);
    } catch (e) {
      print('❌ [AUTH_REPO] Unexpected error: $e');
      rethrow;
    }
  }

  /// Extraire l'userId depuis le JWT
  String? _extractUserIdFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        print('⚠️ [AUTH_REPO] Token JWT invalide (pas 3 parties)');
        return null;
      }

      final payload = parts[1];
      final normalizedPayload = base64Url.normalize(payload);
      final payloadString = utf8.decode(base64Url.decode(normalizedPayload));
      final payloadMap = jsonDecode(payloadString);

      print('🔍 [AUTH_REPO] JWT payload: $payloadMap');

      // Le JWT peut contenir 'userId', 'sub', ou 'id'
      final userId = payloadMap['userId'] ?? payloadMap['sub'] ?? payloadMap['id'];

      print('🔍 [AUTH_REPO] userId trouvé dans JWT: $userId');
      return userId?.toString();
    } catch (e) {
      print('❌ [AUTH_REPO] Erreur extraction userId du JWT: $e');
      return null;
    }
  }

  /// 🔥 CRITIQUE: Sauvegarder les données d'authentification
  Future<void> _saveAuthData({
    required String accessToken,
    String? refreshToken,
    required String userId,
    required Map<String, dynamic> userData,
  }) async {
    try {
      print('========================================');
      print('📤 [AUTH_REPO] SAUVEGARDE DES DONNÉES...');

      final prefs = await SharedPreferences.getInstance();

      // 🔥 CRITIQUE: Vider d'abord toutes les anciennes données
      await prefs.clear();
      print('🗑️ [AUTH_REPO] Anciennes données supprimées');

      // Sauvegarder les tokens
      final tokenSaved = await prefs.setString(StorageKeys.accessToken, accessToken);
      print('📝 [AUTH_REPO] access_token sauvegardé: $tokenSaved');

      if (refreshToken != null) {
        final refreshSaved = await prefs.setString(StorageKeys.refreshToken, refreshToken);
        print('📝 [AUTH_REPO] refresh_token sauvegardé: $refreshSaved');
      }

      // 🔥 CRITIQUE: Sauvegarder l'userId
      final userIdSaved = await prefs.setString(StorageKeys.userId, userId);
      print('📝 [AUTH_REPO] user_id sauvegardé: $userIdSaved (valeur: $userId)');

      // Sauvegarder les autres infos
      final nomSaved = await prefs.setString(StorageKeys.userName, userData['nom'] ?? '');
      print('📝 [AUTH_REPO] user_name sauvegardé: $nomSaved (valeur: ${userData['nom']})');

      final emailSaved = await prefs.setString(StorageKeys.userEmail, userData['email'] ?? '');
      print('📝 [AUTH_REPO] user_email sauvegardé: $emailSaved (valeur: ${userData['email']})');

      final roleSaved = await prefs.setString(StorageKeys.userRole, userData['role'] ?? '');
      print('📝 [AUTH_REPO] user_role sauvegardé: $roleSaved (valeur: ${userData['role']})');

      if (userData['poste'] != null) {
        await prefs.setString('user_poste', userData['poste']);
        print('📝 [AUTH_REPO] user_poste sauvegardé: ${userData['poste']}');
      }

      if (userData['departement'] != null) {
        await prefs.setString('user_departement', userData['departement']);
        print('📝 [AUTH_REPO] user_departement sauvegardé: ${userData['departement']}');
      }

      final loggedInSaved = await prefs.setBool(StorageKeys.isLoggedIn, true);
      print('📝 [AUTH_REPO] is_logged_in sauvegardé: $loggedInSaved (valeur: true)');

      print('========================================');
    } catch (e) {
      print('❌ [AUTH_REPO] Error saving auth data: $e');
      rethrow;
    }
  }

  /// 🔍 VÉRIFICATION: Lire immédiatement après sauvegarde
  Future<void> _verifyStoredData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      print('========================================');
      print('🔍 [AUTH_REPO] VÉRIFICATION DONNÉES SAUVEGARDÉES:');
      print('   - Toutes les clés: ${prefs.getKeys()}');
      print('   - access_token présent: ${prefs.getString(StorageKeys.accessToken) != null}');
      print('   - user_id: ${prefs.getString(StorageKeys.userId)}');
      print('   - user_name: ${prefs.getString(StorageKeys.userName)}');
      print('   - user_email: ${prefs.getString(StorageKeys.userEmail)}');
      print('   - user_role: ${prefs.getString(StorageKeys.userRole)}');
      print('   - is_logged_in: ${prefs.getBool(StorageKeys.isLoggedIn)}');
      print('========================================');
    } catch (e) {
      print('❌ [AUTH_REPO] Error verifying data: $e');
    }
  }

  /// Récupérer les infos utilisateur stockées
  Future<Map<String, dynamic>?> getUserInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      print('========================================');
      print('🔍 [AUTH_REPO] RÉCUPÉRATION getUserInfo...');
      print('   - Toutes les clés disponibles: ${prefs.getKeys()}');

      final userId = prefs.getString(StorageKeys.userId);
      final userName = prefs.getString(StorageKeys.userName);
      final userEmail = prefs.getString(StorageKeys.userEmail);
      final userRole = prefs.getString(StorageKeys.userRole);

      print('   - user_id récupéré: $userId');
      print('   - user_name récupéré: $userName');
      print('   - user_email récupéré: $userEmail');
      print('   - user_role récupéré: $userRole');
      print('========================================');

      if (userId == null || userId.isEmpty) {
        print('⚠️ [AUTH_REPO] getUserInfo: userId est null ou vide!');
        return null;
      }

      return {
        'id': userId,
        'nom': userName,
        'email': userEmail,
        'role': userRole,
        'poste': prefs.getString('user_poste'),
        'departement': prefs.getString('user_departement'),
      };
    } catch (e) {
      print('❌ [AUTH_REPO] Error getting user info: $e');
      return null;
    }
  }

  /// Vérifier si l'utilisateur est connecté
  Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool(StorageKeys.isLoggedIn) ?? false;
      final userId = prefs.getString(StorageKeys.userId);

      print('🔍 [AUTH_REPO] isLoggedIn: $isLoggedIn, userId: $userId');

      return isLoggedIn && userId != null && userId.isNotEmpty;
    } catch (e) {
      print('❌ [AUTH_REPO] Error checking login status: $e');
      return false;
    }
  }

  /// Déconnexion
  Future<void> logout() async {
    try {
      print('📤 [AUTH_REPO] Déconnexion en cours...');
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      await DioClient.instance.clearToken();
      print('✅ [AUTH_REPO] Logout successful');
    } catch (e) {
      print('❌ [AUTH_REPO] Error during logout: $e');
    }
  }

  /// Signup
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

      await DioClient.instance.saveToken(newAccessToken);
      await prefs.setString(StorageKeys.accessToken, newAccessToken);

      return newAccessToken;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Gestion des erreurs
  Exception _handleError(DioException e) {
    if (e.response != null) {
      final message = e.response?.data['message'] ?? 'Erreur inconnue';
      print('========================================');
      print('❌ [AUTH_REPO] API Error:');
      print('   Status: ${e.response?.statusCode}');
      print('   Message: $message');
      print('   Data: ${e.response?.data}');
      print('========================================');
      return Exception(message);
    }

    print('❌ [AUTH_REPO] Network Error: ${e.message}');
    return Exception('Erreur réseau : ${e.message}');
  }
}