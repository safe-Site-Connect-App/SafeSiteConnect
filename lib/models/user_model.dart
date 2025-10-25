class UserModel {
  final String id;
  final String nom;
  final String email;
  final String role;
  final String? poste;
  final String? departement;
  final bool? isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.id,
    required this.nom,
    required this.email,
    required this.role,
    this.poste,
    this.departement,
    this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? json['id'] ?? '',
      nom: json['nom'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',  // CRITIQUE: Le rôle doit être présent
      poste: json['poste'],
      departement: json['departement'],
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'nom': nom,
      'email': email,
      'role': role,
      if (poste != null) 'poste': poste,
      if (departement != null) 'departement': departement,
      if (isActive != null) 'isActive': isActive,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  // Vérifier si l'utilisateur est admin
  bool get isAdmin => role.toLowerCase() == 'admin';

  // Vérifier si l'utilisateur est employee
  bool get isEmployee => role.toLowerCase() == 'employee';

  UserModel copyWith({
    String? id,
    String? nom,
    String? email,
    String? role,
    String? poste,
    String? departement,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      email: email ?? this.email,
      role: role ?? this.role,
      poste: poste ?? this.poste,
      departement: departement ?? this.departement,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, nom: $nom, email: $email, role: $role, poste: $poste)';
  }
}