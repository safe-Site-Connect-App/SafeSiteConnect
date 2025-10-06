class AlerteModel {
  final String? id;
  final String titre;
  final String description;
  final String priorite;
  final String? lieu;
  final String statut;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AlerteModel({
    this.id,
    required this.titre,
    required this.description,
    required this.priorite,
    this.lieu,
    required this.statut,
    this.createdAt,
    this.updatedAt,
  });

  // Factory constructor from JSON
  factory AlerteModel.fromJson(Map<String, dynamic> json) {
    return AlerteModel(
      id: json['_id'] ?? json['id'],
      titre: json['titre'] ?? '',
      description: json['description'] ?? '',
      priorite: json['priorite'] ?? 'Mineure',
      lieu: json['lieu'],
      statut: json['statut'] ?? 'New',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'titre': titre,
      'description': description,
      'priorite': priorite,
      if (lieu != null) 'lieu': lieu,
      'statut': statut,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  // Create DTO for API (without id)
  Map<String, dynamic> toCreateDto() {
    return {
      'titre': titre,
      'description': description,
      'priorite': priorite,
      if (lieu != null && lieu!.isNotEmpty) 'lieu': lieu,
      'statut': statut,
    };
  }

  // Update DTO for API
  Map<String, dynamic> toUpdateDto() {
    return {
      'titre': titre,
      'description': description,
      'priorite': priorite,
      if (lieu != null) 'lieu': lieu,
      'statut': statut,
    };
  }

  // CopyWith method for immutability
  AlerteModel copyWith({
    String? id,
    String? titre,
    String? description,
    String? priorite,
    String? lieu,
    String? statut,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AlerteModel(
      id: id ?? this.id,
      titre: titre ?? this.titre,
      description: description ?? this.description,
      priorite: priorite ?? this.priorite,
      lieu: lieu ?? this.lieu,
      statut: statut ?? this.statut,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper methods
  bool get isResolved => statut == 'Resolved';
  bool get isNew => statut == 'New';
  bool get isInProgress => statut == 'In Progress';
  bool get isCritical => priorite == 'Critique';
  bool get isModerate => priorite == 'Modérée';
  bool get isMinor => priorite == 'Mineure';

  String getFormattedDate() {
    if (createdAt == null) return '';
    final day = createdAt!.day.toString().padLeft(2, '0');
    final month = createdAt!.month.toString().padLeft(2, '0');
    final year = createdAt!.year;
    final hour = createdAt!.hour.toString().padLeft(2, '0');
    final minute = createdAt!.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  @override
  String toString() {
    return 'AlerteModel(id: $id, titre: $titre, priorite: $priorite, statut: $statut)';
  }
}

// Enums for type safety
enum AlertePriorite {
  critique('Critique'),
  moderee('Modérée'),
  mineure('Mineure');

  final String value;
  const AlertePriorite(this.value);

  static AlertePriorite fromString(String value) {
    return AlertePriorite.values.firstWhere(
          (e) => e.value == value,
      orElse: () => AlertePriorite.mineure,
    );
  }
}

enum AlerteStatut {
  nouveau('New'),
  enCours('In Progress'),
  resolu('Resolved');

  final String value;
  const AlerteStatut(this.value);

  static AlerteStatut fromString(String value) {
    return AlerteStatut.values.firstWhere(
          (e) => e.value == value,
      orElse: () => AlerteStatut.nouveau,
    );
  }

  String get displayName {
    switch (this) {
      case AlerteStatut.nouveau:
        return 'Nouvelle';
      case AlerteStatut.enCours:
        return 'En cours';
      case AlerteStatut.resolu:
        return 'Résolue';
    }
  }
}