import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import '../utils/dio_client.dart';
import '../models/pointage_model.dart';
import '../utils/constants.dart';

class PointageService {
  final Dio _dio = DioClient.instance.dio;

  // Créer un pointage (ENTREE ou SORTIE)
  Future<PointageModel> createPointage(CreatePointageDto dto) async {
    try {
      print('📤 [SERVICE] Création pointage: ${dto.toJson()}');
      final response = await _dio.post(
        ApiConstants.pointagesCreateUrl,
        data: dto.toJson(),
      );

      print('✅ [SERVICE] Réponse: ${response.statusCode}, Data: ${response.data}');

      if (response.statusCode == 201 && response.data['success'] == true) {
        return PointageModel.fromJson(response.data['data'] as Map<String, dynamic>);
      } else {
        throw Exception(response.data['message'] ?? 'Erreur lors de la création du pointage');
      }
    } on DioException catch (e) {
      print('❌ [SERVICE] Erreur Dio: ${e.response?.statusCode}, ${e.response?.data}');
      if (e.response?.statusCode == 400) {
        throw Exception(e.response?.data['message'] ?? 'Vous avez déjà enregistré ce type de pointage aujourd\'hui');
      } else if (e.response?.statusCode == 404) {
        throw Exception('Utilisateur non trouvé');
      } else if (e.response?.statusCode == 401) {
        throw Exception(ApiConstants.unauthorizedError);
      } else if (e.response?.statusCode == 500) {
        throw Exception(ApiConstants.serverError);
      }
      throw Exception('${ApiConstants.networkError}: ${e.message}');
    } catch (e) {
      print('❌ [SERVICE] Erreur inattendue: $e');
      throw Exception('Erreur inattendue: $e');
    }
  }

  // Récupérer le pointage du jour
  Future<TodayPointageResponse> getTodayPointage() async {
    try {
      print('📥 [SERVICE] Récupération pointage du jour...');
      final response = await _dio.get(ApiConstants.pointagesTodayUrl);

      print('✅ [SERVICE] Réponse: ${response.statusCode}, Data: ${response.data}');

      if (response.statusCode == 200 && response.data['success'] == true) {
        return TodayPointageResponse.fromJson(response.data['data'] as Map<String, dynamic>);
      } else {
        throw Exception('Erreur lors de la récupération du pointage du jour');
      }
    } on DioException catch (e) {
      print('❌ [SERVICE] Erreur Dio: ${e.response?.statusCode}, ${e.response?.data}');
      if (e.response?.statusCode == 401) {
        throw Exception(ApiConstants.unauthorizedError);
      } else if (e.response?.statusCode == 500) {
        throw Exception(ApiConstants.serverError);
      }
      throw Exception('${ApiConstants.networkError}: ${e.message}');
    } catch (e) {
      print('❌ [SERVICE] Erreur inattendue: $e');
      throw Exception('Erreur inattendue: $e');
    }
  }

  // Récupérer les pointages d'un utilisateur pour une période
  Future<List<PointageModel>> getPointagesByPeriod({
    required String userId,
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      final startStr = DateFormat('yyyy-MM-dd').format(start);
      final endStr = DateFormat('yyyy-MM-dd').format(end);
      print('📥 [SERVICE] Récupération pointages pour user: $userId, période: $startStr à $endStr');
      final response = await _dio.get(
        ApiConstants.pointagesUserUrl(userId),
        queryParameters: {
          'start': startStr,
          'end': endStr,
        },
      );

      print('✅ [SERVICE] Réponse: ${response.statusCode}, Count: ${response.data['count']}');

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] as List<dynamic>;
        return data.map((json) => PointageModel.fromJson(json as Map<String, dynamic>)).toList();
      } else {
        throw Exception('Erreur lors de la récupération des pointages');
      }
    } on DioException catch (e) {
      print('❌ [SERVICE] Erreur Dio: ${e.response?.statusCode}, ${e.response?.data}');
      if (e.response?.statusCode == 401) {
        throw Exception(ApiConstants.unauthorizedError);
      } else if (e.response?.statusCode == 404) {
        throw Exception('Utilisateur non trouvé');
      } else if (e.response?.statusCode == 500) {
        throw Exception(ApiConstants.serverError);
      }
      throw Exception('${ApiConstants.networkError}: ${e.message}');
    } catch (e) {
      print('❌ [SERVICE] Erreur inattendue: $e');
      throw Exception('Erreur inattendue: $e');
    }
  }

  // Récupérer tous les pointages pour une période (admin)
  Future<List<PointageModel>> getAllPointagesByWeek({
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      final startStr = DateFormat('yyyy-MM-dd').format(start);
      final endStr = DateFormat('yyyy-MM-dd').format(end);
      print('📥 [SERVICE] Récupération tous les pointages, période: $startStr à $endStr');
      final response = await _dio.get(
        ApiConstants.pointagesWeekUrl,
        queryParameters: {
          'start': startStr,
          'end': endStr,
        },
      );

      print('✅ [SERVICE] Réponse: ${response.statusCode}, Count: ${response.data['count']}');

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] as List<dynamic>;
        return data.map((json) => PointageModel.fromJson(json as Map<String, dynamic>)).toList();
      } else {
        throw Exception('Erreur lors de la récupération des pointages');
      }
    } on DioException catch (e) {
      print('❌ [SERVICE] Erreur Dio: ${e.response?.statusCode}, ${e.response?.data}');
      if (e.response?.statusCode == 401) {
        throw Exception(ApiConstants.unauthorizedError);
      } else if (e.response?.statusCode == 500) {
        throw Exception(ApiConstants.serverError);
      }
      throw Exception('${ApiConstants.networkError}: ${e.message}');
    } catch (e) {
      print('❌ [SERVICE] Erreur inattendue: $e');
      throw Exception('Erreur inattendue: $e');
    }
  }

  // Récupérer le rapport de présence
  Future<List<Map<String, dynamic>>> getAttendanceReport({
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      final startStr = DateFormat('yyyy-MM-dd').format(start);
      final endStr = DateFormat('yyyy-MM-dd').format(end);
      print('📥 [SERVICE] Récupération rapport de présence, période: $startStr à $endStr');
      final response = await _dio.get(
        ApiConstants.pointagesReportUrl,
        queryParameters: {
          'start': startStr,
          'end': endStr,
        },
      );

      print('✅ [SERVICE] Réponse: ${response.statusCode}, Data: ${response.data}');

      if (response.statusCode == 200 && response.data['success'] == true) {
        return List<Map<String, dynamic>>.from(response.data['data']);
      } else {
        throw Exception('Erreur lors de la récupération du rapport');
      }
    } on DioException catch (e) {
      print('❌ [SERVICE] Erreur Dio: ${e.response?.statusCode}, ${e.response?.data}');
      if (e.response?.statusCode == 401) {
        throw Exception(ApiConstants.unauthorizedError);
      } else if (e.response?.statusCode == 500) {
        throw Exception(ApiConstants.serverError);
      }
      throw Exception('${ApiConstants.networkError}: ${e.message}');
    } catch (e) {
      print('❌ [SERVICE] Erreur inattendue: $e');
      throw Exception('Erreur inattendue: $e');
    }
  }
}