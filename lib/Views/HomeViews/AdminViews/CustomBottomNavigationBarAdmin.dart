import 'package:flutter/material.dart';

class CustomBottomNavigationBarAdmin extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavigationBarAdmin({
    required this.currentIndex,
    required this.onTap,
    super.key,
  });

  void _navigateToPage(BuildContext context, int index) {
    // Liste des routes correspondant aux indices
    const List<String> routes = [
      '/dashboard', // Dashboard
      '/user_management', // Gestion des utilisateurs
      '/incident_management', // Gestion des incidents / alertes
      '/task_management', // Gestion des tâches
      '/attendance_tracking', // Pointage / Suivi des présences
    ];

    // Naviguer vers la page correspondante
    if (index != currentIndex) {
      Navigator.pushReplacementNamed(context, routes[index]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF16579D),
        unselectedItemColor: Colors.grey[600],
        backgroundColor: Colors.transparent,
        elevation: 0,
        currentIndex: currentIndex,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400),
        showUnselectedLabels: true,
        onTap: (index) {
          onTap(index); // Appeler le callback pour mettre à jour l'index
          _navigateToPage(context, index); // Naviguer vers la page
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined, size: 28),
            activeIcon: Icon(Icons.dashboard, size: 28),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group_outlined, size: 28),
            activeIcon: Icon(Icons.group, size: 28),
            label: 'Utilisateurs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.warning_outlined, size: 28),
            activeIcon: Icon(Icons.warning, size: 28),
            label: 'Incidents',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.task_outlined, size: 28),
            activeIcon: Icon(Icons.task, size: 28),
            label: 'Tâches',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.access_time_outlined, size: 28),
            activeIcon: Icon(Icons.access_time, size: 28),
            label: 'Pointage',
          ),
        ],
      ),
    );
  }
}