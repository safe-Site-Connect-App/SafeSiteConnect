import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../ViewsModels/tache_viewmodel.dart';
import '../../../ViewsModels/auth_viewmodel.dart';
import '../../../models/tache_model.dart';
import '../../../utils/constants.dart';
import '../../../navigation/CustomBottomNavigationBar.dart';

class TaskScreen extends StatefulWidget {
  const TaskScreen({super.key});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  int _currentIndex = 2;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  Future<void> _initializeData() async {
    if (_isInitialized) return;

    final authViewModel = context.read<AuthViewModel>();
    final tacheViewModel = context.read<TacheViewModel>();

    // ✅ Vérifier et charger l'utilisateur si nécessaire
    if (authViewModel.currentUser == null) {
      print('⚠️ [TASK] Utilisateur non chargé, tentative de chargement...');
      await authViewModel.loadUserFromStorage();
    }

    // Vérifier l'authentification
    if (!authViewModel.isAuthenticated) {
      print('❌ [TASK] Utilisateur non authentifié');
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      }
      return;
    }

    final userId = authViewModel.currentUser?.id;

    if (userId == null || userId.isEmpty) {
      print('❌ [TASK] UserId invalide: $userId');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur: ID utilisateur invalide. Veuillez vous reconnecter.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
      return;
    }

    print('✅ [TASK] UserId valide: $userId');

    // Charger les tâches de l'utilisateur
    await _loadUserTasks(userId, tacheViewModel);
    _isInitialized = true;
  }

  Future<void> _loadUserTasks(String userId, TacheViewModel tacheViewModel) async {
    try {
      print('🔄 [TASK] Chargement des tâches pour userId: $userId');
      await tacheViewModel.loadUserTaches(userId);

      if (mounted && tacheViewModel.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${tacheViewModel.errorMessage}'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        print('✅ [TASK] ${tacheViewModel.allTaches.length} tâches chargées');
      }
    } catch (e) {
      print('❌ [TASK] Erreur chargement: $e');
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

  Future<void> _refreshTasks() async {
    final authViewModel = context.read<AuthViewModel>();
    final tacheViewModel = context.read<TacheViewModel>();
    final userId = authViewModel.currentUser?.id;

    if (userId != null && userId.isNotEmpty) {
      await _loadUserTasks(userId, tacheViewModel);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur: Utilisateur non identifié'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<TacheViewModel, AuthViewModel>(
      builder: (context, tacheViewModel, authViewModel, child) {
        return Scaffold(
          backgroundColor: const Color(AppColors.backgroundColor),
          appBar: _buildAppBar(authViewModel),
          body: _buildBody(tacheViewModel, authViewModel),
          bottomNavigationBar: CustomBottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
          ),
        );
      },
    );
  }

  AppBar _buildAppBar(AuthViewModel authViewModel) {
    return AppBar(
      backgroundColor: const Color(AppColors.primaryColor),
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            AppTextStyles.appBarTitle,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            authViewModel.currentUser?.nom ?? 'Utilisateur',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
      automaticallyImplyLeading: false,
      actions: [
        // 🐛 Bouton DEBUG
        IconButton(
          icon: const Icon(Icons.bug_report, color: Colors.yellow, size: 24),
          onPressed: _debugStorage,
          tooltip: 'Debug',
        ),
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white, size: 24),
          onPressed: _refreshTasks,
          tooltip: 'Actualiser',
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  /// 🐛 Méthode de debug pour afficher le contenu du storage
  Future<void> _debugStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authViewModel = context.read<AuthViewModel>();

      print('========================================');
      print('🐛 [DEBUG] TASK SCREEN STORAGE');
      print('========================================');
      print('📦 SharedPreferences Keys: ${prefs.getKeys()}');
      print('   - access_token: ${prefs.getString('access_token')?.substring(0, 20)}...');
      print('   - user_id: ${prefs.getString('user_id')}');
      print('   - user_name: ${prefs.getString('user_name')}');
      print('   - user_email: ${prefs.getString('user_email')}');
      print('   - user_role: ${prefs.getString('user_role')}');
      print('   - is_logged_in: ${prefs.getBool('is_logged_in')}');
      print('========================================');
      print('📦 AuthViewModel State:');
      print('   - currentUser: ${authViewModel.currentUser}');
      print('   - currentUser?.id: ${authViewModel.currentUser?.id}');
      print('   - isAuthenticated: ${authViewModel.isAuthenticated}');
      print('========================================');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Debug info in console\nUserId: ${authViewModel.currentUser?.id ?? "NULL"}'),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('❌ [DEBUG] Error: $e');
    }
  }

  Widget _buildBody(TacheViewModel tacheViewModel, AuthViewModel authViewModel) {
    // État de chargement initial
    if (tacheViewModel.isLoading && tacheViewModel.allTaches.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF7ED957)),
            SizedBox(height: 16),
            Text(
              'Chargement de vos tâches...',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // État d'erreur
    if (tacheViewModel.errorMessage != null && tacheViewModel.allTaches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                tacheViewModel.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _refreshTasks,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(AppColors.primaryColor),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    // Contenu principal avec RefreshIndicator
    return RefreshIndicator(
      onRefresh: _refreshTasks,
      color: const Color(0xFF7ED957),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            _buildHeaderGradient(),
            Padding(
              padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatsCard(tacheViewModel),
                  const SizedBox(height: 24),
                  _buildTodayTasksSection(tacheViewModel),
                  const SizedBox(height: 32),
                  _buildFutureTasksSection(tacheViewModel),
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
          colors: [Color(AppColors.primaryColor), Color(AppColors.backgroundColor)],
        ),
      ),
    );
  }

  Widget _buildStatsCard(TacheViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            'Total',
            viewModel.totalTaches.toString(),
            Icons.task_alt,
            const Color(AppColors.primaryColor),
          ),
          _buildStatItem(
            'Nouvelles',
            viewModel.tachesNew.toString(),
            Icons.fiber_new,
            const Color(AppColors.statusNew),
          ),
          _buildStatItem(
            'En cours',
            viewModel.tachesInProgress.toString(),
            Icons.pending,
            const Color(AppColors.statusInProgress),
          ),
          _buildStatItem(
            'Terminées',
            viewModel.tachesCompleted.toString(),
            Icons.check_circle,
            const Color(AppColors.statusCompleted),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(AppColors.cardBackground), Color(AppColors.backgroundColor)],
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

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case TachePriorite.p1:
        return const Color(AppColors.priorityP1);
      case TachePriorite.p2:
        return const Color(AppColors.priorityP2);
      case TachePriorite.p3:
        return const Color(AppColors.priorityP3);
      default:
        return Colors.grey;
    }
  }

  IconData _getPriorityIcon(String priority) {
    switch (priority) {
      case TachePriorite.p1:
        return Icons.warning;
      case TachePriorite.p2:
        return Icons.error_outline;
      case TachePriorite.p3:
        return Icons.info_outline;
      default:
        return Icons.task;
    }
  }

  Widget _buildTodayTasksSection(TacheViewModel viewModel) {
    final today = DateTime.now();
    final todayTasks = viewModel.allTaches.where((task) {
      if (task.statut == TacheStatut.termine) return false;
      if (task.createdAt == null) return true;
      final createdDate = task.createdAt!;
      return createdDate.year == today.year &&
          createdDate.month == today.month &&
          createdDate.day == today.day;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildCardHeader(Icons.priority_high, "Tâches du jour"),
            Text(
              "${today.day.toString().padLeft(2, '0')}/${today.month.toString().padLeft(2, '0')}/${today.year}",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        todayTasks.isEmpty
            ? _buildEmptyState(AppTextStyles.emptyStateTitle)
            : ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: todayTasks.length,
          itemBuilder: (context, index) => _buildTaskCard(todayTasks[index], viewModel),
        ),
      ],
    );
  }

  Widget _buildFutureTasksSection(TacheViewModel viewModel) {
    final today = DateTime.now();
    final futureTasks = viewModel.allTaches.where((task) {
      if (task.statut == TacheStatut.termine) return false;
      if (task.createdAt == null) return false;
      return task.createdAt!.isAfter(DateTime(today.year, today.month, today.day));
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCardHeader(Icons.calendar_month, "À venir"),
        const SizedBox(height: 16),
        futureTasks.isEmpty
            ? _buildEmptyState('Aucune tâche à venir')
            : SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: futureTasks.length,
            itemBuilder: (context, index) => _buildFutureTaskCard(futureTasks[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildTaskCard(TacheModel task, TacheViewModel viewModel) {
    final priorityColor = _getPriorityColor(task.priorite);
    final isCompleted = task.statut == TacheStatut.termine;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            task.priorite == TachePriorite.p1 ? Colors.red.shade50 : Colors.white,
            task.priorite == TachePriorite.p1
                ? Colors.red.shade100.withOpacity(0.3)
                : const Color(AppColors.backgroundColor),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: task.priorite == TachePriorite.p1
              ? Colors.red.withOpacity(0.3)
              : Colors.transparent,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: task.priorite == TachePriorite.p1
                ? Colors.red.withOpacity(0.1)
                : Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
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
                    color: priorityColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getPriorityIcon(task.priorite),
                    color: priorityColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    task.titre,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(AppColors.primaryColor),
                      decoration: isCompleted
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                  ),
                ),
                // Menu déroulant pour changer le statut
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert,
                    color: Color(AppColors.primaryColor),
                    size: 24,
                  ),
                  onSelected: (value) {
                    if (value == 'new') {
                      _changeTaskStatus(task.id!, TacheStatut.nouveau, viewModel);
                    } else if (value == 'progress') {
                      _changeTaskStatus(task.id!, TacheStatut.enCours, viewModel);
                    } else if (value == 'completed') {
                      _changeTaskStatus(task.id!, TacheStatut.termine, viewModel);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'new',
                      child: Row(
                        children: [
                          Icon(
                            Icons.fiber_new,
                            size: 18,
                            color: task.statut == TacheStatut.nouveau
                                ? const Color(AppColors.statusNew)
                                : Colors.grey,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Nouvelle',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: task.statut == TacheStatut.nouveau
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'progress',
                      child: Row(
                        children: [
                          Icon(
                            Icons.pending,
                            size: 18,
                            color: task.statut == TacheStatut.enCours
                                ? const Color(AppColors.statusInProgress)
                                : Colors.grey,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'En cours',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: task.statut == TacheStatut.enCours
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'completed',
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 18,
                            color: task.statut == TacheStatut.termine
                                ? const Color(AppColors.statusCompleted)
                                : Colors.grey,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Terminée',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: task.statut == TacheStatut.termine
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (task.createdAt != null)
              _buildInfoRow(
                Icons.access_time,
                "Date",
                "${task.createdAt!.day}/${task.createdAt!.month}/${task.createdAt!.year}",
              ),
            if (task.zone != null && task.zone!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildInfoRow(Icons.place, "Lieu", task.zone!),
            ],
            const SizedBox(height: 8),
            _buildInfoRow(
              task.statut == TacheStatut.nouveau
                  ? Icons.fiber_new
                  : task.statut == TacheStatut.enCours
                  ? Icons.pending
                  : Icons.check_circle,
              "Statut",
              TacheStatut.getLabel(task.statut),
            ),
            if (task.description != null && task.description!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                task.description!,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _changeTaskStatus(
      String tacheId,
      String newStatut,
      TacheViewModel viewModel,
      ) async {
    final success = await viewModel.changeStatus(
      tacheId: tacheId,
      newStatut: newStatut,
    );

    if (success && mounted) {
      Color snackBarColor;
      IconData snackBarIcon;

      switch (newStatut) {
        case TacheStatut.nouveau:
          snackBarColor = const Color(AppColors.statusNew);
          snackBarIcon = Icons.fiber_new;
          break;
        case TacheStatut.enCours:
          snackBarColor = const Color(AppColors.statusInProgress);
          snackBarIcon = Icons.pending;
          break;
        case TacheStatut.termine:
          snackBarColor = const Color(AppColors.statusCompleted);
          snackBarIcon = Icons.check_circle;
          break;
        default:
          snackBarColor = Colors.grey;
          snackBarIcon = Icons.info;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(snackBarIcon, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Statut changé: ${TacheStatut.getLabel(newStatut)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: snackBarColor,
          duration: const Duration(seconds: 2),
        ),
      );
    } else if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${viewModel.errorMessage}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildFutureTaskCard(TacheModel task) {
    final priorityColor = _getPriorityColor(task.priorite);

    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: 16),
      decoration: _cardDecoration(),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: priorityColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getPriorityIcon(task.priorite),
                    color: priorityColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    task.titre,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(AppColors.primaryColor),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (task.createdAt != null)
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    "${task.createdAt!.day}/${task.createdAt!.month}/${task.createdAt!.year}",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: priorityColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    task.priorite,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: priorityColor,
                    ),
                  ),
                ),
                Icon(
                  task.statut == TacheStatut.nouveau
                      ? Icons.fiber_new
                      : task.statut == TacheStatut.enCours
                      ? Icons.pending
                      : Icons.check_circle,
                  size: 18,
                  color: task.statut == TacheStatut.nouveau
                      ? const Color(AppColors.statusNew)
                      : task.statut == TacheStatut.enCours
                      ? const Color(AppColors.statusInProgress)
                      : const Color(AppColors.statusCompleted),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.task_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardHeader(IconData icon, String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(AppColors.primaryColor).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(AppColors.primaryColor), size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(AppColors.primaryColor),
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
        Flexible(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Color(AppColors.primaryColor),
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

