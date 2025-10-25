import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/pointage_service.dart';
import '../utils/constants.dart';
import '../models/pointage_model.dart';

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
      print('========================================');
      print('📥 [REPO] Récupération historique: $startDate à $endDate');

      // Utiliser l'userId fourni, sinon récupérer depuis SharedPreferences
      final effectiveUserId = userId ?? await _getUserIdFromAuth();
      print('📥 [REPO] User ID: $effectiveUserId');

      final pointages = await _service.getPointagesByPeriod(
        userId: effectiveUserId,
        start: DateTime.parse(startDate),
        end: DateTime.parse(endDate),
      );

      print('✅ [REPO] Historique reçu: ${pointages.length} pointages');
      print('========================================');

      return pointages.map((p) => p.toJson()).toList();
    } on DioException catch (e) {
      print('========================================');
      print('❌ [REPO] Erreur historique: ${e.response?.statusCode}');
      print('❌ Message: ${e.response?.data}');
      print('========================================');

      throw Exception(
          e.response?.data['message'] ??
              'Erreur lors de la récupération de l\'historique');
    } catch (e) {
      print('========================================');
      print('❌ [REPO] Erreur: $e');
      print('========================================');

      throw Exception('Erreur: $e');
    }
  }

  /// Récupérer l'ID utilisateur depuis SharedPreferences
  Future<String> _getUserIdFromAuth() async {
    try {
      print('🔍 [REPO] Récupération de l\'userId...');

      final prefs = await SharedPreferences.getInstance();

      // Essayer avec la clé correcte
      String? userId = prefs.getString(StorageKeys.userId);
      print('🔍 [REPO] userId depuis "${StorageKeys.userId}": $userId');

      // Si non trouvé, essayer de décoder le JWT
      if (userId == null || userId.isEmpty) {
        print('⚠️ [REPO] userId non trouvé dans SharedPreferences');
        print('🔍 [REPO] Tentative d\'extraction depuis le JWT...');

        final token = prefs.getString(StorageKeys.accessToken);
        if (token != null) {
          userId = _extractUserIdFromToken(token);

          if (userId != null && userId.isNotEmpty) {
            // Sauvegarder pour la prochaine fois
            await prefs.setString(StorageKeys.userId, userId);
            print('✅ [REPO] userId extrait du JWT et sauvegardé: $userId');
          }
        }
      }

      if (userId == null || userId.isEmpty) {
        print('========================================');
        print('❌ [REPO] DIAGNOSTIC:');
        print('❌ Toutes les clés dans SharedPreferences:');
        final allKeys = prefs.getKeys();
        for (final key in allKeys) {
          print('   - $key: ${prefs.get(key)}');
        }
        print('========================================');

        throw Exception('userId non trouvé. Veuillez vous reconnecter.');
      }

      print('✅ [REPO] User ID extrait: $userId');
      return userId;
    } catch (e) {
      print('========================================');
      print('❌ [REPO] Erreur extraction userId: $e');
      print('========================================');

      throw Exception('Impossible de récupérer l\'ID utilisateur: $e');
    }
  }

  /// Extraire l'userId depuis le JWT
  String? _extractUserIdFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        print('⚠️ [REPO] Token invalide (pas 3 parties)');
        return null;
      }

      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final Map<String, dynamic> json = jsonDecode(decoded);

      print('🔍 [REPO] Payload JWT: $json');

      // Le JWT peut contenir 'userId', 'sub', ou 'id'
      final userId = json['userId'] ?? json['sub'] ?? json['id'];

      if (userId != null) {
        print('✅ [REPO] userId trouvé dans le JWT: $userId');
      } else {
        print('⚠️ [REPO] Aucun userId trouvé dans le JWT');
      }

      return userId as String?;
    } catch (e) {
      print('❌ [REPO] Erreur décodage JWT: $e');
      return null;
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