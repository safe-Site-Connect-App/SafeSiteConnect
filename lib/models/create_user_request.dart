class CreateUserRequest {
  final String nom;
  final String email;
  final String motdepasse;
  final String confirmMotdepasse;
  final String role;
  final String poste;
  final String departement;

  CreateUserRequest({
    required this.nom,
    required this.email,
    required this.motdepasse,
    required this.confirmMotdepasse,
    required this.role,
    required this.poste,
    required this.departement,
  });

  Map<String, dynamic> toJson() {
    return {
      'nom': nom,
      'email': email,
      'motdepasse': motdepasse,
      'confirmMotdepasse': confirmMotdepasse,
      'role': role,
      'poste': poste,
      'departement': departement,
    };
  }
}