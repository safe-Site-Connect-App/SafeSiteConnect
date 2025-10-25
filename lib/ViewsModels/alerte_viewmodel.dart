import 'package:flutter/foundation.dart';
import '../models/alerte_model.dart';
import '../services/alerte_service.dart';

class AlerteViewModel extends ChangeNotifier {
  final AlerteService _service;

  AlerteViewModel({AlerteService? service})
      : _service = service ?? AlerteService();

  // State variables
  List<AlerteModel> _alertes = [];
  List<AlerteModel> _filteredAlertes = [];
  bool _isLoading = false;
  String? _error;
  String _sortBy = 'date'; // 'date' or 'priority'
  String _searchQuery = '';

  // Getters
  List<AlerteModel> get alertes => _filteredAlertes;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get sortBy => _sortBy;
  bool get hasError => _error != null;
  int get totalCount => _alertes.length;
  int get unresolvedCount => _alertes.where((a) => !a.isResolved).length;
  int get criticalCount => _alertes.where((a) => a.isCritical).length;

  // Get statistics
  Map<String, int> get statistics => _service.getStatistics(_alertes);

  // Initialize - Load all alertes
  Future<void> initialize() async {
    await loadAlertes();
  }

  // Load all alertes
  Future<void> loadAlertes() async {
    _setLoading(true);
    _clearError();

    try {
      _alertes = await _service.getAllAlertes();
      _applyFiltersAndSort();
      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  // Create new alerte
  Future<bool> createAlerte({
    required String titre,
    required String description,
    required String priorite,
    String? lieu,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final newAlerte = await _service.createAlerte(
        titre: titre,
        description: description,
        priorite: priorite,
        lieu: lieu,
      );

      _alertes.insert(0, newAlerte);
      _applyFiltersAndSort();
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Update alerte
  Future<bool> updateAlerte({
    required String id,
    required String titre,
    required String description,
    required String priorite,
    String? lieu,
    String? statut,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final updatedAlerte = await _service.updateAlerte(
        id: id,
        titre: titre,
        description: description,
        priorite: priorite,
        lieu: lieu,
        statut: statut,
      );

      final index = _alertes.indexWhere((a) => a.id == id);
      if (index != -1) {
        _alertes[index] = updatedAlerte;
        _applyFiltersAndSort();
      }

      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Mark alerte as resolved
  Future<bool> markAsResolved(String id) async {
    _setLoading(true);
    _clearError();

    try {
      final updatedAlerte = await _service.markAsResolved(id);

      final index = _alertes.indexWhere((a) => a.id == id);
      if (index != -1) {
        _alertes[index] = updatedAlerte;
        _applyFiltersAndSort();
      }

      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Mark alerte as in progress
  Future<bool> markAsInProgress(String id) async {
    _setLoading(true);
    _clearError();

    try {
      final updatedAlerte = await _service.markAsInProgress(id);

      final index = _alertes.indexWhere((a) => a.id == id);
      if (index != -1) {
        _alertes[index] = updatedAlerte;
        _applyFiltersAndSort();
      }

      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Delete alerte
  Future<bool> deleteAlerte(String id) async {
    _setLoading(true);
    _clearError();

    try {
      await _service.deleteAlerte(id);
      _alertes.removeWhere((a) => a.id == id);
      _applyFiltersAndSort();
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Get alerte by ID
  Future<AlerteModel?> getAlerteById(String id) async {
    try {
      return await _service.getAlerteById(id);
    } catch (e) {
      _setError(e.toString());
      return null;
    }
  }

  // Sort alertes
  void sortAlertes(String sortType) {
    _sortBy = sortType;
    _applyFiltersAndSort();
  }

  // Search alertes
  void searchAlertes(String query) {
    _searchQuery = query;
    _applyFiltersAndSort();
  }

  // Filter by priority
  void filterByPriority(String priorite) {
    _filteredAlertes = _alertes.where((a) => a.priorite == priorite).toList();
    _applySorting();
    notifyListeners();
  }

  // Filter by status
  void filterByStatus(String statut) {
    _filteredAlertes = _alertes.where((a) => a.statut == statut).toList();
    _applySorting();
    notifyListeners();
  }

  // Show only unresolved
  void showUnresolved() {
    _filteredAlertes = _alertes.where((a) => !a.isResolved).toList();
    _applySorting();
    notifyListeners();
  }

  // Show only critical
  void showCritical() {
    _filteredAlertes = _alertes.where((a) => a.isCritical).toList();
    _applySorting();
    notifyListeners();
  }

  // Clear all filters
  void clearFilters() {
    _searchQuery = '';
    _applyFiltersAndSort();
  }

  // Refresh alertes
  Future<void> refresh() async {
    await loadAlertes();
  }

  // Private methods
  void _applyFiltersAndSort() {
    _filteredAlertes = List.from(_alertes);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      _filteredAlertes = _service.filterBySearch(_filteredAlertes, _searchQuery);
    }

    // Apply sorting
    _applySorting();

    notifyListeners();
  }

  void _applySorting() {
    if (_sortBy == 'date') {
      _filteredAlertes = _service.sortByDate(_filteredAlertes);
    } else if (_sortBy == 'priority') {
      _filteredAlertes = _service.sortByPriority(_filteredAlertes);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _error = message;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  // Toggle read status (local only - for UI purposes)
  void toggleReadStatus(String id) {
    final index = _alertes.indexWhere((a) => a.id == id);
    if (index != -1) {
      // This is just for local UI state
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}