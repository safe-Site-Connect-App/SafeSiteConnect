import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/alerte_model.dart';
import '../utils/constants.dart';
import '../utils/storage_helper.dart';

class AlerteRepository {
  final http.Client _client;

  AlerteRepository({http.Client? client}) : _client = client ?? http.Client();

  // Get authorization headers
  Future<Map<String, String>> _getHeaders() async {
    final token = await StorageHelper.getAccessToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Create new alerte
  Future<AlerteModel> createAlerte(AlerteModel alerte) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse(ApiConstants.alertesCreateUrl);

      final response = await _client.post(
        url,
        headers: headers,
        body: jsonEncode(alerte.toCreateDto()),
      ).timeout(ApiConstants.connectTimeout);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return AlerteModel.fromJson(data);
      } else if (response.statusCode == 401) {
        throw Exception(ApiConstants.unauthorizedError);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? ApiConstants.serverError);
      }
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception(ApiConstants.timeoutError);
      }
      throw Exception('Erreur lors de la création de l\'alerte: ${e.toString()}');
    }
  }

  // Get all alertes
  Future<List<AlerteModel>> getAllAlertes() async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse(ApiConstants.alertesUrl);

      final response = await _client.get(
        url,
        headers: headers,
      ).timeout(ApiConstants.receiveTimeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => AlerteModel.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        throw Exception(ApiConstants.unauthorizedError);
      } else {
        throw Exception(ApiConstants.serverError);
      }
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception(ApiConstants.timeoutError);
      }
      throw Exception('Erreur lors de la récupération des alertes: ${e.toString()}');
    }
  }

  // Get single alerte by ID
  Future<AlerteModel> getAlerteById(String id) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse('${ApiConstants.alertesUrl}/$id');

      final response = await _client.get(
        url,
        headers: headers,
      ).timeout(ApiConstants.receiveTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return AlerteModel.fromJson(data);
      } else if (response.statusCode == 404) {
        throw Exception('Alerte non trouvée');
      } else if (response.statusCode == 401) {
        throw Exception(ApiConstants.unauthorizedError);
      } else {
        throw Exception(ApiConstants.serverError);
      }
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception(ApiConstants.timeoutError);
      }
      throw Exception('Erreur lors de la récupération de l\'alerte: ${e.toString()}');
    }
  }

  // Update alerte
  Future<AlerteModel> updateAlerte(String id, AlerteModel alerte) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse('${ApiConstants.alertesUrl}/$id');

      final response = await _client.patch(
        url,
        headers: headers,
        body: jsonEncode(alerte.toUpdateDto()),
      ).timeout(ApiConstants.connectTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return AlerteModel.fromJson(data);
      } else if (response.statusCode == 404) {
        throw Exception('Alerte non trouvée');
      } else if (response.statusCode == 401) {
        throw Exception(ApiConstants.unauthorizedError);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? ApiConstants.serverError);
      }
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception(ApiConstants.timeoutError);
      }
      throw Exception('Erreur lors de la mise à jour de l\'alerte: ${e.toString()}');
    }
  }

  // Mark alerte as resolved
  Future<AlerteModel> markAsResolved(String id) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse('${ApiConstants.alertesUrl}/$id');

      final response = await _client.patch(
        url,
        headers: headers,
        body: jsonEncode({'statut': 'Resolved'}),
      ).timeout(ApiConstants.connectTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return AlerteModel.fromJson(data);
      } else if (response.statusCode == 404) {
        throw Exception('Alerte non trouvée');
      } else if (response.statusCode == 401) {
        throw Exception(ApiConstants.unauthorizedError);
      } else {
        throw Exception(ApiConstants.serverError);
      }
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception(ApiConstants.timeoutError);
      }
      throw Exception('Erreur lors de la résolution de l\'alerte: ${e.toString()}');
    }
  }

  // Delete alerte
  Future<void> deleteAlerte(String id) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse('${ApiConstants.alertesUrl}/$id');

      final response = await _client.delete(
        url,
        headers: headers,
      ).timeout(ApiConstants.connectTimeout);

      if (response.statusCode == 200 || response.statusCode == 204) {
        return;
      } else if (response.statusCode == 404) {
        throw Exception('Alerte non trouvée');
      } else if (response.statusCode == 401) {
        throw Exception(ApiConstants.unauthorizedError);
      } else {
        throw Exception(ApiConstants.serverError);
      }
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception(ApiConstants.timeoutError);
      }
      throw Exception('Erreur lors de la suppression de l\'alerte: ${e.toString()}');
    }
  }

  // Get alertes by priority
  Future<List<AlerteModel>> getAlertesByPriority(String priorite) async {
    final alertes = await getAllAlertes();
    return alertes.where((alerte) => alerte.priorite == priorite).toList();
  }

  // Get alertes by status
  Future<List<AlerteModel>> getAlertesByStatus(String statut) async {
    final alertes = await getAllAlertes();
    return alertes.where((alerte) => alerte.statut == statut).toList();
  }

  // Get unresolved alertes
  Future<List<AlerteModel>> getUnresolvedAlertes() async {
    final alertes = await getAllAlertes();
    return alertes.where((alerte) => alerte.statut != 'Resolved').toList();
  }

  // Get critical alertes
  Future<List<AlerteModel>> getCriticalAlertes() async {
    final alertes = await getAllAlertes();
    return alertes.where((alerte) => alerte.priorite == 'Critique').toList();
  }

  // Dispose
  void dispose() {
    _client.close();
  }
}