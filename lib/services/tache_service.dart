import '../models/tache_model.dart';
import '../repositories/tache_repository.dart';

class TacheService {
  final TacheRepository _repository;

  TacheService({TacheRepository? repository})
      : _repository = repository ?? TacheRepository();

  // Créer une nouvelle tâche
  Future<TacheModel> createTache({
    required String titre,
    String? description,
    required String priorite,
    String? zone,
    String statut = 'New',
    required String assigneA,
  }) async {
    try {
      final createDto = CreateTacheDto(
        titre: titre,
        description: description,
        priorite: priorite,
        zone: zone,
        statut: statut,
        assigneA: assigneA,
      );

      return await _repository.createTache(createDto);
    } catch (e) {
      throw Exception('Service: Erreur création tâche - ${e.toString()}');
    }
  }

  // Récupérer toutes les tâches
  Future<List<TacheModel>> fetchAllTaches() async {
    try {
      return await _repository.getAllTaches();
    } catch (e) {
      throw Exception('Service: Erreur récupération tâches - ${e.toString()}');
    }
  }

  // Récupérer les tâches de l'utilisateur connecté
  Future<List<TacheModel>> fetchTachesByUser() async {
    try {
      return await _repository.getTachesByUser();
    } catch (e) {
      throw Exception('Service: Erreur récupération tâches utilisateur - ${e.toString()}');
    }
  }

  // Récupérer une tâche par ID
  Future<TacheModel> fetchTacheById(String tacheId) async {
    try {
      return await _repository.getTacheById(tacheId);
    } catch (e) {
      throw Exception('Service: Erreur récupération tâche - ${e.toString()}');
    }
  }

  // Mettre à jour une tâche
  Future<TacheModel> updateTache({
    required String tacheId,
    String? titre,
    String? description,
    String? priorite,
    String? zone,
    String? statut,
    String? assigneA,
  }) async {
    try {
      final updateDto = UpdateTacheDto(
        titre: titre,
        description: description,
        priorite: priorite,
        zone: zone,
        statut: statut,
        assigneA: assigneA,
      );

      return await _repository.updateTache(tacheId, updateDto);
    } catch (e) {
      throw Exception('Service: Erreur mise à jour tâche - ${e.toString()}');
    }
  }

  // Assigner une tâche à un autre utilisateur
  Future<TacheModel> reassignTache({
    required String tacheId,
    required String newUserId,
    String? newStatut,
  }) async {
    try {
      final updateDto = UpdateTacheDto(
        assigneA: newUserId,
        statut: newStatut,
      );

      return await _repository.updateTache(tacheId, updateDto);
    } catch (e) {
      throw Exception('Service: Erreur réassignation tâche - ${e.toString()}');
    }
  }

  // Changer le statut d'une tâche
  Future<TacheModel> changeStatus({
    required String tacheId,
    required String newStatut,
  }) async {
    try {
      final updateDto = UpdateTacheDto(statut: newStatut);
      return await _repository.updateTache(tacheId, updateDto);
    } catch (e) {
      throw Exception('Service: Erreur changement statut - ${e.toString()}');
    }
  }

  // Supprimer une tâche
  Future<void> deleteTache(String tacheId) async {
    try {
      await _repository.deleteTache(tacheId);
    } catch (e) {
      throw Exception('Service: Erreur suppression tâche - ${e.toString()}');
    }
  }

  // Récupérer tous les utilisateurs
  Future<List<UserAssignee>> fetchAllUsers() async {
    try {
      return await _repository.getAllUsers();
    } catch (e) {
      throw Exception('Service: Erreur récupération utilisateurs - ${e.toString()}');
    }
  }

  // Filtrer les tâches par statut
  List<TacheModel> filterByStatus(List<TacheModel> taches, String statut) {
    return taches.where((tache) => tache.statut == statut).toList();
  }

  // Filtrer les tâches par priorité
  List<TacheModel> filterByPriority(List<TacheModel> taches, String priorite) {
    return taches.where((tache) => tache.priorite == priorite).toList();
  }

  // Filtrer les tâches par zone
  List<TacheModel> filterByZone(List<TacheModel> taches, String zone) {
    return taches.where((tache) => tache.zone == zone).toList();
  }

  // Trier les tâches par date (plus récent en premier)
  List<TacheModel> sortByDate(List<TacheModel> taches) {
    final sorted = List<TacheModel>.from(taches);
    sorted.sort((a, b) {
      if (a.createdAt == null || b.createdAt == null) return 0;
      return b.createdAt!.compareTo(a.createdAt!);
    });
    return sorted;
  }

  // Trier les tâches par priorité (P1 > P2 > P3)
  List<TacheModel> sortByPriority(List<TacheModel> taches) {
    final priorityOrder = {'P1': 1, 'P2': 2, 'P3': 3};
    final sorted = List<TacheModel>.from(taches);
    sorted.sort((a, b) {
      final priorityA = priorityOrder[a.priorite] ?? 999;
      final priorityB = priorityOrder[b.priorite] ?? 999;
      return priorityA.compareTo(priorityB);
    });
    return sorted;
  }

  void dispose() {
    _repository.dispose();
  }
}