import 'package:flutter/material.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavigationBar({
    required this.currentIndex,
    required this.onTap,
    super.key,
  });

  void _navigateToPage(BuildContext context, int index) {
    // Liste des routes correspondant aux indices
    const List<String> routes = [
      '/home', // Accueil
      '/pointage', // Pointage
      '/tasks', // Tâches (à implémenter)
      '/alert', // Alerte (à implémenter)
      '/profile', // Profil (à implémenter)
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
            icon: Icon(Icons.home_rounded, size: 28),
            activeIcon: Icon(Icons.home_rounded, size: 28),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.timer_outlined, size: 28),
            activeIcon: Icon(Icons.timer, size: 28),
            label: 'Pointage',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.task_outlined, size: 28),
            activeIcon: Icon(Icons.task, size: 28),
            label: 'Tâches',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_outlined, size: 28),
            activeIcon: Icon(Icons.notifications, size: 28),
            label: 'Alerte',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded, size: 28),
            activeIcon: Icon(Icons.person_rounded, size: 28),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}