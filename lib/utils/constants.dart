// ==================== BASE CONFIGURATION ====================
class ApiConstants {
  static const String baseUrl = 'http://192.168.1.147:3000';
  static const String apiVersion = '';

  // ==================== AUTH ENDPOINTS ====================
  static const String signup = '/auth/signup';
  static const String login = '/auth/login';
  static const String refreshToken = '/auth/refresh';
  static const String adminUsers = '/auth/admin/users';
  static const String profile = '/auth/profile'; // Added to match the backend endpoint

  // ==================== USER ENDPOINTS ====================
  static const String users = '/users';
  // Removed userProfile since it's not used and conflicts with /auth/profile

  // ==================== POINTAGE ENDPOINTS ====================
  static const String pointagesCreate = '/pointages/create';
  static const String pointagesToday = '/pointages/today';
  static const String pointagesUser = '/pointages/user';
  static const String pointagesWeek = '/pointages/week';
  static const String pointagesReport = '/pointages/report';

  // ==================== ALERTE ENDPOINTS ====================
  static const String alertes = '/alertes';

  // ==================== TACHE ENDPOINTS ====================
  static const String taches = '/taches';
  static const String myTasks = '/taches/my-tasks'; // New endpoint for user tasks

  // ==================== PERMISSION ENDPOINTS ====================
  static const String permissions = '/permissions';
  static const String roles = '/roles';

  // ==================== OTHER ENDPOINTS ====================
  static const String departments = '/departments';
  static const String posts = '/posts';
  static const String stats = '/stats';

  // ==================== HEADERS ====================
  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // ==================== FULL URLS ====================
  static String get fullBaseUrl => '$baseUrl$apiVersion';

  // Auth URLs
  static String get signupUrl => '$fullBaseUrl$signup';
  static String get loginUrl => '$fullBaseUrl$login';
  static String get refreshTokenUrl => '$fullBaseUrl$refreshToken';
  static String get adminUsersUrl => '$fullBaseUrl$adminUsers';
  static String get profileUrl => '$fullBaseUrl$profile'; // Added full URL for profile

  // Pointage URLs
  static String get pointagesCreateUrl => '$fullBaseUrl$pointagesCreate';
  static String get pointagesTodayUrl => '$fullBaseUrl$pointagesToday';
  static String get pointagesWeekUrl => '$fullBaseUrl$pointagesWeek';
  static String get pointagesReportUrl => '$fullBaseUrl$pointagesReport';

  // Alerte URLs
  static String get alertesUrl => '$fullBaseUrl$alertes';
  static String get alertesCreateUrl => '$fullBaseUrl$alertes';
  static String alerteByIdUrl(String id) => '$fullBaseUrl$alertes/$id';

  // Tache URLs
  static String get tachesUrl => '$fullBaseUrl$taches';
  static String get myTasksUrl => '$fullBaseUrl$myTasks';
  static String tacheByIdUrl(String id) => '$fullBaseUrl$taches/$id';

  // Method to get user pointages URL with userId
  static String pointagesUserUrl(String userId) => '$fullBaseUrl$pointagesUser/$userId';

  // ==================== CONFIGURATION HELPERS ====================

  // Timeout durations
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // QR Code format validation
  static const String qrCodePattern = r'^(ENTREE|SORTIE)\|(\d{4}-\d{2}-\d{2})\|(\d{2}:\d{2})$';

  // Working hours
  static const int workStartHour = 8;
  static const int lateArrivalHour = 10;
  static const int workEndHour = 17;

  // ==================== ERROR MESSAGES ====================
  static const String networkError = 'Erreur de connexion au serveur';
  static const String timeoutError = 'La requête a expiré';
  static const String unauthorizedError = 'Non autorisé. Veuillez vous reconnecter';
  static const String serverError = 'Erreur serveur. Veuillez réessayer';
  static const String invalidQRFormat = 'Format de QR code invalide';
  static const String cameraPermissionDenied = 'Permission caméra refusée';

  // ==================== SUCCESS MESSAGES ====================
  static const String pointageCreatedSuccess = 'Pointage enregistré avec succès';
  static const String loginSuccess = 'Connexion réussie';
  static const String logoutSuccess = 'Déconnexion réussie';
  static const String alerteCreatedSuccess = 'Alerte créée avec succès';
  static const String alerteUpdatedSuccess = 'Alerte mise à jour avec succès';
  static const String alerteResolvedSuccess = 'Alerte marquée comme résolue';
  static const String alerteDeletedSuccess = 'Alerte supprimée avec succès';
  static const String tacheCreatedSuccess = 'Tâche créée avec succès';
  static const String tacheUpdatedSuccess = 'Tâche mise à jour avec succès';
  static const String tacheDeletedSuccess = 'Tâche supprimée avec succès';
  static const String tacheAssignedSuccess = 'Tâche assignée avec succès';
  static const String tacheStatusChangedSuccess = 'Statut de la tâche modifié';

  // ==================== VALIDATION ====================

  // Valider le format du QR code
  static bool isValidQRCode(String qrCode) {
    return RegExp(qrCodePattern).hasMatch(qrCode);
  }

  // Vérifier si l'heure est valide (format HH:MM)
  static bool isValidTime(String time) {
    final timeRegex = RegExp(r'^([0-1][0-9]|2[0-3]):[0-5][0-9]$');
    return timeRegex.hasMatch(time);
  }

  // Vérifier si c'est une heure de retard
  static bool isLateArrival(String time) {
    final parts = time.split(':');
    if (parts.length != 2) return false;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);

    if (hour == null || minute == null) return false;

    return hour > lateArrivalHour || (hour == lateArrivalHour && minute > 0);
  }

  // ==================== DEVELOPMENT/PRODUCTION SWITCH ====================

  // Pour basculer facilement entre dev et prod
  static bool get isDevelopment => true;

  static String get environmentBaseUrl {
    if (isDevelopment) {
      return 'http://192.168.1.177:3000'; // Dev
    } else {
      return 'https://api.votre-domaine.com'; // Production
    }
  }
}

// ==================== API RESPONSE STATUS ====================
class ApiStatus {
  static const int success = 200;
  static const int created = 201;
  static const int badRequest = 400;
  static const int unauthorized = 401;
  static const int forbidden = 403;
  static const int notFound = 404;
  static const int serverError = 500;
}

// ==================== STORAGE KEYS ====================
class StorageKeys {
  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';
  static const String userId = 'user_id';
  static const String userName = 'user_name';
  static const String userEmail = 'user_email';
  static const String userRole = 'user_role';
  static const String isLoggedIn = 'is_logged_in';
  static const String lastPointageDate = 'last_pointage_date';
}

// ==================== TACHE ENUMS ====================
class TachePriorite {
  static const String p1 = 'P1';
  static const String p2 = 'P2';
  static const String p3 = 'P3';

  static List<String> get all => [p1, p2, p3];

  static String getLabel(String priorite) {
    switch (priorite) {
      case p1:
        return 'Priorité 1 - Urgent';
      case p2:
        return 'Priorité 2 - Important';
      case p3:
        return 'Priorité 3 - Normal';
      default:
        return 'Non défini';
    }
  }
}

class TacheStatut {
  static const String nouveau = 'New';
  static const String enCours = 'In Progress';
  static const String termine = 'Completed';

  static List<String> get all => [nouveau, enCours, termine];

  static String getLabel(String statut) {
    switch (statut) {
      case nouveau:
        return 'Nouvelle';
      case enCours:
        return 'En cours';
      case termine:
        return 'Terminée';
      default:
        return 'Non défini';
    }
  }
}

class TacheType {
  static const String maintenance = 'Maintenance';
  static const String qualite = 'Qualité';
  static const String securite = 'Sécurité';

  static List<String> get all => [maintenance, qualite, securite];
}

class TacheZone {
  static const String zoneA = 'Zone A';
  static const String zoneB = 'Zone B';
  static const String zoneC = 'Zone C';
  static const String dataCenterA = 'Data Center A';

  static List<String> get all => [zoneA, zoneB, zoneC, dataCenterA];
}

// ==================== COLOR CONSTANTS ====================
class AppColors {
  static const primaryColor = 0xFF005B96;
  static const secondaryColor = 0xFF007BB8;
  static const backgroundColor = 0xFFF8F9FA;
  static const cardBackground = 0xFFFFFFFF;

  // Priority colors
  static const priorityP1 = 0xFFEF4444; // Rouge
  static const priorityP2 = 0xFFF59E0B; // Orange
  static const priorityP3 = 0xFF10B981; // Vert

  // Status colors
  static const statusNew = 0xFFF59E0B; // Orange
  static const statusInProgress = 0xFF8B5CF6; // Violet
  static const statusCompleted = 0xFF10B981; // Vert
}

// ==================== TEXT STYLES ====================
class AppTextStyles {
  static const appBarTitle = 'Gestion des tâches';
  static const emptyStateTitle = 'Aucune tâche trouvée';
  static const emptyStateSubtitle = 'Essayez d\'autres filtres ou termes de recherche';
  static const searchHint = 'Rechercher par titre ou ID...';
  static const filterDialogTitle = 'Filtrer les tâches';
  static const addTaskDialogTitle = 'Ajouter une tâche';
  static const assignDialogTitle = 'Réassigner';
  static const deleteConfirmTitle = 'Confirmer la suppression';
  static const deleteConfirmMessage = 'Êtes-vous sûr de vouloir supprimer cette tâche ?';
}

// ==================== ROUTES ====================
class AppRoutes {
  static const String home = '/';
  static const String login = '/login';
  static const String taches = '/taches';
  static const String alertes = '/alertes';
  static const String pointages = '/pointages';
  static const String profile = '/profile';
  static const String users = '/users';
}