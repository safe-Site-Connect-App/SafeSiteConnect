import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'constants.dart';

class DioClient {
  static final DioClient instance = DioClient._internal();
  late Dio dio;
  final _storage = const FlutterSecureStorage();

  DioClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.fullBaseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        headers: ApiConstants.headers,
      ),
    );

    // Intercepteur pour ajouter le token et logger les requêtes
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: StorageKeys.accessToken);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
            print('[DIO] → ${options.method} ${options.path}');
            print('[DIO] Headers: ${options.headers}');
          } else {
            print('[DIO] ⚠️ Aucun token pour ${options.path}');
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          print('[DIO] ← [${response.statusCode}] ${response.requestOptions.path}');
          print('[DIO] Data: ${response.data}');
          return handler.next(response);
        },
        onError: (error, handler) async {
          print('[DIO] ❌ [${error.response?.statusCode}] ${error.requestOptions.path}');
          print('[DIO] Error: ${error.response?.data}');
          print('[DIO] Message: ${error.message}');

          // Gestion du refresh token pour 401
          if (error.response?.statusCode == 401) {
            final refreshToken = await _storage.read(key: StorageKeys.refreshToken);
            if (refreshToken != null) {
              try {
                // Tenter de rafraîchir le token
                final refreshResponse = await dio.post(
                  ApiConstants.refreshToken,
                  data: {'refreshToken': refreshToken},
                );

                if (refreshResponse.statusCode == 200) {
                  final newAccessToken = refreshResponse.data['accessToken'];
                  await _storage.write(key: StorageKeys.accessToken, value: newAccessToken);

                  // Réessayer la requête originale avec le nouveau token
                  error.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
                  final cloneReq = await dio.request(
                    error.requestOptions.path,
                    options: Options(
                      method: error.requestOptions.method,
                      headers: error.requestOptions.headers,
                    ),
                    data: error.requestOptions.data,
                    queryParameters: error.requestOptions.queryParameters,
                  );
                  return handler.resolve(cloneReq);
                }
              } catch (e) {
                print('[DIO] Échec refresh token: $e');
                // Rediriger vers login si le refresh échoue
                await _storage.deleteAll();
              }
            }
          }

          return handler.next(error);
        },
      ),
    );
  }

  // ✅ Méthode pour sauvegarder le token
  Future<void> saveToken(String token) async {
    await _storage.write(key: StorageKeys.accessToken, value: token);
    print('[DIO] Token sauvegardé');
  }

  // ✅ Méthode pour sauvegarder le refresh token (optionnel)
  Future<void> saveRefreshToken(String refreshToken) async {
    await _storage.write(key: StorageKeys.refreshToken, value: refreshToken);
    print('[DIO] Refresh token sauvegardé');
  }

  // ✅ Méthode pour supprimer les tokens
  Future<void> clearToken() async {
    await _storage.delete(key: StorageKeys.accessToken);
    await _storage.delete(key: StorageKeys.refreshToken);
    print('[DIO] Tokens supprimés');
  }

  // Méthode utilitaire pour vérifier si on est authentifié
  Future<bool> isAuthenticated() async {
    final token = await _storage.read(key: StorageKeys.accessToken);
    return token != null && token.isNotEmpty;
  }

  // Méthode pour se déconnecter
  Future<void> logout() async {
    await _storage.deleteAll();
    print('[DIO] Déconnexion complète');
  }
}