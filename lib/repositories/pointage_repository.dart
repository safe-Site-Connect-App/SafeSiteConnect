import 'dart:convert';
import 'package:dio/dio.dart';
import '../services/pointage_service.dart';
import '../utils/constants.dart';
import '../models/pointage_model.dart';
import '../utils/storage_helper.dart';

class PointageRepository {
  final PointageService _service = PointageService();

  /// Créer un nouveau pointage
  Future<void> createPointage({
    required String type,
    required String date,
    required String heure,
  }) async {
    try {
      print('========================================');
      print('📤 [REPO] Création pointage');
      print('📤 Type: $type');
      print('📤 Date brute: $date');
      print('📤 Heure: $heure');

      DateTime dateTime;
      try {
        if (date.contains('-') && date.split('-').length == 3) {
          dateTime = DateTime.parse(date);
        } else if (date.contains('/') && date.split('/').length == 3) {
          final parts = date.split('/');
          final day = parts[0].padLeft(2, '0');
          final month = parts[1].padLeft(2, '0');
          final year = parts[2];
          dateTime = DateTime.parse('$year-$month-$day');
        } else {
          dateTime = DateTime.parse(date);
        }
      } catch (e) {
        print('❌ [REPO] Erreur parsing date: $e');
        throw Exception('Format de date invalide. Utilisez YYYY-MM-DD ou DD/MM/YYYY');
      }

      print('📤 Date formatée: ${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}');
      print('========================================');

      final dto = CreatePointageDto(
        date: dateTime,
        heure: heure,
        type: PointageType.fromString(type),
      );

      final pointage = await _service.createPointage(dto);

      print('========================================');
      print('✅ [REPO] Pointage créé: ${pointage.id}');
      print('========================================');
    } on DioException catch (e) {
      print('========================================');
      print('❌ [REPO] Erreur DioException');
      print('❌ Status: ${e.response?.statusCode}');
      print('❌ Data: ${e.response?.data}');
      print('❌ Message: ${e.message}');
      print('========================================');

      if (e.response?.statusCode == 400) {
        final errorData = e.response?.data;
        if (errorData != null && errorData['message'] != null) {
          if (errorData['message'] is List) {
            throw Exception((errorData['message'] as List).join(', '));
          } else {
            throw Exception(errorData['message']);
          }
        }
        throw Exception('Données invalides');
      } else if (e.response?.statusCode == 401) {
        throw Exception(ApiConstants.unauthorizedError);
      } else if (e.response?.statusCode == 500) {
        throw Exception(ApiConstants.serverError);
      } else {
        throw Exception(
            e.response?.data['message'] ??
                'Erreur lors de la création du pointage');
      }
    } catch (e) {
      print('❌ [REPO] Erreur inattendue: $e');
      throw Exception('Erreur inattendue: $e');
    }
  }

  /// Récupérer le pointage du jour
  Future<Map<String, dynamic>> getTodayPointage() async {
    try {
      print('📥 [REPO] Récupération pointage du jour...');

      final response = await _service.getTodayPointage();

      print('✅ [REPO] Pointage reçu: ${response.hasEntree}, ${response.hasSortie}');

      return {
        'hasEntree': response.hasEntree,
        'hasSortie': response.hasSortie,
        'entree': response.entree?.toJson(),
        'sortie': response.sortie?.toJson(),
      };
    } on DioException catch (e) {
      print('❌ [REPO] Erreur récupération: ${e.response?.statusCode}');
      throw Exception(
          e.response?.data['message'] ??
              'Erreur lors de la récupération du pointage');
    } catch (e) {
      print('❌ [REPO] Erreur: $e');
      throw Exception('Erreur: $e');
    }
  }

  /// Récupérer l'historique des pointages
  Future<List<Map<String, dynamic>>> getPointageHistory({
    required String startDate,
    required String endDate,
    String? userId,
  }) async {
    try {
      print('📥 [REPO] Récupération historique: $startDate à $endDate');

      // Utiliser l'userId fourni, sinon récupérer depuis StorageHelper
      final effectiveUserId = userId ?? await _getUserIdFromAuth();
      print('📥 [REPO] User ID: $effectiveUserId');

      final pointages = await _service.getPointagesByPeriod(
        userId: effectiveUserId,
        start: DateTime.parse(startDate),
        end: DateTime.parse(endDate),
      );

      print('✅ [REPO] Historique reçu: ${pointages.length} pointages');
      return pointages.map((p) => p.toJson()).toList();
    } on DioException catch (e) {
      print('❌ [REPO] Erreur historique: ${e.response?.statusCode}');
      throw Exception(
          e.response?.data['message'] ??
              'Erreur lors de la récupération de l\'historique');
    } catch (e) {
      print('❌ [REPO] Erreur: $e');
      throw Exception('Erreur: $e');
    }
  }

  /// Récupérer l'ID utilisateur depuis StorageHelper
  Future<String> _getUserIdFromAuth() async {
    try {
      final userId = await StorageHelper.getUserId();
      if (userId == null) {
        throw Exception('userId non trouvé dans SharedPreferences');
      }
      print('✅ [REPO] User ID extrait via StorageHelper: $userId');
      return userId;
    } catch (e) {
      print('❌ [REPO] Erreur extraction userId: $e');
      throw Exception('Impossible de récupérer l\'ID utilisateur: $e');
    }
  }

  /// Récupérer tous les pointages pour une période (admin)
  Future<List<PointageModel>> getAllPointagesByWeek({
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      print('📥 [REPO] Récupération tous les pointages: ${start.toIso8601String()} à ${end.toIso8601String()}');

      final pointages = await _service.getAllPointagesByWeek(
        start: start,
        end: end,
      );

      print('✅ [REPO] ${pointages.length} pointages reçus');
      return pointages;
    } on DioException catch (e) {
      print('❌ [REPO] Erreur historique: ${e.response?.statusCode}');
      throw Exception(
          e.response?.data['message'] ??
              'Erreur lors de la récupération des pointages');
    } catch (e) {
      print('❌ [REPO] Erreur: $e');
      throw Exception('Erreur: $e');
    }
  }
}