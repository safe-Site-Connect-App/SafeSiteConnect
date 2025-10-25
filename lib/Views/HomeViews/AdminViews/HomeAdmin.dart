import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../ViewsModels/alerte_viewmodel.dart';
import '../../../ViewsModels/pointage_viewmodel.dart';
import '../../../ViewsModels/tache_viewmodel.dart';
import '../../../ViewsModels/user_viewmodel.dart';
import '../../../models/alerte_model.dart';
import 'CustomBottomNavigationBarAdmin.dart';
import 'ProfilAdminPage.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with TickerProviderStateMixin {
  int _currentIndex = 0;
  final String _adminName = "Admin Principal";
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimation();
    _fetchData();
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

  void _fetchData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AlerteViewModel>().initialize();
      context.read<PointageViewModel>().fetchTodayPointage();
      context.read<TacheViewModel>().loadAllTaches();
      context.read<UserViewModel>().loadUsers();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(screenWidth),
      body: _buildBody(screenWidth),
      bottomNavigationBar: CustomBottomNavigationBarAdmin(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }

  AppBar _buildAppBar(double screenWidth) {
    return AppBar(
      backgroundColor: const Color(0xFF005B96),
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Tableau de bord",
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: screenWidth * 0.035,
              fontWeight: FontWeight.w400,
            ),
          ),
          Text(
            _adminName,
            style: TextStyle(
              color: Colors.white,
              fontSize: screenWidth * 0.045,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      automaticallyImplyLeading: false,
      actions: [
        GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const ProfilAdminPage()),
            );
          },
          child: Container(
            margin: EdgeInsets.only(right: screenWidth * 0.04),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: screenWidth * 0.04,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody(double screenWidth) {
    return Consumer4<AlerteViewModel, PointageViewModel, TacheViewModel, UserViewModel>(
      builder: (context, alerteVM, pointageVM, tacheVM, userVM, child) {
        if (alerteVM.isLoading || pointageVM.isLoading || tacheVM.isLoading || userVM.isLoading) {
          return Center(
            child: CircularProgressIndicator(
              color: const Color(0xFF005B96),
              strokeWidth: 3,
            ),
          );
        }

        if (alerteVM.hasError || pointageVM.errorMessage != null || tacheVM.errorMessage != null || userVM.errorMessage != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: screenWidth * 0.12, color: Colors.red[300]),
                SizedBox(height: screenWidth * 0.03),
                Text(
                  alerteVM.error ?? pointageVM.errorMessage ?? tacheVM.errorMessage ?? userVM.errorMessage ?? 'Une erreur est survenue',
                  style: TextStyle(color: Colors.red[700], fontSize: screenWidth * 0.035),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: screenWidth * 0.03),
                ElevatedButton(
                  onPressed: _fetchData,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenWidth * 0.02),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  child: Text('Réessayer', style: TextStyle(fontSize: screenWidth * 0.03)),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await Future.wait([
              alerteVM.refresh(),
              pointageVM.fetchTodayPointage(),
              tacheVM.loadAllTaches(),
              userVM.loadUsers(),
            ]);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                _buildHeaderGradient(screenWidth),
                Padding(
                  padding: EdgeInsets.all(screenWidth * 0.04),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatisticsSection(alerteVM, pointageVM, tacheVM, userVM, screenWidth),
                      SizedBox(height: screenWidth * 0.06),
                      _buildCriticalAlertsSection(alerteVM, screenWidth),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderGradient(double screenWidth) {
    return Container(
      height: screenWidth * 0.12,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF005B96), Color(0xFFF8F9FA)],
        ),
      ),
    );
  }

  Widget _buildStatisticsSection(
      AlerteViewModel alerteVM,
      PointageViewModel pointageVM,
      TacheViewModel tacheVM,
      UserViewModel userVM,
      double screenWidth,
      ) {
    // Calculate the number of users who have clocked in today
    final usersPointedToday = pointageVM.weekPointages.length;
    final totalUsers = userVM.users.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCardHeader(Icons.analytics_outlined, "Statistiques globales", screenWidth: screenWidth),
        SizedBox(height: screenWidth * 0.03),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: screenWidth * 0.04,
          mainAxisSpacing: screenWidth * 0.04,
          childAspectRatio: 0.9,
          children: [
            _buildStatCard(
              "Incidents",
              "${alerteVM.totalCount}",
              "${alerteVM.criticalCount} critiques",
              Icons.report_problem,
              Colors.red,
              screenWidth,
            ),
            _buildStatCard(
              "Pointages",
              "$usersPointedToday / $totalUsers",
              "Employés présents",
              Icons.access_time,
              Colors.blue,
              screenWidth,
            ),
            _buildStatCard(
              "Tâches",
              "${tacheVM.totalTaches}",
              "${tacheVM.tachesP1} P1",
              Icons.assignment,
              Colors.green,
              screenWidth,
            ),
            _buildStatCard(
              "Employés",
              "$totalUsers",
              "actifs",
              Icons.people,
              Colors.purple,
              screenWidth,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCriticalAlertsSection(AlerteViewModel alerteVM, double screenWidth) {
    final criticalAlerts = alerteVM.alertes.where((alert) => alert.isCritical).toList();

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            decoration: _alertDecoration(),
            child: Padding(
              padding: EdgeInsets.all(screenWidth * 0.04),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCardHeader(
                    Icons.warning,
                    "Alertes critiques (${criticalAlerts.length})",
                    color: Colors.red,
                    screenWidth: screenWidth,
                  ),
                  SizedBox(height: screenWidth * 0.03),
                  criticalAlerts.isEmpty
                      ? Center(
                    child: Padding(
                      padding: EdgeInsets.all(screenWidth * 0.06),
                      child: Column(
                        children: [
                          Icon(Icons.check_circle, size: screenWidth * 0.12, color: Colors.grey[400]),
                          SizedBox(height: screenWidth * 0.03),
                          Text(
                            'Aucune alerte critique',
                            style: TextStyle(color: Colors.grey[600], fontSize: screenWidth * 0.035),
                          ),
                        ],
                      ),
                    ),
                  )
                      : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: criticalAlerts.length > 5 ? 5 : criticalAlerts.length,
                    separatorBuilder: (context, index) => SizedBox(height: screenWidth * 0.03),
                    itemBuilder: (context, index) {
                      return _buildNotificationItem(criticalAlerts[index], screenWidth);
                    },
                  ),
                  SizedBox(height: screenWidth * 0.04),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Navigate to IncidentScreen
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: screenWidth * 0.03),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            elevation: 2,
                          ),
                          icon: Icon(Icons.visibility, size: screenWidth * 0.04),
                          label: Text(
                            "Voir toutes",
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: screenWidth * 0.03),
                          ),
                        ),
                      ),
                      if (criticalAlerts.isNotEmpty) ...[
                        SizedBox(width: screenWidth * 0.03),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              for (var alert in criticalAlerts) {
                                await alerteVM.markAsResolved(alert.id!);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7ED957),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: screenWidth * 0.03),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              elevation: 2,
                            ),
                            icon: Icon(Icons.check_circle, size: screenWidth * 0.04),
                            label: Text(
                              "Marquer vues",
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: screenWidth * 0.03),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, String subtitle, IconData icon, Color color, double screenWidth) {
    return Container(
      decoration: _cardDecoration(screenWidth),
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(screenWidth * 0.02),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: screenWidth * 0.05),
                ),
                const Spacer(),
              ],
            ),
            SizedBox(height: screenWidth * 0.03),
            Text(
              value,
              style: TextStyle(
                fontSize: screenWidth * 0.05,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF005B96),
              ),
            ),
            SizedBox(height: screenWidth * 0.01),
            Text(
              title,
              style: TextStyle(
                fontSize: screenWidth * 0.035,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF005B96),
              ),
            ),
            SizedBox(height: screenWidth * 0.01),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: screenWidth * 0.03,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(AlerteModel alert, double screenWidth) {
    return Container(
      padding: EdgeInsets.all(screenWidth * 0.03),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(screenWidth * 0.02),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(Icons.warning, color: Colors.red, size: screenWidth * 0.04),
          ),
          SizedBox(width: screenWidth * 0.03),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.titre,
                  style: TextStyle(
                    fontSize: screenWidth * 0.035,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                SizedBox(height: screenWidth * 0.01),
                Text(
                  alert.description,
                  style: TextStyle(
                    fontSize: screenWidth * 0.03,
                    color: Colors.grey[700],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            alert.getFormattedDate().split(' ')[1],
            style: TextStyle(
              fontSize: screenWidth * 0.03,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration(double screenWidth) {
    return BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.white, Color(0xFFF8F9FA)],
      ),
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 2),
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
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.red.withOpacity(0.3), width: 1.5),
      boxShadow: [
        BoxShadow(
          color: Colors.red.withOpacity(0.1),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  Widget _buildCardHeader(IconData icon, String title, {Color color = const Color(0xFF005B96), required double screenWidth}) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(screenWidth * 0.02),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: screenWidth * 0.05),
        ),
        SizedBox(width: screenWidth * 0.03),
        Text(
          title,
          style: TextStyle(
            fontSize: screenWidth * 0.04,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}