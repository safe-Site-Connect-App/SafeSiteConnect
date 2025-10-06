import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/tache_model.dart';
import '../utils/constants.dart';
import '../utils/storage_helper.dart';

class TacheRepository {
  final http.Client _client;

  TacheRepository({http.Client? client}) : _client = client ?? http.Client();

  // Récupérer le token d'authentification
  Future<String?> _getAuthToken() async {
    return await StorageHelper.getAccessToken();
  }

  // Headers avec authentification
  Future<Map<String, String>> _getHeaders() async {
    final token = await _getAuthToken();
    return {
      ...ApiConstants.headers,
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Helper pour extraire les données de la réponse
  dynamic _extractData(dynamic responseData) {
    if (responseData is Map && responseData.containsKey('data')) {
      return responseData['data'];
    }
    return responseData;
  }

  // Créer une nouvelle tâche
  Future<TacheModel> createTache(CreateTacheDto createDto) async {
    try {
      final headers = await _getHeaders();
      print('🔧 [REPO] Création tâche pour: ${createDto.assigneA}');

      final response = await _client
          .post(
        Uri.parse(ApiConstants.tachesUrl),
        headers: headers,
        body: jsonEncode(createDto.toJson()),
      )
          .timeout(ApiConstants.connectTimeout);

      print('📡 [REPO] Réponse création: ${response.statusCode}');

      if (response.statusCode == ApiStatus.created || response.statusCode == ApiStatus.success) {
        final responseData = jsonDecode(response.body);
        final data = _extractData(responseData);
        return TacheModel.fromJson(data);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Erreur lors de la création de la tâche');
      }
    } catch (e) {
      print('❌ [REPO] Erreur création tâche: $e');
      throw Exception('Erreur réseau: ${e.toString()}');
    }
  }

  // Récupérer toutes les tâches
  Future<List<TacheModel>> getAllTaches() async {
    try {
      final headers = await _getHeaders();
      print('🔧 [REPO] Récupération de toutes les tâches');

      final response = await _client
          .get(
        Uri.parse(ApiConstants.tachesUrl),
        headers: headers,
      )
          .timeout(ApiConstants.connectTimeout);

      print('📡 [REPO] Réponse getAllTaches: ${response.statusCode}');

      if (response.statusCode == ApiStatus.success) {
        final responseData = jsonDecode(response.body);
        print('📦 [REPO] Type de données: ${responseData.runtimeType}');

        final data = _extractData(responseData);

        if (data is! List) {
          print('⚠️ [REPO] Format inattendu: $data');
          throw Exception('Format de données incorrect');
        }

        print('✅ [REPO] ${data.length} tâches récupérées');
        return data.map<TacheModel>((json) => TacheModel.fromJson(json)).toList();
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Erreur lors de la récupération des tâches');
      }
    } catch (e) {
      print('❌ [REPO] Erreur getAllTaches: $e');
      throw Exception('Erreur réseau: ${e.toString()}');
    }
  }

  // Récupérer les tâches de l'utilisateur connecté
  Future<List<TacheModel>> getTachesByUser() async {
    try {
      final headers = await _getHeaders();
      print('🔧 [REPO] Récupération tâches pour l\'utilisateur connecté');
      print('🔧 [REPO] URL: ${ApiConstants.myTasksUrl}');

      final response = await _client
          .get(
        Uri.parse(ApiConstants.myTasksUrl),
        headers: headers,
      )
          .timeout(ApiConstants.connectTimeout);

      print('📡 [REPO] Réponse getTachesByUser: ${response.statusCode}');
      print('📦 [REPO] Body: ${response.body}');

      if (response.statusCode == ApiStatus.success) {
        final responseData = jsonDecode(response.body);
        print('📦 [REPO] Type de données: ${responseData.runtimeType}');

        final data = _extractData(responseData);

        if (data is! List) {
          print('⚠️ [REPO] Format inattendu: $data');
          throw Exception('Format de données incorrect');
        }

        print('✅ [REPO] ${data.length} tâches utilisateur récupérées');
        return data.map<TacheModel>((json) => TacheModel.fromJson(json)).toList();
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Erreur lors de la récupération des tâches de l\'utilisateur');
      }
    } catch (e) {
      print('❌ [REPO] Erreur getTachesByUser: $e');
      throw Exception('Erreur réseau: ${e.toString()}');
    }
  }

  // Récupérer une tâche par ID
  Future<TacheModel> getTacheById(String tacheId) async {
    try {
      final headers = await _getHeaders();
      print('🔧 [REPO] Récupération tâche ID: $tacheId');

      final response = await _client
          .get(
        Uri.parse(ApiConstants.tacheByIdUrl(tacheId)),
        headers: headers,
      )
          .timeout(ApiConstants.connectTimeout);

      print('📡 [REPO] Réponse getTacheById: ${response.statusCode}');

      if (response.statusCode == ApiStatus.success) {
        final responseData = jsonDecode(response.body);
        final data = _extractData(responseData);
        return TacheModel.fromJson(data);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Tâche non trouvée');
      }
    } catch (e) {
      print('❌ [REPO] Erreur getTacheById: $e');
      throw Exception('Erreur réseau: ${e.toString()}');
    }
  }

  // Mettre à jour une tâche
  Future<TacheModel> updateTache(String tacheId, UpdateTacheDto updateDto) async {
    try {
      final headers = await _getHeaders();
      print('🔧 [REPO] Mise à jour tâche: $tacheId');

      final response = await _client
          .patch(
        Uri.parse(ApiConstants.tacheByIdUrl(tacheId)),
        headers: headers,
        body: jsonEncode(updateDto.toJson()),
      )
          .timeout(ApiConstants.connectTimeout);

      print('📡 [REPO] Réponse updateTache: ${response.statusCode}');

      if (response.statusCode == ApiStatus.success) {
        final responseData = jsonDecode(response.body);
        final data = _extractData(responseData);
        return TacheModel.fromJson(data);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Erreur lors de la mise à jour');
      }
    } catch (e) {
      print('❌ [REPO] Erreur updateTache: $e');
      throw Exception('Erreur réseau: ${e.toString()}');
    }
  }

  // Supprimer une tâche
  Future<void> deleteTache(String tacheId) async {
    try {
      final headers = await _getHeaders();
      print('🔧 [REPO] Suppression tâche: $tacheId');

      final response = await _client
          .delete(
        Uri.parse(ApiConstants.tacheByIdUrl(tacheId)),
        headers: headers,
      )
          .timeout(ApiConstants.connectTimeout);

      print('📡 [REPO] Réponse deleteTache: ${response.statusCode}');

      if (response.statusCode != ApiStatus.success && response.statusCode != 204) {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Erreur lors de la suppression');
      }

      print('✅ [REPO] Tâche supprimée avec succès');
    } catch (e) {
      print('❌ [REPO] Erreur deleteTache: $e');
      throw Exception('Erreur réseau: ${e.toString()}');
    }
  }

  // Récupérer tous les utilisateurs (pour l'assignation)
  Future<List<UserAssignee>> getAllUsers() async {
    try {
      final headers = await _getHeaders();
      print('🔧 [REPO] Récupération de tous les utilisateurs');

      final response = await _client
          .get(
        Uri.parse(ApiConstants.adminUsersUrl),
        headers: headers,
      )
          .timeout(ApiConstants.connectTimeout);

      print('📡 [REPO] Réponse getAllUsers: ${response.statusCode}');

      if (response.statusCode == ApiStatus.success) {
        final responseData = jsonDecode(response.body);
        final data = _extractData(responseData);

        if (data is! List) {
          throw Exception('Format de données incorrect');
        }

        print('✅ [REPO] ${data.length} utilisateurs récupérés');
        return data.map<UserAssignee>((json) => UserAssignee.fromJson(json)).toList();
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Erreur lors de la récupération des utilisateurs');
      }
    } catch (e) {
      print('❌ [REPO] Erreur getAllUsers: $e');
      throw Exception('Erreur réseau: ${e.toString()}');
    }
  }

  void dispose() {
    _client.close();
  }
}