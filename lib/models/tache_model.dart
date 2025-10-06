class TacheModel {
  final String? id;
  final String titre;
  final String? description;
  final String priorite;
  final String? zone;
  final String statut;
  final UserAssignee? assigneA;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  TacheModel({
    this.id,
    required this.titre,
    this.description,
    required this.priorite,
    this.zone,
    required this.statut,
    this.assigneA,
    this.createdAt,
    this.updatedAt,
  });

  factory TacheModel.fromJson(Map<String, dynamic> json) {
    return TacheModel(
      id: json['_id'] as String?,
      titre: json['titre'] as String,
      description: json['description'] as String?,
      priorite: json['priorite'] as String,
      zone: json['zone'] as String?,
      statut: json['statut'] as String? ?? 'New',
      assigneA: json['assigneA'] != null
          ? UserAssignee.fromJson(json['assigneA'] as Map<String, dynamic>)
          : null,
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
      'titre': titre,
      if (description != null) 'description': description,
      'priorite': priorite,
      if (zone != null) 'zone': zone,
      'statut': statut,
      if (assigneA != null) 'assigneA': assigneA!.id,
    };
  }

  TacheModel copyWith({
    String? id,
    String? titre,
    String? description,
    String? priorite,
    String? zone,
    String? statut,
    UserAssignee? assigneA,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TacheModel(
      id: id ?? this.id,
      titre: titre ?? this.titre,
      description: description ?? this.description,
      priorite: priorite ?? this.priorite,
      zone: zone ?? this.zone,
      statut: statut ?? this.statut,
      assigneA: assigneA ?? this.assigneA,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class UserAssignee {
  final String id;
  final String nom;
  final String email;
  final String? role;
  final String? poste;

  UserAssignee({
    required this.id,
    required this.nom,
    required this.email,
    this.role,
    this.poste,
  });

  factory UserAssignee.fromJson(Map<String, dynamic> json) {
    return UserAssignee(
      id: json['_id'] as String,
      nom: json['nom'] as String,
      email: json['email'] as String,
      role: json['role'] as String?,
      poste: json['poste'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'nom': nom,
      'email': email,
      if (role != null) 'role': role,
      if (poste != null) 'poste': poste,
    };
  }
}

class CreateTacheDto {
  final String titre;
  final String? description;
  final String priorite;
  final String? zone;
  final String statut;
  final String assigneA; // User ID

  CreateTacheDto({
    required this.titre,
    this.description,
    required this.priorite,
    this.zone,
    this.statut = 'New',
    required this.assigneA,
  });

  Map<String, dynamic> toJson() {
    return {
      'titre': titre,
      if (description != null) 'description': description,
      'priorite': priorite,
      if (zone != null) 'zone': zone,
      'statut': statut,
      'assigneA': assigneA,
    };
  }
}

class UpdateTacheDto {
  final String? titre;
  final String? description;
  final String? priorite;
  final String? zone;
  final String? statut;
  final String? assigneA;

  UpdateTacheDto({
    this.titre,
    this.description,
    this.priorite,
    this.zone,
    this.statut,
    this.assigneA,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (titre != null) data['titre'] = titre;
    if (description != null) data['description'] = description;
    if (priorite != null) data['priorite'] = priorite;
    if (zone != null) data['zone'] = zone;
    if (statut != null) data['statut'] = statut;
    if (assigneA != null) data['assigneA'] = assigneA;
    return data;
  }
}