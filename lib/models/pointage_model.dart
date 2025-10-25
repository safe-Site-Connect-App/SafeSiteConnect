class PointageModel {
  final String? id;
  final String user;
  final String userName;
  final DateTime date;
  final String heure;
  final PointageType type;
  final PointageEtat etat;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PointageModel({
    this.id,
    required this.user,
    required this.userName,
    required this.date,
    required this.heure,
    required this.type,
    required this.etat,
    this.createdAt,
    this.updatedAt,
  });

  factory PointageModel.fromJson(Map<String, dynamic> json) {
    // Handle user field (either a string ID, nested object, or missing)
    String userId;
    if (json['user'] is String) {
      userId = json['user'] as String;
    } else if (json['user'] is Map<String, dynamic>) {
      userId = json['user']['_id'] as String? ?? '';
    } else if (json['id'] != null) {
      // Si user est absent mais id est présent, utiliser id comme fallback
      userId = json['id'] as String? ?? '';
    } else if (json['_id'] != null) {
      // Si user est absent mais _id est présent, utiliser _id comme fallback
      userId = json['_id'] as String? ?? '';
    } else {
      // Si aucun identifiant n'est trouvé, utiliser une valeur par défaut
      userId = '';
    }

    // Handle userName field (either from userName or user.nom)
    String userName;
    if (json['userName'] != null && json['userName'] is String) {
      userName = json['userName'] as String;
    } else if (json['user'] is Map<String, dynamic> && json['user']['nom'] != null) {
      userName = json['user']['nom'] as String;
    } else {
      userName = 'Unknown'; // Fallback if neither is present
    }

    return PointageModel(
      id: json['_id'] as String?,
      user: userId,
      userName: userName,
      date: DateTime.parse(json['date'] as String),
      heure: json['heure'] as String,
      type: PointageType.fromString(json['type'] as String),
      etat: PointageEtat.fromString(json['etat'] as String),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'user': user,
      'userName': userName,
      'date': date.toIso8601String(),
      'heure': heure,
      'type': type.value,
      'etat': etat.value,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  PointageModel copyWith({
    String? id,
    String? user,
    String? userName,
    DateTime? date,
    String? heure,
    PointageType? type,
    PointageEtat? etat,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PointageModel(
      id: id ?? this.id,
      user: user ?? this.user,
      userName: userName ?? this.userName,
      date: date ?? this.date,
      heure: heure ?? this.heure,
      type: type ?? this.type,
      etat: etat ?? this.etat,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

enum PointageType {
  entree('ENTREE'),
  sortie('SORTIE');

  final String value;
  const PointageType(this.value);

  static PointageType fromString(String value) {
    return PointageType.values.firstWhere(
          (e) => e.value == value,
      orElse: () => PointageType.entree,
    );
  }
}

enum PointageEtat {
  present('Present'),
  absent('Absent');

  final String value;
  const PointageEtat(this.value);

  static PointageEtat fromString(String value) {
    return PointageEtat.values.firstWhere(
          (e) => e.value == value,
      orElse: () => PointageEtat.present,
    );
  }
}

class CreatePointageDto {
  final DateTime date;
  final String heure;
  final PointageType type;

  CreatePointageDto({
    required this.date,
    required this.heure,
    required this.type,
  });

  Map<String, dynamic> toJson() {
    // Format: YYYY-MM-DD (ex: 2025-10-06)
    final formattedDate = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    return {
      'date': formattedDate,
      'heure': heure,
      'type': type.value,
    };
  }
}

class TodayPointageResponse {
  final bool hasEntree;
  final bool hasSortie;
  final PointageModel? entree;
  final PointageModel? sortie;

  TodayPointageResponse({
    required this.hasEntree,
    required this.hasSortie,
    this.entree,
    this.sortie,
  });

  factory TodayPointageResponse.fromJson(Map<String, dynamic> json) {
    return TodayPointageResponse(
      hasEntree: json['hasEntree'] as bool,
      hasSortie: json['hasSortie'] as bool,
      entree: json['entree'] != null
          ? PointageModel.fromJson(json['entree'] as Map<String, dynamic>)
          : null,
      sortie: json['sortie'] != null
          ? PointageModel.fromJson(json['sortie'] as Map<String, dynamic>)
          : null,
    );
  }
}