import 'package:flutter/material.dart';
import '../models/pointage_model.dart';
import '../repositories/pointage_repository.dart';

enum EmployeeStatus {
  present,
  absent,
  notPointed,
}

class PointageViewModel extends ChangeNotifier {
  final PointageRepository _repository = PointageRepository();
  PointageRepository get repository => _repository;

  bool _isLoading = false;
  String? _errorMessage;
  PointageModel? _lastPointage;
  bool _hasEntree = false;
  bool _hasSortie = false;
  PointageModel? _entreePointage;
  PointageModel? _sortiePointage;
  List<PointageModel> _weekPointages = [];

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  PointageModel? get lastPointage => _lastPointage;
  bool get hasEntree => _hasEntree;
  bool get hasSortie => _hasSortie;
  PointageModel? get entreePointage => _entreePointage;
  PointageModel? get sortiePointage => _sortiePointage;
  List<PointageModel> get weekPointages => _weekPointages;

  EmployeeStatus get employeeStatus {
    if (!_hasEntree && !_hasSortie) {
      return EmployeeStatus.notPointed;
    }
    if (_hasEntree && _entreePointage?.etat == PointageEtat.absent) {
      return EmployeeStatus.absent;
    }
    return EmployeeStatus.present;
  }

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Récupérer le pointage du jour
  Future<void> fetchTodayPointage() async {
    try {
      print('🔄 [VM] Récupération du pointage du jour...');
      setLoading(true);
      _errorMessage = null;

      final todayData = await _repository.getTodayPointage();

      _hasEntree = todayData['hasEntree'] ?? false;
      _hasSortie = todayData['hasSortie'] ?? false;

      if (todayData['entree'] != null) {
        _entreePointage = PointageModel.fromJson(todayData['entree'] as Map<String, dynamic>);
        _lastPointage = _entreePointage;
      }

      if (todayData['sortie'] != null) {
        _sortiePointage = PointageModel.fromJson(todayData['sortie'] as Map<String, dynamic>);
        _lastPointage = _sortiePointage;
      }

      print('✅ [VM] Pointage récupéré: Entrée=$_hasEntree, Sortie=$_hasSortie');
      setLoading(false);
    } catch (e) {
      print('❌ [VM] Erreur récupération: $e');
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      setLoading(false);
    }
  }

  /// Créer un pointage depuis un QR Code
  Future<bool> createPointageFromQR({
    required String qrCodeData,
    required BuildContext context,
  }) async {
    try {
      print('========================================');
      print('📤 [VM] Traitement QR: $qrCodeData');

      setLoading(true);
      _errorMessage = null;

      // Parser le QR Code: TYPE|DATE|HEURE
      final parts = qrCodeData.split('|');

      if (parts.length != 3) {
        throw Exception('Format QR invalide. Format attendu: TYPE|DATE|HEURE');
      }

      final type = parts[0].trim().toUpperCase();
      String date = parts[1].trim();
      final heure = parts[2].trim();

      print('🔍 Type brut: $type');
      print('🔍 Date brute: $date');
      print('🔍 Heure brute: $heure');

      // Convertir la date si nécessaire
      if (date.contains('/')) {
        final dateParts = date.split('/');
        if (dateParts.length == 3) {
          final day = dateParts[0].padLeft(2, '0');
          final month = dateParts[1].padLeft(2, '0');
          final year = dateParts[2];
          date = '$year-$month-$day';
          print('📅 Date convertie: $date');
        }
      }

      // Validation du format final
      final dateRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
      final heureRegex = RegExp(r'^\d{2}:\d{2}$');

      if (!dateRegex.hasMatch(date)) {
        throw Exception('Format de date invalide. Attendu: YYYY-MM-DD (ex: 2025-10-05)');
      }

      if (!heureRegex.hasMatch(heure)) {
        throw Exception('Format d\'heure invalide. Attendu: HH:mm (ex: 14:30)');
      }

      // Validation du type
      if (type != 'ENTREE' && type != 'SORTIE') {
        throw Exception('Type invalide. Doit être ENTREE ou SORTIE');
      }

      print('✅ Données validées');
      print('📤 Envoi au backend: Type=$type, Date=$date, Heure=$heure');
      print('========================================');

      // Créer le pointage
      await _repository.createPointage(
        type: type,
        date: date,
        heure: heure,
      );

      print('✅ [VM] Pointage créé avec succès');

      // Rafraîchir les données
      await fetchTodayPointage();

      setLoading(false);
      return true;
    } catch (e) {
      print('❌ [VM] Erreur création pointage: $e');
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      setLoading(false);
      return false;
    }
  }

  /// Récupérer tous les pointages pour une période (admin)
  Future<void> fetchAllPointagesByWeek({
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      print('🔄 [VM] Récupération des pointages de la semaine...');
      setLoading(true);
      _errorMessage = null;

      final pointages = await _repository.getAllPointagesByWeek(
        start: start,
        end: end,
      );

      _weekPointages = pointages;
      print('✅ [VM] ${pointages.length} pointages récupérés');
      setLoading(false);
      notifyListeners();
    } catch (e) {
      print('❌ [VM] Erreur récupération: $e');
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      setLoading(false);
      notifyListeners();
    }
  }

  // Méthodes pour l'UI
  String getStatusText() {
    switch (employeeStatus) {
      case EmployeeStatus.present:
        return 'Présent';
      case EmployeeStatus.absent:
        return 'Absent (Retard)';
      case EmployeeStatus.notPointed:
        return 'Non pointé';
    }
  }

  Color getStatusColor() {
    switch (employeeStatus) {
      case EmployeeStatus.present:
        return const Color(0xFF7ED957);
      case EmployeeStatus.absent:
        return Colors.orange;
      case EmployeeStatus.notPointed:
        return Colors.red;
    }
  }

  IconData getStatusIcon() {
    switch (employeeStatus) {
      case EmployeeStatus.present:
        return Icons.check_circle;
      case EmployeeStatus.absent:
        return Icons.warning;
      case EmployeeStatus.notPointed:
        return Icons.cancel;
    }
  }

  String? getLastPointageText() {
    if (_lastPointage == null) return null;

    final type = _lastPointage!.type == PointageType.entree ? 'Entrée' : 'Sortie';
    final heure = _lastPointage!.heure;
    return '$type à $heure';
  }
}