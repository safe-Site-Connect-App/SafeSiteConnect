import '../models/alerte_model.dart';
import '../repositories/alerte_repository.dart';

class AlerteService {
  final AlerteRepository _repository;

  AlerteService({AlerteRepository? repository})
      : _repository = repository ?? AlerteRepository();

  // Create alerte with validation
  Future<AlerteModel> createAlerte({
    required String titre,
    required String description,
    required String priorite,
    String? lieu,
  }) async {
    // Validation
    if (titre.trim().isEmpty) {
      throw Exception('Le titre ne peut pas être vide');
    }
    if (description.trim().isEmpty) {
      throw Exception('La description ne peut pas être vide');
    }
    if (!['Critique', 'Modérée', 'Mineure'].contains(priorite)) {
      throw Exception('Priorité invalide');
    }

    final alerte = AlerteModel(
      titre: titre.trim(),
      description: description.trim(),
      priorite: priorite,
      lieu: lieu?.trim(),
      statut: 'New',
    );

    return await _repository.createAlerte(alerte);
  }

  // Get all alertes
  Future<List<AlerteModel>> getAllAlertes() async {
    return await _repository.getAllAlertes();
  }

  // Get alerte by ID
  Future<AlerteModel> getAlerteById(String id) async {
    if (id.isEmpty) {
      throw Exception('ID invalide');
    }
    return await _repository.getAlerteById(id);
  }

  // Update alerte
  Future<AlerteModel> updateAlerte({
    required String id,
    required String titre,
    required String description,
    required String priorite,
    String? lieu,
    String? statut,
  }) async {
    // Validation
    if (id.isEmpty) {
      throw Exception('ID invalide');
    }
    if (titre.trim().isEmpty) {
      throw Exception('Le titre ne peut pas être vide');
    }
    if (description.trim().isEmpty) {
      throw Exception('La description ne peut pas être vide');
    }
    if (!['Critique', 'Modérée', 'Mineure'].contains(priorite)) {
      throw Exception('Priorité invalide');
    }
    if (statut != null && !['New', 'In Progress', 'Resolved'].contains(statut)) {
      throw Exception('Statut invalide');
    }

    final alerte = AlerteModel(
      id: id,
      titre: titre.trim(),
      description: description.trim(),
      priorite: priorite,
      lieu: lieu?.trim(),
      statut: statut ?? 'New',
    );

    return await _repository.updateAlerte(id, alerte);
  }

  // Mark as resolved
  Future<AlerteModel> markAsResolved(String id) async {
    if (id.isEmpty) {
      throw Exception('ID invalide');
    }
    return await _repository.markAsResolved(id);
  }

  // Mark as in progress
  Future<AlerteModel> markAsInProgress(String id) async {
    if (id.isEmpty) {
      throw Exception('ID invalide');
    }

    final alerte = await _repository.getAlerteById(id);
    final updatedAlerte = alerte.copyWith(statut: 'In Progress');

    return await _repository.updateAlerte(id, updatedAlerte);
  }

  // Delete alerte
  Future<void> deleteAlerte(String id) async {
    if (id.isEmpty) {
      throw Exception('ID invalide');
    }
    return await _repository.deleteAlerte(id);
  }

  // Get alertes by priority
  Future<List<AlerteModel>> getAlertesByPriority(String priorite) async {
    if (!['Critique', 'Modérée', 'Mineure'].contains(priorite)) {
      throw Exception('Priorité invalide');
    }
    return await _repository.getAlertesByPriority(priorite);
  }

  // Get alertes by status
  Future<List<AlerteModel>> getAlertesByStatus(String statut) async {
    if (!['New', 'In Progress', 'Resolved'].contains(statut)) {
      throw Exception('Statut invalide');
    }
    return await _repository.getAlertesByStatus(statut);
  }

  // Get unresolved alertes
  Future<List<AlerteModel>> getUnresolvedAlertes() async {
    return await _repository.getUnresolvedAlertes();
  }

  // Get critical alertes
  Future<List<AlerteModel>> getCriticalAlertes() async {
    return await _repository.getCriticalAlertes();
  }

  // Sort alertes by date (newest first)
  List<AlerteModel> sortByDate(List<AlerteModel> alertes) {
    final sorted = List<AlerteModel>.from(alertes);
    sorted.sort((a, b) {
      if (a.createdAt == null && b.createdAt == null) return 0;
      if (a.createdAt == null) return 1;
      if (b.createdAt == null) return -1;
      return b.createdAt!.compareTo(a.createdAt!);
    });
    return sorted;
  }

  // Sort alertes by priority (Critical > Moderate > Minor)
  List<AlerteModel> sortByPriority(List<AlerteModel> alertes) {
    const priorityOrder = {'Critique': 1, 'Modérée': 2, 'Mineure': 3};
    final sorted = List<AlerteModel>.from(alertes);
    sorted.sort((a, b) {
      final priorityA = priorityOrder[a.priorite] ?? 999;
      final priorityB = priorityOrder[b.priorite] ?? 999;
      return priorityA.compareTo(priorityB);
    });
    return sorted;
  }

  // Filter alertes by search query
  List<AlerteModel> filterBySearch(List<AlerteModel> alertes, String query) {
    if (query.trim().isEmpty) return alertes;

    final lowerQuery = query.toLowerCase();
    return alertes.where((alerte) {
      return alerte.titre.toLowerCase().contains(lowerQuery) ||
          alerte.description.toLowerCase().contains(lowerQuery) ||
          (alerte.lieu?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }

  // Get statistics
  Map<String, int> getStatistics(List<AlerteModel> alertes) {
    return {
      'total': alertes.length,
      'new': alertes.where((a) => a.statut == 'New').length,
      'inProgress': alertes.where((a) => a.statut == 'In Progress').length,
      'resolved': alertes.where((a) => a.statut == 'Resolved').length,
      'critical': alertes.where((a) => a.priorite == 'Critique').length,
      'moderate': alertes.where((a) => a.priorite == 'Modérée').length,
      'minor': alertes.where((a) => a.priorite == 'Mineure').length,
    };
  }

  // Dispose
  void dispose() {
    _repository.dispose();
  }
}