import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../Provider/Providertheme.dart';
import '../../../ViewsModels/auth_viewmodel.dart';
import '../../../ViewsModels/user_viewmodel.dart';
import '../../../navigation/CustomBottomNavigationBar.dart';

class ProfilEmployePage extends StatefulWidget {
  const ProfilEmployePage({super.key});

  @override
  State<ProfilEmployePage> createState() => _ProfilEmployePageState();
}

class _ProfilEmployePageState extends State<ProfilEmployePage> {
  int _currentIndex = 4;
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    await authViewModel.loadUserFromStorage();
    setState(() {
      _isLoadingProfile = false;
    });
  }




  Future<void> _handleLogout() async {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF005B96),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Déconnexion', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await authViewModel.logout();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/signin');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final authViewModel = Provider.of<AuthViewModel>(context);
    final user = authViewModel.currentUser;

    return Scaffold(
      backgroundColor: theme.brightness == Brightness.dark
          ? const Color(0xFF121212)
          : const Color(0xFFF8F9FA),
      appBar: _buildAppBar(themeProvider),
      body: _isLoadingProfile
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF005B96)))
          : user == null
          ? _buildErrorState()
          : _buildBody(context, user),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }

  AppBar _buildAppBar(ThemeProvider themeProvider) {
    final theme = Theme.of(context);
    return AppBar(
      backgroundColor: const Color(0xFF005B96),
      elevation: 0,
      title: const Text(
        "Mon Profil",
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      automaticallyImplyLeading: false,

    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Erreur de chargement du profil',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadUserProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF005B96),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Réessayer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, user) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildHeaderGradient(),
          Padding(
            padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildProfileHeader(user),
                const SizedBox(height: 32),
                _buildInfoCard(user),
                const SizedBox(height: 32),
                _buildActionButtons(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderGradient() {
    return Container(
      height: 60,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF005B96), Color(0xFFF8F9FA)],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(user) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF7ED957), width: 4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 60,
            backgroundColor: const Color(0xFF7ED957),
            child: Text(
              user.nom.isNotEmpty ? user.nom[0].toUpperCase() : '?',
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          user.nom,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF005B96),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          user.role ?? 'Rôle non spécifié',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        if (user.poste != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF005B96).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.work, size: 16, color: Color(0xFF005B96)),
                const SizedBox(width: 8),
                Text(
                  user.poste!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF005B96),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoCard(user) {
    return Container(
      decoration: _cardDecoration(),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF005B96).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.info_outline, color: Color(0xFF005B96), size: 24),
                ),
                const SizedBox(width: 12),
                const Flexible(
                  child: Text(
                    "Infos Personnelles",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF005B96),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildInfoRow(Icons.email, "Email", user.email),
            if (user.poste != null) ...[
              const Divider(height: 20, color: Colors.grey),
              _buildInfoRow(Icons.badge, "Poste", user.poste!),
            ],
            if (user.departement != null) ...[
              const Divider(height: 20, color: Colors.grey),
              _buildInfoRow(Icons.business, "Département", user.departement!),
            ],
            const Divider(height: 20, color: Colors.grey),
            _buildInfoRow(Icons.verified_user, "Rôle", user.role ?? 'N/A'),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _handleLogout,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF005B96), width: 2),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.logout, color: Color(0xFF005B96), size: 20),
            label: const Text(
              "Déconnexion",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF005B96),
              ),
            ),
          ),
        ),
      ],
    );
  }

  BoxDecoration _cardDecoration() {
    final theme = Theme.of(context);
    return BoxDecoration(
      gradient: theme.brightness == Brightness.dark
          ? const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF2D2D2D), Color(0xFF1E1E1E)],
      )
          : const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.white, Color(0xFFF8F9FA)],
      ),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: const Color(0xFF005B96)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: theme.brightness == Brightness.dark
                      ? Colors.grey[400]
                      : Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF005B96),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}