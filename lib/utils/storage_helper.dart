import 'package:shared_preferences/shared_preferences.dart';

class StorageHelper {
  static SharedPreferences? _prefs;

  // Initialiser SharedPreferences
  static Future<void> init() async {
    print('📤 [STORAGE] Initialisation de SharedPreferences...');
    _prefs ??= await SharedPreferences.getInstance();
    print('✅ [STORAGE] SharedPreferences initialisé');
  }

  // Sauvegarder le token d'accès
  static Future<void> saveAccessToken(String token) async {
    await _initPrefs();
    await _prefs!.setString('access_token', token);
    print('✅ [STORAGE] access_token sauvegardé');
  }

  // Récupérer le token d'accès
  static Future<String?> getAccessToken() async {
    await _initPrefs();
    final token = _prefs!.getString('access_token');
    print('🔍 [STORAGE] Récupération access_token: $token');
    return token;
  }

  // Sauvegarder le refresh token
  static Future<void> saveRefreshToken(String refreshToken) async {
    await _initPrefs();
    await _prefs!.setString('refresh_token', refreshToken);
    print('✅ [STORAGE] refresh_token sauvegardé');
  }

  // Récupérer le refresh token
  static Future<String?> getRefreshToken() async {
    await _initPrefs();
    final refreshToken = _prefs!.getString('refresh_token');
    print('🔍 [STORAGE] Récupération refresh_token: $refreshToken');
    return refreshToken;
  }

  // Sauvegarder l'ID utilisateur
  static Future<void> saveUserId(String userId) async {
    await _initPrefs();
    await _prefs!.setString('user_id', userId);
    print('✅ [STORAGE] user_id sauvegardé: $userId');
  }

  // Récupérer l'ID utilisateur
  static Future<String?> getUserId() async {
    await _initPrefs();
    final userId = _prefs!.getString('user_id');
    print('🔍 [STORAGE] Récupération user_id: $userId');
    return userId;
  }

  // Sauvegarder le nom de l'utilisateur
  static Future<void> saveUserName(String name) async {
    await _initPrefs();
    await _prefs!.setString('user_name', name);
    print('✅ [STORAGE] user_name sauvegardé: $name');
  }

  // Récupérer le nom de l'utilisateur
  static Future<String?> getUserName() async {
    await _initPrefs();
    final name = _prefs!.getString('user_name');
    print('🔍 [STORAGE] Récupération user_name: $name');
    return name;
  }

  // Sauvegarder l'email de l'utilisateur
  static Future<void> saveUserEmail(String email) async {
    await _initPrefs();
    await _prefs!.setString('user_email', email);
    print('✅ [STORAGE] user_email sauvegardé: $email');
  }

  // Récupérer l'email de l'utilisateur
  static Future<String?> getUserEmail() async {
    await _initPrefs();
    final email = _prefs!.getString('user_email');
    print('🔍 [STORAGE] Récupération user_email: $email');
    return email;
  }

  // Sauvegarder le rôle de l'utilisateur
  static Future<void> saveUserRole(String role) async {
    await _initPrefs();
    await _prefs!.setString('user_role', role);
    print('✅ [STORAGE] user_role sauvegardé: $role');
  }

  // Récupérer le rôle de l'utilisateur
  static Future<String?> getUserRole() async {
    await _initPrefs();
    final role = _prefs!.getString('user_role');
    print('🔍 [STORAGE] Récupération user_role: $role');
    return role;
  }

  // Définir l'état de connexion
  static Future<void> setLoggedIn(bool isLoggedIn) async {
    await _initPrefs();
    await _prefs!.setBool('is_logged_in', isLoggedIn);
    print('✅ [STORAGE] is_logged_in défini à: $isLoggedIn');
  }

  // Vérifier l'état de connexion
  static Future<bool> isLoggedIn() async {
    await _initPrefs();
    final isLoggedIn = _prefs!.getBool('is_logged_in') ?? false;
    print('🔍 [STORAGE] Vérification is_logged_in: $isLoggedIn');
    return isLoggedIn;
  }

  // Supprimer toutes les données
  static Future<void> clearAll() async {
    await _initPrefs();
    await _prefs!.clear();
    print('✅ [STORAGE] Toutes les données de SharedPreferences supprimées');
  }

  // Initialisation interne de SharedPreferences
  static Future<void> _initPrefs() async {
    if (_prefs == null) {
      print('📤 [STORAGE] Initialisation interne de SharedPreferences...');
      _prefs = await SharedPreferences.getInstance();
      print('✅ [STORAGE] SharedPreferences initialisé (interne)');
    }
  }
}