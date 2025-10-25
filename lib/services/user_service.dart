import '../models/user_model.dart';
import '../models/create_user_request.dart';
import '../models/api_response.dart';
import '../utils/constants.dart';
import 'api_service.dart';

class UserService extends ApiService {
  // Créer un utilisateur (signup)
  Future<ApiResponse<UserModel>> createUser(CreateUserRequest request) async {
    return handleApiCall(
      dio.post(ApiConstants.signup, data: request.toJson()),
          (data) => UserModel.fromJson(data),
    );
  }

  // Créer un utilisateur en tant qu'admin
  Future<ApiResponse<UserModel>> createUserAsAdmin(CreateUserRequest request) async {
    return handleApiCall(
      dio.post(ApiConstants.adminUsers, data: request.toJson()),
          (data) => UserModel.fromJson(data),
    );
  }

  // Récupérer tous les utilisateurs
  Future<ApiResponse<List<UserModel>>> getAllUsers({
    int page = 1,
    int limit = 10,
    String? role,
    String? poste,
    bool? isActive,
    String? email,
    String? nom,
    String? departement,
  }) async {
    Map<String, dynamic> queryParams = {
      'page': page,
      'limit': limit,
    };

    if (role != null) queryParams['role'] = role;
    if (poste != null) queryParams['poste'] = poste;
    if (isActive != null) queryParams['isActive'] = isActive;
    if (email != null) queryParams['email'] = email;
    if (nom != null) queryParams['nom'] = nom;
    if (departement != null) queryParams['departement'] = departement;

    return handleApiCallList(
      dio.get(ApiConstants.adminUsers, queryParameters: queryParams),
          (data) => UserModel.fromJson(data),
    );
  }

  // Récupérer un utilisateur spécifique
  Future<ApiResponse<UserModel>> getUserById(String userId) async {
    return handleApiCall(
      dio.get('${ApiConstants.adminUsers}/$userId'),
          (data) => UserModel.fromJson(data),
    );
  }

  // Mettre à jour un utilisateur
  Future<ApiResponse<UserModel>> updateUser(String userId, Map<String, dynamic> data) async {
    return handleApiCall(
      dio.patch('${ApiConstants.adminUsers}/$userId', data: data),
          (data) => UserModel.fromJson(data['user'] ?? data),
    );
  }

  // Mettre à jour le profil de l'utilisateur connecté
  Future<ApiResponse<UserModel>> updateProfile(Map<String, dynamic> data) async {
    return handleApiCall(
      dio.put(ApiConstants.profile, data: data), // Use the new profile endpoint
          (data) => UserModel.fromJson(data['user'] ?? data),
    );
  }

  // Supprimer un utilisateur
  Future<ApiResponse<String>> deleteUser(String userId) async {
    return handleApiCall(
      dio.delete('${ApiConstants.adminUsers}/$userId'),
          (data) => data['message'] ?? 'Utilisateur supprimé avec succès',
    );
  }

  // Basculer le statut d'un utilisateur
  Future<ApiResponse<UserModel>> toggleUserStatus(String userId) async {
    return handleApiCall(
      dio.patch('${ApiConstants.adminUsers}/$userId/toggle-status'),
          (data) => UserModel.fromJson(data['user'] ?? data),
    );
  }

  // Rechercher des utilisateurs
  Future<ApiResponse<List<UserModel>>> searchUsers(String query) async {
    return handleApiCallList(
      dio.get('${ApiConstants.adminUsers}/search', queryParameters: {'q': query}),
          (data) => UserModel.fromJson(data),
    );
  }

  // Récupérer les statistiques des utilisateurs
  Future<ApiResponse<Map<String, dynamic>>> getUserStats() async {
    return handleApiCall(
      dio.get('${ApiConstants.adminUsers}/stats'),
          (data) => data as Map<String, dynamic>,
    );
  }
}