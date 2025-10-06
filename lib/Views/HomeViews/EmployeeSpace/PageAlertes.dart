import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../ViewsModels/alerte_viewmodel.dart';
import '../../../navigation/CustomBottomNavigationBar.dart';
import '../../../models/alerte_model.dart';
import '../../../utils/constants.dart';

class PageAlertes extends StatefulWidget {
  const PageAlertes({super.key});

  @override
  State<PageAlertes> createState() => _PageAlertesState();
}

class _PageAlertesState extends State<PageAlertes> {
  int _currentIndex = 3;

  @override
  void initState() {
    super.initState();
    // Load alertes when page initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AlerteViewModel>().initialize();
    });
  }

  void _showAddAlertDialog() {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    String priority = 'Mineure';
    String location = '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Icon(Icons.add_alert, color: const Color(0xFF005B96)),
                  const SizedBox(width: 8),
                  Text('Ajouter une alerte'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'Titre',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: priority,
                      decoration: InputDecoration(
                        labelText: 'Priorité',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: ['Critique', 'Modérée', 'Mineure']
                          .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                          .toList(),
                      onChanged: (value) => setDialogState(() => priority = value!),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      onChanged: (value) => location = value,
                      decoration: InputDecoration(
                        labelText: 'Lieu',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (titleController.text.isNotEmpty && descriptionController.text.isNotEmpty) {
                      final viewModel = context.read<AlerteViewModel>();
                      final success = await viewModel.createAlerte(
                        titre: titleController.text,
                        description: descriptionController.text,
                        priorite: priority,
                        lieu: location.isNotEmpty ? location : null,
                      );

                      Navigator.of(context).pop();

                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(ApiConstants.alerteCreatedSuccess),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(viewModel.error ?? 'Erreur lors de la création'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF005B96),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Ajouter', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditAlertDialog(AlerteModel alert) {
    final TextEditingController titleController = TextEditingController(text: alert.titre);
    final TextEditingController descriptionController = TextEditingController(text: alert.description);
    String priority = alert.priorite;
    String location = alert.lieu ?? '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Icon(Icons.edit, color: const Color(0xFF005B96)),
                  const SizedBox(width: 8),
                  Text('Modifier l\'alerte'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'Titre',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: priority,
                      decoration: InputDecoration(
                        labelText: 'Priorité',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: ['Critique', 'Modérée', 'Mineure']
                          .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                          .toList(),
                      onChanged: (value) => setDialogState(() => priority = value!),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      onChanged: (value) => location = value,
                      decoration: InputDecoration(
                        labelText: 'Lieu',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      controller: TextEditingController(text: location),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Annuler'),
                ),
                if (!alert.isResolved)
                  ElevatedButton(
                    onPressed: () async {
                      final viewModel = context.read<AlerteViewModel>();
                      final success = await viewModel.markAsResolved(alert.id!);

                      Navigator.of(context).pop();

                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(ApiConstants.alerteResolvedSuccess),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Marquer comme résolue', style: TextStyle(color: Colors.white)),
                  ),
                ElevatedButton(
                  onPressed: () async {
                    if (titleController.text.isNotEmpty && descriptionController.text.isNotEmpty) {
                      final viewModel = context.read<AlerteViewModel>();
                      final success = await viewModel.updateAlerte(
                        id: alert.id!,
                        titre: titleController.text,
                        description: descriptionController.text,
                        priorite: priority,
                        lieu: location.isNotEmpty ? location : null,
                        statut: alert.statut,
                      );

                      Navigator.of(context).pop();

                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(ApiConstants.alerteUpdatedSuccess),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF005B96),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Modifier', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AlerteViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          appBar: _buildAppBar(viewModel),
          body: _buildBody(viewModel),
          floatingActionButton: _buildFloatingActionButton(),
          bottomNavigationBar: CustomBottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
          ),
        );
      },
    );
  }

  AppBar _buildAppBar(AlerteViewModel viewModel) {
    return AppBar(
      backgroundColor: const Color(0xFF005B96),
      elevation: 0,
      title: Row(
        children: [
          const Text(
            "Mes Alertes",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (viewModel.unresolvedCount > 0)
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: CircleAvatar(
                radius: 10,
                backgroundColor: Colors.red,
                child: Text(
                  viewModel.unresolvedCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
      automaticallyImplyLeading: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: () => viewModel.refresh(),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.sort, color: Colors.white, size: 24),
          onSelected: (value) => viewModel.sortAlertes(value),
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'date', child: Text('Trier par date')),
            const PopupMenuItem(value: 'priority', child: Text('Trier par priorité')),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildBody(AlerteViewModel viewModel) {
    if (viewModel.isLoading && viewModel.alertes.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF005B96)),
      );
    }

    if (viewModel.hasError && viewModel.alertes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              viewModel.error ?? 'Une erreur est survenue',
              style: TextStyle(color: Colors.red[700]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => viewModel.refresh(),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => viewModel.refresh(),
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
                  _buildAlertsSection(viewModel),
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

  Widget _buildAlertsSection(AlerteViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCardHeader(Icons.warning, "Alertes"),
        const SizedBox(height: 16),
        viewModel.alertes.isEmpty
            ? Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              children: [
                Icon(Icons.notifications_none, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Aucune alerte',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
              ],
            ),
          ),
        )
            : ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: viewModel.alertes.length,
          itemBuilder: (context, index) => GestureDetector(
            onTap: () => _showEditAlertDialog(viewModel.alertes[index]),
            child: _buildAlertCard(viewModel.alertes[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildAlertCard(AlerteModel alert) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            alert.isCritical ? Colors.red.shade50 : Colors.white,
            alert.isCritical ? Colors.red.shade100.withOpacity(0.3) : const Color(0xFFF8F9FA),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: alert.isCritical ? Colors.red.withOpacity(0.3) : Colors.transparent,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: alert.isCritical ? Colors.red.withOpacity(0.1) : Colors.black.withOpacity(0.08),
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
                    color: alert.isCritical
                        ? Colors.red.withOpacity(0.1)
                        : alert.isModerate
                        ? Colors.orange.withOpacity(0.1)
                        : Colors.yellow.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    alert.isCritical
                        ? Icons.warning
                        : alert.isModerate
                        ? Icons.error_outline
                        : Icons.info_outline,
                    color: alert.isCritical
                        ? Colors.red
                        : alert.isModerate
                        ? Colors.orange
                        : Colors.yellow,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    alert.titre,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF005B96),
                      decoration: alert.isResolved ? TextDecoration.lineThrough : TextDecoration.none,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.access_time, "Date", alert.getFormattedDate()),
            const SizedBox(height: 8),
            if (alert.lieu != null && alert.lieu!.isNotEmpty)
              _buildInfoRow(Icons.place, "Lieu", alert.lieu!),
            const SizedBox(height: 12),
            Text(
              alert.description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[800],
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: alert.isCritical
                        ? Colors.red.withOpacity(0.1)
                        : alert.isModerate
                        ? Colors.orange.withOpacity(0.1)
                        : Colors.yellow.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    alert.priorite,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: alert.isCritical
                          ? Colors.red
                          : alert.isModerate
                          ? Colors.orange
                          : Colors.yellow,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: alert.isResolved
                        ? Colors.green.withOpacity(0.1)
                        : alert.isInProgress
                        ? Colors.blue.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    AlerteStatut.fromString(alert.statut).displayName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: alert.isResolved
                          ? Colors.green
                          : alert.isInProgress
                          ? Colors.blue
                          : Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return Container(
      decoration: _fabDecoration(),
      child: FloatingActionButton(
        onPressed: _showAddAlertDialog,
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(Icons.add_alert, color: Colors.white, size: 24),
      ),
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
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF005B96),
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