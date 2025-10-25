import 'package:dio/dio.dart';
import '../utils/dio_client.dart';
import '../utils/storage_helper.dart';
import '../utils/constants.dart';

class AuthService {
  final Dio _dio = DioClient.instance.dio;

  Future<void> login(String email, String password) async {
    try {
      print('📤 [AUTH] Tentative de connexion: $email');
      final response = await _dio.post(
        ApiConstants.loginUrl,
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final token = response.data['token'] as String;
        final refreshToken = response.data['refreshToken'] as String?;
        final userData = response.data['user'] as Map<String, dynamic>;

        // Sauvegarder dans SharedPreferences
        print('📤 [AUTH] Sauvegarde des données dans SharedPreferences...');
        await StorageHelper.saveAccessToken(token);
        print('✅ [AUTH] access_token sauvegardé');
        if (refreshToken != null) {
          await StorageHelper.saveRefreshToken(refreshToken);
          print('✅ [AUTH] refresh_token sauvegardé');
        }
        await StorageHelper.saveUserId(userData['userId'] ?? userData['_id'] ?? userData['sub']);
        print('✅ [AUTH] userId sauvegardé: ${userData['userId'] ?? userData['_id'] ?? userData['sub']}');
        await StorageHelper.saveUserName(userData['nom'] ?? '');
        print('✅ [AUTH] nom sauvegardé: ${userData['nom'] ?? ''}');
        await StorageHelper.saveUserEmail(userData['email'] ?? '');
        print('✅ [AUTH] email sauvegardé: ${userData['email'] ?? ''}');
        await StorageHelper.saveUserRole(userData['role'] ?? '');
        print('✅ [AUTH] role sauvegardé: ${userData['role'] ?? ''}');
        await StorageHelper.setLoggedIn(true);
        print('✅ [AUTH] is_logged_in défini à true');

        // Sauvegarder dans FlutterSecureStorage
        print('📤 [AUTH] Sauvegarde des tokens dans FlutterSecureStorage...');
        await DioClient.instance.saveToken(token);
        print('✅ [AUTH] access_token sauvegardé dans FlutterSecureStorage');
        if (refreshToken != null) {
          await DioClient.instance.saveRefreshToken(refreshToken);
          print('✅ [AUTH] refresh_token sauvegardé dans FlutterSecureStorage');
        }

        // Vérifier les données sauvegardées
        final isLoggedIn = await StorageHelper.isLoggedIn();
        final savedUserId = await StorageHelper.getUserId();
        final savedToken = await StorageHelper.getAccessToken();
        print('🔍 [AUTH] Vérification: isLoggedIn=$isLoggedIn, userId=$savedUserId, access_token=$savedToken');

        print('✅ [AUTH] Connexion réussie');
      } else {
        throw Exception('Échec de la connexion: ${response.data['message'] ?? 'Réponse inattendue'}');
      }
    } catch (e) {
      print('❌ [AUTH] Erreur connexion: $e');
      throw Exception('Erreur lors de la connexion: $e');
    }
  }

  Future<void> logout() async {
    try {
      print('📤 [AUTH] Déconnexion en cours...');
      await StorageHelper.clearAll();
      print('✅ [AUTH] SharedPreferences vidé');
      await DioClient.instance.logout();
      print('✅ [AUTH] FlutterSecureStorage vidé');
      print('✅ [AUTH] Déconnexion réussie');
    } catch (e) {
      print('❌ [AUTH] Erreur déconnexion: $e');
      throw Exception('Erreur lors de la déconnexion: $e');
    }
  }
}