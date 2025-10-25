import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../ViewsModels/auth_viewmodel.dart';
import '../../../ViewsModels/tache_viewmodel.dart';
import '../../../ViewsModels/user_viewmodel.dart';
import '../../../models/tache_model.dart';
import '../../../utils/constants.dart';
import 'CustomBottomNavigationBarAdmin.dart';

class TacheEmployScreen extends StatefulWidget {
  const TacheEmployScreen({super.key});

  @override
  State<TacheEmployScreen> createState() => _TacheEmployScreenState();
}

class _TacheEmployScreenState extends State<TacheEmployScreen> {
  int _currentIndex = 3;
  final String _adminName = "Admin Principal";
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authViewModel = context.read<AuthViewModel>();
      if (!authViewModel.isAuthenticated) {
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      } else {
        _loadData();
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    final tacheViewModel = context.read<TacheViewModel>();
    final userViewModel = context.read<UserViewModel>();
    try {
      await Future.wait([
        tacheViewModel.loadAllTaches(),
        userViewModel.loadUsers(),
      ]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de chargement: ${e.toString()}')),
        );
      }
    }
  }

  void _onSearchChanged(String value, TacheViewModel viewModel) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      viewModel.setSearchQuery(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<TacheViewModel, UserViewModel>(
      builder: (context, tacheViewModel, userViewModel, child) {
        final pendingCount = tacheViewModel.tachesNew + tacheViewModel.tachesInProgress;

        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          appBar: _buildAppBar(pendingCount, tacheViewModel),
          body: _buildBody(tacheViewModel, userViewModel),
          floatingActionButton: _buildFloatingActionButton(tacheViewModel, userViewModel),
          bottomNavigationBar: CustomBottomNavigationBarAdmin(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
          ),
        );
      },
    );
  }

  AppBar _buildAppBar(int pendingCount, TacheViewModel viewModel) {
    return AppBar(
      backgroundColor: const Color(0xFF005B96),
      elevation: 0,
      title: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Gestion des tâches",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                _adminName,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          if (pendingCount > 0)
            Padding(
              padding: const EdgeInsets.only(left: 6.0),
              child: CircleAvatar(
                radius: 8,
                backgroundColor: Colors.red,
                child: Text(
                  pendingCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
      automaticallyImplyLeading: false,
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.sort, color: Colors.white, size: 20),
          onSelected: (value) => viewModel.setSortBy(value),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'date',
              child: Row(
                children: [
                  Icon(
                    viewModel.sortBy == 'date' ? Icons.check : Icons.calendar_today,
                    size: 16,
                    color: const Color(0xFF005B96),
                  ),
                  const SizedBox(width: 6),
                  const Text('Trier par date', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'priority',
              child: Row(
                children: [
                  Icon(
                    viewModel.sortBy == 'priority' ? Icons.check : Icons.priority_high,
                    size: 16,
                    color: const Color(0xFF005B96),
                  ),
                  const SizedBox(width: 6),
                  const Text('Trier par priorité', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.filter_list, color: Colors.white, size: 20),
          onPressed: () => _showFilterDialog(viewModel),
        ),
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
          onPressed: _loadData,
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildBody(TacheViewModel tacheViewModel, UserViewModel userViewModel) {
    if (tacheViewModel.isLoading && tacheViewModel.allTaches.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if ((tacheViewModel.errorMessage != null || userViewModel.errorMessage != null) &&
        tacheViewModel.allTaches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 36, color: Colors.red),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                tacheViewModel.errorMessage ?? userViewModel.errorMessage ?? 'Erreur inconnue',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh, size: 14),
              label: const Text('Réessayer', style: TextStyle(fontSize: 11)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF005B96),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            _buildHeaderGradient(),
            Padding(
              padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.03),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatsCards(tacheViewModel),
                  const SizedBox(height: 12),
                  _buildSearchSection(tacheViewModel),
                  const SizedBox(height: 12),
                  _buildTasksSection(tacheViewModel),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards(TacheViewModel viewModel) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildStatCard('Total', viewModel.totalTaches.toString(), Icons.task, const Color(0xFF005B96)),
          _buildStatCard('Nouvelles', viewModel.tachesNew.toString(), Icons.fiber_new, const Color(0xFFEF4444)),
          _buildStatCard('En cours', viewModel.tachesInProgress.toString(), Icons.pending, const Color(0xFFF59E0B)),
          _buildStatCard('Terminées', viewModel.tachesCompleted.toString(), Icons.check_circle, const Color(0xFF10B981)),
          _buildStatCard('P1', viewModel.tachesP1.toString(), Icons.warning, const Color(0xFFEF4444)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(8),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
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

  Widget _buildSearchSection(TacheViewModel viewModel) {
    return Container(
      decoration: _cardDecoration(),
      padding: const EdgeInsets.all(8),
      child: TextField(
        onChanged: (value) => _onSearchChanged(value, viewModel),
        decoration: InputDecoration(
          hintText: AppTextStyles.searchHint,
          hintStyle: TextStyle(color: Colors.grey[500], fontSize: 12),
          prefixIcon: Icon(Icons.search, color: Colors.grey[500], size: 16),
          suffixIcon: viewModel.hasActiveFilters
              ? IconButton(
            icon: const Icon(Icons.clear, size: 16, color: Colors.grey),
            onPressed: () => viewModel.clearFilters(),
            tooltip: 'Effacer les filtres',
          )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: const Color(0xFFF1F5F9),
          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        ),
        style: const TextStyle(fontSize: 12),
        autofillHints: null,
      ),
    );
  }

  Widget _buildTasksSection(TacheViewModel viewModel) {
    return Container(
      decoration: _cardDecoration(),
      padding: const EdgeInsets.all(12),
      height: MediaQuery.of(context).size.height * 0.7,
      child: viewModel.filteredTaches.isEmpty
          ? _buildEmptyState()
          : ListView.separated(
        itemCount: viewModel.filteredTaches.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return _buildTaskCard(viewModel.filteredTaches[index], viewModel);
        },
      ),
    );
  }

  Widget _buildTaskCard(TacheModel task, TacheViewModel viewModel) {
    Color priorityColor = _getPriorityColor(task.priorite);
    final isCompleted = task.statut == TacheStatut.termine;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            task.priorite == TachePriorite.p1 ? Colors.red.shade50 : Colors.white,
            task.priorite == TachePriorite.p1 ? Colors.red.shade100.withOpacity(0.3) : const Color(0xFFF8F9FA),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: task.priorite == TachePriorite.p1 ? Colors.red.withOpacity(0.3) : Colors.transparent,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: task.priorite == TachePriorite.p1 ? Colors.red.withOpacity(0.1) : Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: priorityColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    task.priorite == TachePriorite.p1
                        ? Icons.warning
                        : task.priorite == TachePriorite.p2
                        ? Icons.error_outline
                        : Icons.info_outline,
                    color: priorityColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.titre,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF005B96),
                          decoration: isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Color(0xFF005B96), size: 20),
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
                    const PopupMenuItem(
                      value: 'new',
                      child: Row(
                        children: [
                          Icon(Icons.fiber_new, size: 16, color: Color(0xFF005B96)),
                          SizedBox(width: 6),
                          Text('Nouvelle', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'progress',
                      child: Row(
                        children: [
                          Icon(Icons.pending, size: 16, color: Color(0xFF005B96)),
                          SizedBox(width: 6),
                          Text('En cours', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'completed',
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, size: 16, color: Color(0xFF005B96)),
                          SizedBox(width: 6),
                          Text('Terminée', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (task.createdAt != null)
              _buildInfoRow(
                Icons.access_time,
                "Date",
                "${task.createdAt!.day.toString().padLeft(2, '0')}/${task.createdAt!.month.toString().padLeft(2, '0')}/${task.createdAt!.year}",
              ),
            const SizedBox(height: 6),
            if (task.zone != null && task.zone!.isNotEmpty)
              _buildInfoRow(Icons.place, "Lieu", task.zone!),
            const SizedBox(height: 6),
            _buildInfoRow(Icons.info, "Statut", TacheStatut.getLabel(task.statut)),
            const SizedBox(height: 8),
            if (task.description != null && task.description!.isNotEmpty)
              Text(
                task.description!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[800],
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: priorityColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    task.priorite,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: priorityColor,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      task.assigneA?.nom ?? 'Non assigné',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showAssignDialog(task, viewModel),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF005B96),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    icon: const Icon(Icons.person, size: 14),
                    label: const Text("Assigner", style: TextStyle(fontSize: 11)),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _deleteTask(task.id!, viewModel),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    icon: const Icon(Icons.delete, size: 14),
                    label: const Text("Supprimer", style: TextStyle(fontSize: 11)),
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
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.search_off, size: 30, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            AppTextStyles.emptyStateTitle,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          Text(
            AppTextStyles.emptyStateSubtitle,
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton(TacheViewModel tacheViewModel, UserViewModel userViewModel) {
    return Container(
      decoration: _fabDecoration(),
      child: FloatingActionButton(
        onPressed: () => _showAddTaskDialog(tacheViewModel, userViewModel),
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(Icons.add_task, color: Colors.white, size: 20),
      ),
    );
  }

  void _showFilterDialog(TacheViewModel viewModel) {
    String? tempZone = viewModel.filterZone;
    String? tempPriorite = viewModel.filterPriorite;
    String? tempStatut = viewModel.filterStatut;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, Color(0xFFF8F9FA)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF005B96).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.filter_list, color: Color(0xFF005B96), size: 20),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          AppTextStyles.filterDialogTitle,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF005B96),
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: tempZone,
                      decoration: _buildInputDecoration('Zone', Icons.location_on_outlined),
                      items: [null, ...TacheZone.all]
                          .map((zone) => DropdownMenuItem(
                        value: zone,
                        child: Text(zone ?? 'Tous', style: const TextStyle(fontSize: 12)),
                      ))
                          .toList(),
                      onChanged: (value) => setDialogState(() => tempZone = value),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: tempPriorite,
                      decoration: _buildInputDecoration('Priorité', Icons.priority_high_outlined),
                      items: [null, ...TachePriorite.all]
                          .map((priorite) => DropdownMenuItem(
                        value: priorite,
                        child: Text(priorite ?? 'Tous', style: const TextStyle(fontSize: 12)),
                      ))
                          .toList(),
                      onChanged: (value) => setDialogState(() => tempPriorite = value),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: tempStatut,
                      decoration: _buildInputDecoration('Statut', Icons.info_outlined),
                      items: [null, ...TacheStatut.all]
                          .map((statut) => DropdownMenuItem(
                        value: statut,
                        child: Text(statut ?? 'Tous', style: const TextStyle(fontSize: 12)),
                      ))
                          .toList(),
                      onChanged: (value) => setDialogState(() => tempStatut = value),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF005B96),
                              side: const BorderSide(color: Color(0xFF005B96)),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                            child: const Text(
                              "Annuler",
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              viewModel.applyFilters(
                                zone: tempZone,
                                priorite: tempPriorite,
                                statut: tempStatut,
                              );
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF005B96),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                            child: const Text(
                              "Appliquer",
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAssignDialog(TacheModel task, TacheViewModel tacheViewModel) {
    final userViewModel = context.read<UserViewModel>();
    if (userViewModel.isLoading) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chargement des utilisateurs en cours...')),
      );
      return;
    }
    if (userViewModel.users.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(userViewModel.errorMessage ?? 'Aucun utilisateur disponible'),
        ),
      );
      return;
    }

    String? selectedUserId = task.assigneA?.id;
    String? selectedStatut = task.statut;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, Color(0xFFF8F9FA)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.person, color: Color(0xFF10B981), size: 20),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            AppTextStyles.assignDialogTitle,
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
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () {
                            FocusScope.of(context).requestFocus(FocusNode());
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedUserId,
                      decoration: _buildInputDecoration('Employé', Icons.person_outlined),
                      items: userViewModel.users
                          .map((user) => DropdownMenuItem(
                        value: user.id,
                        child: Text(user.nom, style: const TextStyle(fontSize: 12)),
                      ))
                          .toList(),
                      onChanged: (value) => setDialogState(() => selectedUserId = value),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedStatut,
                      decoration: _buildInputDecoration('Statut', Icons.info_outlined),
                      items: TacheStatut.all
                          .map((status) => DropdownMenuItem(
                        value: status,
                        child: Text(TacheStatut.getLabel(status), style: const TextStyle(fontSize: 12)),
                      ))
                          .toList(),
                      onChanged: (value) => setDialogState(() => selectedStatut = value),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              FocusScope.of(context).requestFocus(FocusNode());
                              Navigator.pop(context);
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF005B96),
                              side: const BorderSide(color: Color(0xFF005B96)),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                            child: const Text(
                              "Annuler",
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              if (selectedUserId != null) {
                                FocusScope.of(context).requestFocus(FocusNode());
                                Navigator.pop(context);
                                final success = await tacheViewModel.reassignTache(
                                  tacheId: task.id!,
                                  newUserId: selectedUserId!,
                                  newStatut: selectedStatut,
                                );
                                if (success && mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(ApiConstants.tacheAssignedSuccess),
                                    ),
                                  );
                                } else if (!success && mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Erreur: ${tacheViewModel.errorMessage}'),
                                    ),
                                  );
                                }
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Veuillez sélectionner un employé'),
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                            child: const Text(
                              "Assigner",
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAddTaskDialog(TacheViewModel tacheViewModel, UserViewModel userViewModel) {
    if (userViewModel.isLoading) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chargement des utilisateurs en cours...')),
      );
      return;
    }
    if (userViewModel.users.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(userViewModel.errorMessage ?? 'Aucun utilisateur disponible'),
        ),
      );
      return;
    }

    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String priorite = TachePriorite.p3;
    String? zone;
    String statut = TacheStatut.nouveau;
    String? assigneA = userViewModel.users.isNotEmpty ? userViewModel.users.first.id : null;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              title: Row(
                children: [
                  const Icon(Icons.add_task, color: Color(0xFF005B96), size: 20),
                  const SizedBox(width: 6),
                  const Text(AppTextStyles.addTaskDialogTitle, style: TextStyle(fontSize: 14)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'Titre *',
                        labelStyle: const TextStyle(fontSize: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      style: const TextStyle(fontSize: 12),
                      autofillHints: null,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        labelStyle: const TextStyle(fontSize: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      style: const TextStyle(fontSize: 12),
                      maxLines: 2,
                      autofillHints: null,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: priorite,
                      decoration: _buildInputDecoration('Priorité', Icons.priority_high_outlined),
                      items: TachePriorite.all
                          .map((p) => DropdownMenuItem(value: p, child: Text(TachePriorite.getLabel(p), style: const TextStyle(fontSize: 12))))
                          .toList(),
                      onChanged: (value) => setDialogState(() => priorite = value!),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      onChanged: (value) => zone = value,
                      decoration: InputDecoration(
                        labelText: 'Zone',
                        labelStyle: const TextStyle(fontSize: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      style: const TextStyle(fontSize: 12),
                      autofillHints: null,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: statut,
                      decoration: _buildInputDecoration('Statut', Icons.info_outlined),
                      items: TacheStatut.all
                          .map((s) => DropdownMenuItem(value: s, child: Text(TacheStatut.getLabel(s), style: const TextStyle(fontSize: 12))))
                          .toList(),
                      onChanged: (value) => setDialogState(() => statut = value!),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: assigneA,
                      decoration: _buildInputDecoration('Assignée à *', Icons.person_outlined),
                      items: userViewModel.users
                          .map((user) => DropdownMenuItem(
                        value: user.id,
                        child: Text(user.nom, style: const TextStyle(fontSize: 12)),
                      ))
                          .toList(),
                      onChanged: (value) => setDialogState(() => assigneA = value),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    FocusScope.of(context).requestFocus(FocusNode());
                    Navigator.pop(context);
                  },
                  child: const Text('Annuler', style: TextStyle(color: Color(0xFF005B96), fontSize: 11)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (titleController.text.isNotEmpty && assigneA != null) {
                      FocusScope.of(context).requestFocus(FocusNode());
                      Navigator.pop(context);
                      final success = await tacheViewModel.createTache(
                        titre: titleController.text,
                        description: descriptionController.text.isEmpty ? null : descriptionController.text,
                        priorite: priorite,
                        zone: zone,
                        statut: statut,
                        assigneA: assigneA!,
                      );
                      if (success && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(ApiConstants.tacheCreatedSuccess),
                          ),
                        );
                      } else if (!success && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Erreur: ${tacheViewModel.errorMessage}'),
                          ),
                        );
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Veuillez remplir les champs obligatoires'),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF005B96),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  child: const Text('Ajouter', style: TextStyle(color: Colors.white, fontSize: 11)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _changeTaskStatus(String tacheId, String newStatut, TacheViewModel viewModel) async {
    final success = await viewModel.changeStatus(
      tacheId: tacheId,
      newStatut: newStatut,
    );
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${ApiConstants.tacheStatusChangedSuccess}: ${TacheStatut.getLabel(newStatut)}')),
      );
    } else if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${viewModel.errorMessage}'),
        ),
      );
    }
  }

  Future<void> _deleteTask(String tacheId, TacheViewModel viewModel) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(AppTextStyles.deleteConfirmTitle, style: TextStyle(fontSize: 14)),
        content: const Text(AppTextStyles.deleteConfirmMessage, style: TextStyle(fontSize: 12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler', style: TextStyle(color: Color(0xFF005B96), fontSize: 11)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white, fontSize: 11)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await viewModel.deleteTache(tacheId);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(ApiConstants.tacheDeletedSuccess)),
        );
      } else if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${viewModel.errorMessage}'),
          ),
        );
      }
    }
  }

  BoxDecoration _fabDecoration() {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF005B96), Color(0xFF007BB8)],
      ),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF005B96).withOpacity(0.3),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
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
          color: Colors.black.withOpacity(0.06),
          blurRadius: 12,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case TachePriorite.p1:
        return const Color(0xFFEF4444);
      case TachePriorite.p2:
        return const Color(0xFFF59E0B);
      case TachePriorite.p3:
        return const Color(0xFF10B981);
      default:
        return Colors.grey;
    }
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey[600], fontSize: 12),
      prefixIcon: Icon(icon, size: 16, color: Colors.grey[600]),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide.none,
      ),
      filled: true,
      fillColor: const Color(0xFFF1F5F9),
      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Text(
          "$label: ",
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF005B96),
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}