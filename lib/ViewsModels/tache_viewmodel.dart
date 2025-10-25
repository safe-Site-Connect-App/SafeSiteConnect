// TacheViewModel.dart
import 'package:flutter/foundation.dart';
import '../models/tache_model.dart';
import '../services/tache_service.dart';
import '../utils/constants.dart';

class TacheViewModel extends ChangeNotifier {
  final TacheService _tacheService;

  List<TacheModel> _allTaches = [];
  List<TacheModel> _filteredTaches = [];
  bool _isLoading = false;
  String? _errorMessage;

  String _searchQuery = '';
  String? _filterZone;
  String? _filterPriorite;
  String? _filterStatut;
  String _sortBy = 'date';

  TacheViewModel({TacheService? tacheService})
      : _tacheService = tacheService ?? TacheService();

  // Getters
  List<TacheModel> get allTaches => _allTaches;
  List<TacheModel> get filteredTaches => _filteredTaches;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get sortBy => _sortBy;
  String? get filterZone => _filterZone;
  String? get filterPriorite => _filterPriorite;
  String? get filterStatut => _filterStatut;

  // Statistiques
  int get totalTaches => _allTaches.length;
  int get tachesNew => _allTaches.where((t) => t.statut == TacheStatut.nouveau).length;
  int get tachesInProgress => _allTaches.where((t) => t.statut == TacheStatut.enCours).length;
  int get tachesCompleted => _allTaches.where((t) => t.statut == TacheStatut.termine).length;
  int get tachesP1 => _allTaches.where((t) => t.priorite == TachePriorite.p1).length;

  List<TacheModel> get todayTasks {
    final today = DateTime.now();
    return _allTaches.where((task) {
      if (task.createdAt == null) return false;
      final date = task.createdAt!;
      return date.year == today.year &&
          date.month == today.month &&
          date.day == today.day;
    }).toList();
  }

  List<TacheModel> get criticalTasksToday {
    return todayTasks.where((t) => t.priorite == TachePriorite.p1).toList();
  }

  bool get hasActiveFilters =>
      _searchQuery.isNotEmpty || _filterZone != null ||
          _filterPriorite != null || _filterStatut != null;

  // Charger les tâches de l'utilisateur connecté
  Future<void> loadUserTaches(String userId) async {
    if (userId.isEmpty) {
      _errorMessage = 'ID utilisateur invalide';
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _allTaches = await _tacheService.fetchTachesByUser();
      _applyFiltersAndSort();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _allTaches = [];
      _filteredTaches = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Charger toutes les tâches
  Future<void> loadAllTaches() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _allTaches = await _tacheService.fetchAllTaches();
      _applyFiltersAndSort();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _allTaches = [];
      _filteredTaches = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Créer une tâche
  Future<bool> createTache({
    required String titre,
    String? description,
    required String priorite,
    String? zone,
    required String statut,
    required String assigneA,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newTache = await _tacheService.createTache(
        titre: titre,
        description: description,
        priorite: priorite,
        zone: zone,
        statut: statut,
        assigneA: assigneA,
      );

      _allTaches.insert(0, newTache);
      _applyFiltersAndSort();
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Réassigner une tâche
  Future<bool> reassignTache({
    required String tacheId,
    required String newUserId,
    String? newStatut,
  }) async {
    try {
      final updatedTache = await _tacheService.reassignTache(
        tacheId: tacheId,
        newUserId: newUserId,
        newStatut: newStatut,
      );

      final index = _allTaches.indexWhere((t) => t.id == tacheId);
      if (index != -1) {
        _allTaches[index] = updatedTache;
        _applyFiltersAndSort();
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Changer le statut
  Future<bool> changeStatus({
    required String tacheId,
    required String newStatut,
  }) async {
    try {
      final updatedTache = await _tacheService.changeStatus(
        tacheId: tacheId,
        newStatut: newStatut,
      );

      final index = _allTaches.indexWhere((t) => t.id == tacheId);
      if (index != -1) {
        _allTaches[index] = updatedTache;
        _applyFiltersAndSort();
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Supprimer une tâche
  Future<bool> deleteTache(String tacheId) async {
    try {
      await _tacheService.deleteTache(tacheId);
      _allTaches.removeWhere((t) => t.id == tacheId);
      _applyFiltersAndSort();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Recherche
  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFiltersAndSort();
    notifyListeners();
  }

  // Filtres
  void applyFilters({
    String? zone,
    String? priorite,
    String? statut,
  }) {
    _filterZone = zone;
    _filterPriorite = priorite;
    _filterStatut = statut;
    _applyFiltersAndSort();
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _filterZone = null;
    _filterPriorite = null;
    _filterStatut = null;
    _applyFiltersAndSort();
    notifyListeners();
  }

  void setSortBy(String sortBy) {
    _sortBy = sortBy;
    _applyFiltersAndSort();
    notifyListeners();
  }

  void _applyFiltersAndSort() {
    List<TacheModel> result = List.from(_allTaches);

    if (_searchQuery.isNotEmpty) {
      result = result.where((tache) {
        final titleMatch = tache.titre.toLowerCase().contains(_searchQuery.toLowerCase());
        final idMatch = tache.id?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false;
        return titleMatch || idMatch;
      }).toList();
    }

    if (_filterZone != null) {
      result = _tacheService.filterByZone(result, _filterZone!);
    }
    if (_filterPriorite != null) {
      result = _tacheService.filterByPriority(result, _filterPriorite!);
    }
    if (_filterStatut != null) {
      result = _tacheService.filterByStatus(result, _filterStatut!);
    }

    if (_sortBy == 'date') {
      result = _tacheService.sortByDate(result);
    } else if (_sortBy == 'priority') {
      result = _tacheService.sortByPriority(result);
    }

    _filteredTaches = result;
  }

  @override
  void dispose() {
    _tacheService.dispose();
    super.dispose();
  }
}