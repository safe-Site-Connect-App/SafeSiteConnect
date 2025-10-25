import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../../../ViewsModels/pointage_viewmodel.dart';
import '../../../navigation/CustomBottomNavigationBar.dart';
import 'QRScannerScreen.dart';
import 'package:intl/intl.dart';

class PointageScreen extends StatefulWidget {
  const PointageScreen({super.key});

  @override
  State<PointageScreen> createState() => _PointageScreenState();
}

class _PointageScreenState extends State<PointageScreen> {
  int _currentIndex = 1;
  List<Map<String, dynamic>> _historyData = [];
  bool _isLoadingHistory = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final pointageVM = Provider.of<PointageViewModel>(context, listen: false);

    // Charger le statut du jour
    await pointageVM.fetchTodayPointage();

    // Charger l'historique (30 derniers jours)
    await _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoadingHistory = true);

    try {
      final pointageVM = Provider.of<PointageViewModel>(context, listen: false);

      // Calculer la période (30 derniers jours)
      final endDate = DateTime.now();
      final startDate = endDate.subtract(const Duration(days: 30));

      final history = await pointageVM.repository.getPointageHistory(
        startDate: DateFormat('yyyy-MM-dd').format(startDate),
        endDate: DateFormat('yyyy-MM-dd').format(endDate),
      );

      setState(() {
        _historyData = history;
        _isLoadingHistory = false;
      });
    } catch (e) {
      print('❌ Erreur chargement historique: $e');
      setState(() => _isLoadingHistory = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de chargement: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _scanQRCode() async {
    final PermissionStatus permission = await Permission.camera.request();

    switch (permission) {
      case PermissionStatus.granted:
        if (mounted) {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ChangeNotifierProvider.value(
                value: Provider.of<PointageViewModel>(context, listen: false),
                child: const QRScannerScreen(),
              ),
            ),
          );

          // Rafraîchir les données après le scan
          if (result == true && mounted) {
            await _loadData();
          }
        }
        break;
      case PermissionStatus.denied:
        _showPermissionDialog();
        break;
      case PermissionStatus.permanentlyDenied:
        _showSettingsDialog();
        break;
      default:
        break;
    }
  }

  void _showPermissionDialog() {
    _showDialog(
      title: 'Autorisation caméra',
      icon: Icons.camera_alt,
      content: 'L\'accès à la caméra est nécessaire pour scanner les codes QR.',
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
      content: 'Veuillez activer l\'autorisation caméra dans les paramètres.',
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
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _buildBody(),
      ),
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
      title: const Text(
        "Mon Pointage",
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      automaticallyImplyLeading: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white, size: 24),
          onPressed: _loadData,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          _buildHeaderGradient(),
          Padding(
            padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusCard(),
                const SizedBox(height: 32),
                _buildHistorySection(),
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

  Widget _buildStatusCard() {
    return Consumer<PointageViewModel>(
      builder: (context, pointageVM, _) {
        if (pointageVM.isLoading) {
          return Container(
            decoration: _cardDecoration(),
            padding: const EdgeInsets.all(40),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

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
                _buildCardHeader(Icons.badge_outlined, "Statut du jour"),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(statusIcon, color: statusColor, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
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
                _buildInfoRow(
                  Icons.calendar_today,
                  "Date",
                  DateFormat('dd/MM/yyyy').format(DateTime.now()),
                ),
                if (pointageVM.hasEntree) ...[
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.login,
                    "Entrée",
                    pointageVM.entreePointage?.heure ?? '-',
                  ),
                ],
                if (pointageVM.hasSortie) ...[
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.logout,
                    "Sortie",
                    pointageVM.sortiePointage?.heure ?? '-',
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCardHeader(Icons.history, "Historique des 30 derniers jours"),
        const SizedBox(height: 16),
        if (_isLoadingHistory)
          Container(
            decoration: _cardDecoration(),
            padding: const EdgeInsets.all(40),
            child: const Center(child: CircularProgressIndicator()),
          )
        else if (_historyData.isEmpty)
          Container(
            decoration: _cardDecoration(),
            padding: const EdgeInsets.all(40),
            child: const Center(
              child: Column(
                children: [
                  Icon(Icons.history, size: 48, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Aucun historique disponible',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            ),
          )
        else
          Container(
            decoration: _cardDecoration(),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _historyData.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final entry = _historyData[index];
                final type = entry['type'] as String;
                final date = DateTime.parse(entry['date']);
                final heure = entry['heure'] as String;
                final etat = entry['etat'] as String?;

                return ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: type == 'ENTREE'
                          ? Colors.green.withOpacity(0.1)
                          : Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      type == 'ENTREE' ? Icons.login : Icons.logout,
                      color: type == 'ENTREE' ? Colors.green : Colors.blue,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    "${DateFormat('dd/MM/yyyy').format(date)} - $heure",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF005B96),
                    ),
                  ),
                  subtitle: Text(
                    "${type == 'ENTREE' ? 'Entrée' : 'Sortie'}${etat != null ? ' - $etat' : ''}",
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  trailing: etat == 'Absent'
                      ? const Icon(Icons.warning, color: Colors.orange, size: 20)
                      : etat == 'Present'
                      ? const Icon(Icons.check_circle, color: Colors.green, size: 20)
                      : null,
                );
              },
            ),
          ),
      ],
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

  Widget _buildCardHeader(IconData icon, String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF005B96).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF005B96), size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF005B96),
            ),
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
}