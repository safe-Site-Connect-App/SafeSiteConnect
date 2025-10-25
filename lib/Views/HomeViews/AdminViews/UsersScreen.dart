import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/user_model.dart';
import '../../../ViewsModels/user_viewmodel.dart';

import 'CustomBottomNavigationBarAdmin.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> with TickerProviderStateMixin {
  int _currentIndex = 1;
  final String _adminName = "Admin Principal";
  String _searchQuery = '';
  late UserViewModel _userViewModel;

  @override
  void initState() {
    super.initState();
    _userViewModel = Provider.of<UserViewModel>(context, listen: false);
    _loadUsers();
  }

  void _loadUsers() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _userViewModel.loadUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(),
      body: _buildBody(),
      bottomNavigationBar: CustomBottomNavigationBarAdmin(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF005B96),
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Gestion utilisateurs",
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
          Text(
            _adminName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      automaticallyImplyLeading: false,
      actions: [
        GestureDetector(
          onTap: () => _showAddEmployeeDialog(),
          child: Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF7ED957),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                Icon(Icons.add, color: Colors.white, size: 16),
                SizedBox(width: 4),
                Text(
                  "Ajouter",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    return Consumer<UserViewModel>(
      builder: (context, viewModel, child) {
        return SingleChildScrollView(
          child: Column(
            children: [
              _buildHeaderGradient(),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSearchSection(),
                    const SizedBox(height: 16),
                    _buildUsersSection(viewModel),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeaderGradient() {
    return Container(
      height: 40,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF005B96), Color(0xFFF8F9FA)],
        ),
      ),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      decoration: _cardDecoration(),
      padding: const EdgeInsets.all(16),
      child: TextField(
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: "Rechercher par nom...",
          hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
          prefixIcon: Icon(Icons.search, color: Colors.grey[500], size: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: const Color(0xFFF1F5F9),
          contentPadding: const EdgeInsets.symmetric(
              vertical: 12, horizontal: 12),
        ),
        style: const TextStyle(fontSize: 14),
      ),
    );
  }

  Widget _buildUsersSection(UserViewModel viewModel) {
    return Container(
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF005B96),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.people, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    "Utilisateurs",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  if (viewModel.isLoading)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: _buildUsersList(viewModel),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersList(UserViewModel viewModel) {
    if (viewModel.isLoading && viewModel.users.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(
            color: Color(0xFF005B96),
          ),
        ),
      );
    }

    if (viewModel.errorMessage != null) {
      return _buildErrorState(viewModel);
    }

    final filteredUsers = viewModel.getFilteredUsers(_searchQuery);

    if (filteredUsers.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredUsers.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) =>
          _buildEmployeeCard(filteredUsers[index] as UserModel, viewModel),
    );
  }

  Widget _buildErrorState(UserViewModel viewModel) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                  Icons.error_outline, size: 40, color: Colors.red),
            ),
            const SizedBox(height: 12),
            Text(
              "Erreur",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            Text(
              viewModel.errorMessage!,
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                viewModel.clearError();
                _loadUsers();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF005B96),
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text("Réessayer", style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeeCard(UserModel employee, UserViewModel viewModel) {
    Color statusColor = _getStatusColor(
        employee.isActive ?? true ? 'Actif' : 'Inactif');

    return GestureDetector(
      onTap: () => _showUserDetailsDialog(employee, viewModel),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.person, color: statusColor, size: 20),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        employee.nom,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF005B96),
                        ),
                      ),
                      Text(
                        '${employee.role} • ${employee.poste ?? 'N/A'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    employee.isActive ?? true ? 'Actif' : 'Inactif',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.email_outlined, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      employee.email,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: viewModel.isLoading
                        ? null
                        : () => _showEditEmployeeDialog(employee, viewModel),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF005B96),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.edit, size: 14),
                    label: const Text(
                        "Modifier", style: TextStyle(fontSize: 11)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: viewModel.isLoading
                        ? null
                        : () =>
                        _showDeleteConfirmationDialog(employee, viewModel),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFEF4444),
                      side: const BorderSide(color: Color(0xFFEF4444)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.delete, size: 14),
                    label: const Text(
                        "Supprimer", style: TextStyle(fontSize: 11)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.search_off, size: 40, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          Text(
            "Aucun utilisateur trouvé",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          Text(
            "Essayez un autre nom",
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.white, Color(0xFFF8F9FA)],
      ),
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Actif':
        return const Color(0xFF10B981);
      case 'En congé':
        return const Color(0xFFF59E0B);
      case 'Inactif':
        return const Color(0xFFEF4444);
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  void _showAddEmployeeDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    String? selectedRole;
    String? selectedPost;
    String? selectedDepartement;

    showDialog(
      context: context,
      builder: (context) =>
          Dialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: Container(
              width: MediaQuery
                  .of(context)
                  .size
                  .width * 0.85,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, Color(0xFFF8F9FA)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: StatefulBuilder(
                builder: (context, setDialogState) {
                  return Consumer<UserViewModel>(
                    builder: (context, viewModel, child) {
                      return SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF7ED957).withOpacity(
                                        0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(Icons.person_add,
                                      color: Color(0xFF7ED957), size: 16),
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  "Ajouter utilisateur",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF005B96),
                                  ),
                                ),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 16),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ],
                            ),
                            if (viewModel.errorMessage != null) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: Colors.red.withOpacity(0.3)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                        Icons.error_outline, color: Colors.red,
                                        size: 16),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        viewModel.errorMessage!,
                                        style: const TextStyle(
                                            color: Colors.red, fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: nameController,
                              decoration: _buildInputDecoration(
                                  'Nom', Icons.person_outline),
                              style: const TextStyle(fontSize: 12),
                              enabled: !viewModel.isLoading,
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: emailController,
                              decoration: _buildInputDecoration(
                                  'Email', Icons.email_outlined),
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(fontSize: 12),
                              enabled: !viewModel.isLoading,
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: passwordController,
                              decoration: _buildInputDecoration(
                                  'Mot de passe', Icons.lock_outline),
                              obscureText: true,
                              style: const TextStyle(fontSize: 12),
                              enabled: !viewModel.isLoading,
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: confirmPasswordController,
                              decoration: _buildInputDecoration(
                                  'Confirmer mot de passe', Icons.lock_outline),
                              obscureText: true,
                              style: const TextStyle(fontSize: 12),
                              enabled: !viewModel.isLoading,
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: selectedRole,
                              decoration: _buildInputDecoration(
                                  'Rôle', Icons.person_pin),
                              items: ['Admin', 'Employee']
                                  .map((role) =>
                                  DropdownMenuItem(
                                    value: role,
                                    child: Text(role,
                                        style: const TextStyle(fontSize: 12)),
                                  ))
                                  .toList(),
                              onChanged: viewModel.isLoading
                                  ? null
                                  : (value) {
                                setDialogState(() => selectedRole = value);
                              },
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: selectedPost,
                              decoration: _buildInputDecoration(
                                  'Poste', Icons.work_outline),
                              items: [
                                'Technicien',
                                'Manager',
                                'Opérateur',
                                'Superviseur',
                                'Administrateur'
                              ]
                                  .map((post) =>
                                  DropdownMenuItem(
                                    value: post,
                                    child: Text(post,
                                        style: const TextStyle(fontSize: 12)),
                                  ))
                                  .toList(),
                              onChanged: viewModel.isLoading
                                  ? null
                                  : (value) {
                                setDialogState(() => selectedPost = value);
                              },
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: selectedDepartement,
                              decoration: _buildInputDecoration(
                                  'Département', Icons.business_outlined),
                              items: [
                                'Technique',
                                'Management',
                                'Production',
                                'Qualité',
                                'Administration'
                              ]
                                  .map((dept) =>
                                  DropdownMenuItem(
                                    value: dept,
                                    child: Text(dept,
                                        style: const TextStyle(fontSize: 12)),
                                  ))
                                  .toList(),
                              onChanged: viewModel.isLoading
                                  ? null
                                  : (value) {
                                setDialogState(() =>
                                selectedDepartement = value);
                              },
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: viewModel.isLoading
                                        ? null
                                        : () => Navigator.pop(context),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF005B96),
                                      side: const BorderSide(
                                          color: Color(0xFF005B96)),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8),
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                              8)),
                                    ),
                                    child: const Text("Annuler",
                                        style: TextStyle(fontSize: 11,
                                            fontWeight: FontWeight.w600)),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: viewModel.isLoading
                                        ? null
                                        : () async {
                                      if (nameController.text.isNotEmpty &&
                                          emailController.text.isNotEmpty &&
                                          passwordController.text.isNotEmpty &&
                                          confirmPasswordController.text
                                              .isNotEmpty &&
                                          passwordController.text ==
                                              confirmPasswordController.text &&
                                          selectedRole != null &&
                                          selectedPost != null &&
                                          selectedDepartement != null) {
                                        viewModel.clearError();

                                        final success = await viewModel
                                            .createUser(
                                          nom: nameController.text,
                                          email: emailController.text,
                                          motdepasse: passwordController.text,
                                          confirmMotdepasse: confirmPasswordController
                                              .text,
                                          role: selectedRole!,
                                          poste: selectedPost!,
                                          departement: selectedDepartement!,
                                        );

                                        if (success) {
                                          Navigator.pop(context);
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  "Utilisateur ajouté avec succès"),
                                              backgroundColor: Color(
                                                  0xFF7ED957),
                                            ),
                                          );
                                        }
                                      } else {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                "Veuillez remplir tous les champs correctement"),
                                            backgroundColor: Colors.orange,
                                          ),
                                        );
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF7ED957),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8),
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                              8)),
                                    ),
                                    child: viewModel.isLoading
                                        ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                        : const Text("Ajouter",
                                        style: TextStyle(fontSize: 11,
                                            fontWeight: FontWeight.w600)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
    );
  }

  void _showEditEmployeeDialog(UserModel employee, UserViewModel viewModel) {
    final nameController = TextEditingController(text: employee.nom);
    final emailController = TextEditingController(text: employee.email);
    // ❌ Pas de champ mot de passe - le backend ne l'accepte pas
    String? selectedRole = employee.role;
    String? selectedPost = employee.poste;
    String? selectedDepartement = employee.departement;

    showDialog(
      context: context,
      builder: (context) =>
          Dialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: Container(
              width: MediaQuery
                  .of(context)
                  .size
                  .width * 0.85,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, Color(0xFFF8F9FA)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: StatefulBuilder(
                builder: (context, setDialogState) {
                  return Consumer<UserViewModel>(
                    builder: (context, vm, child) {
                      return SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF005B96).withOpacity(
                                        0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(
                                      Icons.edit, color: Color(0xFF005B96),
                                      size: 16),
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    "Modifier ${employee.nom}",
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF005B96),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 16),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ],
                            ),
                            if (vm.errorMessage != null) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: Colors.red.withOpacity(0.3)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                        Icons.error_outline, color: Colors.red,
                                        size: 16),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        vm.errorMessage!,
                                        style: const TextStyle(
                                            color: Colors.red, fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: nameController,
                              decoration: _buildInputDecoration(
                                  'Nom', Icons.person_outline),
                              style: const TextStyle(fontSize: 12),
                              enabled: !vm.isLoading,
                            ),
                            const SizedBox(height: 8),
                            // ✅ CHAMP EMAIL DÉSACTIVÉ
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextFormField(
                                  controller: emailController,
                                  decoration: _buildInputDecoration(
                                      'Email (non modifiable)',
                                      Icons.email_outlined).copyWith(
                                    suffixIcon: Icon(Icons.lock, size: 16,
                                        color: Colors.grey[400]),
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey[600]),
                                  enabled: false, // Email non modifiable
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(
                                      left: 12, top: 4),
                                  child: Text(
                                    "⚠️ L'email et le mot de passe ne peuvent pas être modifiés",
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.orange[700],
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            // ❌ CHAMP MOT DE PASSE COMPLÈTEMENT RETIRÉ
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: selectedRole,
                              decoration: _buildInputDecoration(
                                  'Rôle', Icons.person_pin),
                              items: ['Admin', 'Employee']
                                  .map((role) =>
                                  DropdownMenuItem(
                                    value: role,
                                    child: Text(role,
                                        style: const TextStyle(fontSize: 12)),
                                  ))
                                  .toList(),
                              onChanged: vm.isLoading
                                  ? null
                                  : (value) {
                                setDialogState(() => selectedRole = value);
                              },
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: selectedPost,
                              decoration: _buildInputDecoration(
                                  'Poste', Icons.work_outline),
                              items: [
                                'Technicien',
                                'Manager',
                                'Opérateur',
                                'Superviseur',
                                'Administrateur'
                              ]
                                  .map((post) =>
                                  DropdownMenuItem(
                                    value: post,
                                    child: Text(post,
                                        style: const TextStyle(fontSize: 12)),
                                  ))
                                  .toList(),
                              onChanged: vm.isLoading
                                  ? null
                                  : (value) {
                                setDialogState(() => selectedPost = value);
                              },
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: selectedDepartement,
                              decoration: _buildInputDecoration(
                                  'Département', Icons.business_outlined),
                              items: [
                                'Technique',
                                'Management',
                                'Production',
                                'Qualité',
                                'Administration'
                              ]
                                  .map((dept) =>
                                  DropdownMenuItem(
                                    value: dept,
                                    child: Text(dept,
                                        style: const TextStyle(fontSize: 12)),
                                  ))
                                  .toList(),
                              onChanged: vm.isLoading
                                  ? null
                                  : (value) {
                                setDialogState(() =>
                                selectedDepartement = value);
                              },
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: vm.isLoading ? null : () =>
                                        Navigator.pop(context),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF005B96),
                                      side: const BorderSide(
                                          color: Color(0xFF005B96)),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8),
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                              8)),
                                    ),
                                    child: const Text("Annuler",
                                        style: TextStyle(fontSize: 11,
                                            fontWeight: FontWeight.w600)),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: vm.isLoading
                                        ? null
                                        : () async {
                                      if (nameController.text.isNotEmpty &&
                                          selectedRole != null &&
                                          selectedPost != null &&
                                          selectedDepartement != null) {
                                        vm.clearError();

                                        // ✅ Pas de mot de passe envoyé
                                        final success = await vm.updateUser(
                                          userId: employee.id,
                                          nom: nameController.text,
                                          role: selectedRole!,
                                          poste: selectedPost!,
                                          departement: selectedDepartement!,
                                          // ❌ motdepasse retiré complètement
                                        );

                                        if (success) {
                                          Navigator.pop(context);
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  "Utilisateur modifié avec succès"),
                                              backgroundColor: Color(
                                                  0xFF005B96),
                                            ),
                                          );
                                        }
                                      } else {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                "Veuillez remplir tous les champs obligatoires"),
                                            backgroundColor: Colors.orange,
                                          ),
                                        );
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF005B96),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8),
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                              8)),
                                    ),
                                    child: vm.isLoading
                                        ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                        : const Text("Modifier",
                                        style: TextStyle(fontSize: 11,
                                            fontWeight: FontWeight.w600)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
    );
  }

  void _showDeleteConfirmationDialog(UserModel employee,
      UserViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            title: Row(
              children: [
                const Icon(Icons.warning, color: Color(0xFFEF4444), size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: const Text(
                    "Confirmer la suppression",
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Êtes-vous sûr de vouloir supprimer ${employee.nom} ?"),
                const SizedBox(height: 8),
                Text(
                  "Cette action est irréversible.",
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Annuler"),
              ),
              Consumer<UserViewModel>(
                builder: (context, vm, child) {
                  return ElevatedButton(
                    onPressed: vm.isLoading
                        ? null
                        : () async {
                      final success = await vm.deleteUser(employee.id!);
                      if (success) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("${employee.nom} a été supprimé"),
                            backgroundColor: const Color(0xFFEF4444),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                    ),
                    child: vm.isLoading
                        ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : const Text("Supprimer"),
                  );
                },
              ),
            ],
          ),
    );
  }

  void _showUserDetailsDialog(UserModel employee, UserViewModel viewModel) {
    Color statusColor = _getStatusColor(
        employee.isActive ?? true ? 'Actif' : 'Inactif');

    showDialog(
      context: context,
      builder: (context) =>
          Dialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            child: Container(
              width: MediaQuery
                  .of(context)
                  .size
                  .width * 0.9,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, Color(0xFFF8F9FA)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                              Icons.person, color: statusColor, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                employee.nom,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF005B96),
                                ),
                              ),
                              Text(
                                employee.email,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildInfoRow(
                        Icons.info_outline, 'ID', employee.id ?? 'N/A'),
                    _buildInfoRow(Icons.badge, 'Rôle', employee.role),
                    _buildInfoRow(Icons.work, 'Poste', employee.poste ?? 'N/A'),
                    _buildInfoRow(Icons.business, 'Département',
                        employee.departement ?? 'N/A'),
                    _buildInfoRow(
                      Icons.calendar_today,
                      'Date de création',
                      employee.createdAt != null ? _formatDate(
                          employee.createdAt!) : 'N/A',
                    ),
                    _buildInfoRow(Icons.email, 'Email', employee.email),
                    _buildInfoRow(Icons.lock, 'Mot de passe', '••••••••'),
                    _buildInfoRow(Icons.info, 'Statut',
                        employee.isActive ?? true ? 'Actif' : 'Inactif',
                        color: statusColor),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF005B96),
                              side: const BorderSide(color: Color(0xFF005B96)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.close, size: 16),
                            label: const Text("Fermer", style: TextStyle(
                                fontSize: 12)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _showEditEmployeeDialog(employee, viewModel);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF005B96),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.edit, size: 16),
                            label: const Text("Modifier", style: TextStyle(
                                fontSize: 12)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value,
      {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF005B96).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
                icon, size: 16, color: color ?? const Color(0xFF005B96)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF005B96),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey[600], fontSize: 12),
      prefixIcon: Icon(icon, size: 16, color: Colors.grey[600]),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      filled: true,
      fillColor: const Color(0xFFF1F5F9),
      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
    );
  }
}