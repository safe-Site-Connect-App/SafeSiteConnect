import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../../../ViewsModels/pointage_viewmodel.dart';
import '../../../navigation/CustomBottomNavigationBar.dart';
import 'QRScannerScreen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  final String _employeeName = "Hassan Fayech";
  bool _hasActiveAlert = true;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimation();
    // ✅ CORRECTION: Utiliser WidgetsBinding pour charger après la construction
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTodayPointage();
    });
  }

  void _initializeAnimation() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _loadTodayPointage() async {
    if (!mounted) return;
    print('🔄 [HOME] Chargement du pointage du jour...');
    final pointageVM = Provider.of<PointageViewModel>(context, listen: false);
    await pointageVM.fetchTodayPointage();
    print('✅ [HOME] Pointage chargé');
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _scanQRCode() async {
    print('📷 [HOME] Demande de permission caméra...');
    final PermissionStatus permission = await Permission.camera.request();

    switch (permission) {
      case PermissionStatus.granted:
        print('✅ [HOME] Permission accordée');
        if (mounted) {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ChangeNotifierProvider.value(
                value: Provider.of<PointageViewModel>(context, listen: false),
                child: const QRScannerScreen(),
              ),
            ),
          );

          print('🔙 [HOME] Retour du scanner - Résultat: $result');

          if (result == true && mounted) {
            print('🔄 [HOME] Rafraîchissement après succès...');
            await _loadTodayPointage();
          }
        }
        break;
      case PermissionStatus.denied:
        print('⚠️ [HOME] Permission refusée');
        _showPermissionDialog();
        break;
      case PermissionStatus.permanentlyDenied:
        print('❌ [HOME] Permission refusée définitivement');
        _showSettingsDialog();
        break;
      default:
        print('❓ [HOME] Statut de permission inconnu: $permission');
        break;
    }
  }

  void _showPermissionDialog() {
    _showDialog(
      title: 'Autorisation caméra',
      icon: Icons.camera_alt,
      content: 'L\'accès à la caméra est nécessaire pour scanner les codes QR. Veuillez autoriser l\'accès dans les paramètres.',
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            _scanQRCode();
          },
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF005B96)),
          child: const Text('Réessayer', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  void _showSettingsDialog() {
    _showDialog(
      title: 'Paramètres requis',
      icon: Icons.settings,
      content: 'L\'autorisation caméra a été refusée de façon permanente. Veuillez l\'activer manuellement dans les paramètres de l\'application.',
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            openAppSettings();
          },
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF005B96)),
          child: const Text('Ouvrir paramètres', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  void _showDialog({
    required String title,
    required IconData icon,
    required String content,
    required List<Widget> actions,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(icon, color: const Color(0xFF005B96)),
              const SizedBox(width: 8),
              Text(title),
            ],
          ),
          content: Text(content),
          actions: actions,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(),
      body: _buildBody(),
      floatingActionButton: _buildFloatingActionButton(),
      bottomNavigationBar: CustomBottomNavigationBar(
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
            "Bonjour,",
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
          Text(
            _employeeName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      automaticallyImplyLeading: false,
      actions: [
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 24),
              onPressed: () {},
            ),
            if (_hasActiveAlert)
              const Positioned(
                right: 8,
                top: 8,
                child: CircleAvatar(
                  radius: 4,
                  backgroundColor: Colors.red,
                ),
              ),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildBody() {
    return RefreshIndicator(
      onRefresh: _loadTodayPointage,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            _buildHeaderGradient(),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildEmployeeStatusCard(),
                  const SizedBox(height: 32),
                  _buildPriorityTasksSection(),
                  const SizedBox(height: 32),
                  Consumer<PointageViewModel>(
                    builder: (context, pointageVM, _) {
                      final shouldShowAlert = pointageVM.employeeStatus == EmployeeStatus.absent ||
                          pointageVM.employeeStatus == EmployeeStatus.notPointed;

                      if (shouldShowAlert && _hasActiveAlert) {
                        return _buildAlertSection();
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
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

  Widget _buildEmployeeStatusCard() {
    return Consumer<PointageViewModel>(
      builder: (context, pointageVM, _) {
        final statusText = pointageVM.getStatusText();
        final statusColor = pointageVM.getStatusColor();
        final statusIcon = pointageVM.getStatusIcon();
        final lastPointageText = pointageVM.getLastPointageText();

        return Container(
          decoration: _cardDecoration(),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCardHeader(Icons.badge_outlined, "Statut de l'employé"),
                const SizedBox(height: 20),
                if (pointageVM.isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 6,
                          backgroundColor: statusColor,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 16,
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Icon(statusIcon, color: statusColor, size: 20),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    Icons.access_time,
                    "Dernier pointage",
                    lastPointageText ?? "Aucun pointage aujourd'hui",
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.assignment, "Tâches du jour", "3 à effectuer"),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPriorityTasksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCardHeader(Icons.priority_high, "Tâches prioritaires du jour"),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            children: [
              _buildTaskCard("Inspection machine", "Zone A", "14:00", "Voir", Icons.search, const Color(0xFF4CAF50)),
              _buildTaskCard("Rapport sécurité", "Zone B", "16:00", "Valider", Icons.security, const Color(0xFFFF9800)),
              _buildTaskCard("Maintenance", "Zone C", "17:00", "Voir", Icons.build, const Color(0xFF2196F3)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAlertSection() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            decoration: _alertDecoration(),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCardHeader(Icons.warning, "Alerte de sécurité active", color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    "Veuillez confirmer votre présence sur site pour des raisons de sécurité.",
                    style: TextStyle(fontSize: 15, color: Colors.red, height: 1.4),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => setState(() => _hasActiveAlert = false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7ED957),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                      ),
                      icon: const Icon(Icons.check_circle),
                      label: const Text(
                        "Confirmer ma présence",
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFloatingActionButton() {
    return Container(
      decoration: _fabDecoration(),
      child: FloatingActionButton(
        onPressed: _scanQRCode,
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 24),
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

  BoxDecoration _alertDecoration() {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.red.shade50, Colors.red.shade100.withOpacity(0.3)],
      ),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.red.withOpacity(0.3), width: 2),
      boxShadow: [
        BoxShadow(
          color: Colors.red.withOpacity(0.1),
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  BoxDecoration _fabDecoration() {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF005B96), Color(0xFF007BB8)],
      ),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF005B96).withOpacity(0.3),
          blurRadius: 15,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  Widget _buildCardHeader(IconData icon, String title, {Color color = const Color(0xFF005B96)}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(icon == Icons.priority_high ? 8 : 12),
          ),
          child: Icon(icon, color: color, size: icon == Icons.priority_high ? 20 : 24),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: icon == Icons.priority_high ? 20 : 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          "$label: ",
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF005B96),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTaskCard(
      String title,
      String zone,
      String deadline,
      String action,
      IconData icon,
      Color accentColor,
      ) {
    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: 16),
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
                    color: accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: accentColor, size: 20),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    deadline,
                    style: TextStyle(
                      fontSize: 12,
                      color: accentColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF005B96),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              zone,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                child: Text(
                  action,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}