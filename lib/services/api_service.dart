import 'package:dio/dio.dart';
import '../utils/dio_client.dart';
import '../models/api_response.dart';

class ApiService {
  final Dio dio = DioClient.instance.dio;

  Future<ApiResponse<T>> handleApiCall<T>(
      Future<Response> apiCall,
      T Function(dynamic) fromJson,
      ) async {
    try {
      final response = await apiCall;

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiResponse.success(
          fromJson(response.data),
          response.data['message'] ?? 'Opération réussie',
        );
      } else {
        return ApiResponse.error(
          response.data['message'] ?? 'Une erreur est survenue',
        );
      }
    } on DioException catch (e) {
      String errorMessage = 'Erreur de connexion';

      if (e.response != null) {
        errorMessage = e.response?.data['message'] ??
            e.response?.data['error'] ??
            'Erreur du serveur';
      } else if (e.type == DioExceptionType.connectionTimeout) {
        errorMessage = 'Délai de connexion expiré';
      } else if (e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'Délai de réception expiré';
      }

      return ApiResponse.error(errorMessage);
    } catch (e) {
      return ApiResponse.error('Erreur inattendue: ${e.toString()}');
    }
  }

  Future<ApiResponse<List<T>>> handleApiCallList<T>(
      Future<Response> apiCall,
      T Function(dynamic) fromJson,
      ) async {
    try {
      final response = await apiCall;

      if (response.statusCode == 200) {
        List<dynamic> dataList = response.data['users'] ??
            response.data['data'] ??
            response.data['results'] ??
            [];
        List<T> result = dataList.map((item) => fromJson(item)).toList();

        return ApiResponse.success(
          result,
          response.data['message'] ?? 'Données récupérées avec succès',
        );
      } else {
        return ApiResponse.error(
          response.data['message'] ?? 'Erreur lors de la récupération des données',
        );
      }
    } on DioException catch (e) {
      String errorMessage = 'Erreur de connexion';

      if (e.response != null) {
        errorMessage = e.response?.data['message'] ??
            e.response?.data['error'] ??
            'Erreur du serveur';
      }

      return ApiResponse.error(errorMessage);
    } catch (e) {
      return ApiResponse.error('Erreur inattendue: ${e.toString()}');
    }
  }
}