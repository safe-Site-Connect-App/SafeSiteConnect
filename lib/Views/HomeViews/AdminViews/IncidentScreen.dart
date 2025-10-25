import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../ViewsModels/alerte_viewmodel.dart';
import '../../../models/alerte_model.dart';
import '../../../utils/constants.dart';
import 'CustomBottomNavigationBarAdmin.dart';

class IncidentScreen extends StatefulWidget {
  const IncidentScreen({super.key});

  @override
  State<IncidentScreen> createState() => _IncidentScreenState();
}

class _IncidentScreenState extends State<IncidentScreen> {
  int _currentIndex = 2;
  final String _adminName = "Admin Principal";

  @override
  void initState() {
    super.initState();
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              title: Row(
                children: [
                  Icon(Icons.add_alert, color: const Color(0xFF005B96), size: 20),
                  const SizedBox(width: 6),
                  Text('Ajouter une alerte', style: TextStyle(fontSize: 16)),
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
                        labelStyle: TextStyle(fontSize: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      style: TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        labelStyle: TextStyle(fontSize: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      maxLines: 3,
                      style: TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: priority,
                      decoration: InputDecoration(
                        labelText: 'Priorité',
                        labelStyle: TextStyle(fontSize: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      items: ['Critique', 'Modérée', 'Mineure']
                          .map((p) => DropdownMenuItem(value: p, child: Text(p, style: TextStyle(fontSize: 12))))
                          .toList(),
                      onChanged: (value) => setDialogState(() => priority = value!),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      onChanged: (value) => location = value,
                      decoration: InputDecoration(
                        labelText: 'Lieu',
                        labelStyle: TextStyle(fontSize: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Annuler', style: TextStyle(fontSize: 12)),
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
                            content: Text(ApiConstants.alerteCreatedSuccess, style: TextStyle(fontSize: 12)),
                            backgroundColor: Colors.green,
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(viewModel.error ?? 'Erreur lors de la création', style: TextStyle(fontSize: 12)),
                            backgroundColor: Colors.red,
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF005B96),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  child: Text('Ajouter', style: TextStyle(fontSize: 12, color: Colors.white)),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              title: Row(
                children: [
                  Icon(Icons.edit, color: const Color(0xFF005B96), size: 20),
                  const SizedBox(width: 6),
                  Text('Modifier l\'alerte', style: TextStyle(fontSize: 16)),
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
                        labelStyle: TextStyle(fontSize: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      style: TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        labelStyle: TextStyle(fontSize: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      maxLines: 3,
                      style: TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: priority,
                      decoration: InputDecoration(
                        labelText: 'Priorité',
                        labelStyle: TextStyle(fontSize: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      items: ['Critique', 'Modérée', 'Mineure']
                          .map((p) => DropdownMenuItem(value: p, child: Text(p, style: TextStyle(fontSize: 12))))
                          .toList(),
                      onChanged: (value) => setDialogState(() => priority = value!),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      onChanged: (value) => location = value,
                      decoration: InputDecoration(
                        labelText: 'Lieu',
                        labelStyle: TextStyle(fontSize: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      controller: TextEditingController(text: location),
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Annuler', style: TextStyle(fontSize: 12)),
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
                            content: Text(ApiConstants.alerteResolvedSuccess, style: TextStyle(fontSize: 12)),
                            backgroundColor: Colors.green,
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    child: Text('Marquer comme résolue', style: TextStyle(fontSize: 12, color: Colors.white)),
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
                            content: Text(ApiConstants.alerteUpdatedSuccess, style: TextStyle(fontSize: 12)),
                            backgroundColor: Colors.green,
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF005B96),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  child: Text('Modifier', style: TextStyle(fontSize: 12, color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmation(AlerteModel alert, double screenWidth) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.red, size: 20),
              const SizedBox(width: 6),
              Text('Confirmer la suppression', style: TextStyle(fontSize: 16)),
            ],
          ),
          content: Text(
            'Êtes-vous sûr de vouloir supprimer l\'alerte "${alert.titre}" ?',
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Annuler', style: TextStyle(fontSize: 12)),
            ),
            ElevatedButton(
              onPressed: () async {
                final viewModel = context.read<AlerteViewModel>();
                final success = await viewModel.deleteAlerte(alert.id!);

                Navigator.of(context).pop();

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Alerte supprimée avec succès', style: TextStyle(fontSize: 12)),
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(viewModel.error ?? 'Erreur lors de la suppression', style: TextStyle(fontSize: 12)),
                      backgroundColor: Colors.red,
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              child: Text('Supprimer', style: TextStyle(fontSize: 12, color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Consumer<AlerteViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          appBar: _buildAppBar(viewModel, screenWidth),
          body: _buildBody(viewModel, screenWidth),
          floatingActionButton: _buildFloatingActionButton(screenWidth),
          bottomNavigationBar: CustomBottomNavigationBarAdmin(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
          ),
        );
      },
    );
  }

  AppBar _buildAppBar(AlerteViewModel viewModel, double screenWidth) {
    return AppBar(
      backgroundColor: const Color(0xFF005B96),
      elevation: 0,
      title: Row(
        children: [
          Text(
            "Incidents",
            style: TextStyle(
              color: Colors.white,
              fontSize: screenWidth * 0.04,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (viewModel.unresolvedCount > 0)
            Padding(
              padding: EdgeInsets.only(left: screenWidth * 0.02),
              child: CircleAvatar(
                radius: screenWidth * 0.025,
                backgroundColor: Colors.red,
                child: Text(
                  viewModel.unresolvedCount.toString(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: screenWidth * 0.02,
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
          icon: Icon(Icons.refresh, color: Colors.white, size: screenWidth * 0.05),
          onPressed: () => viewModel.refresh(),
        ),
        PopupMenuButton<String>(
          icon: Icon(Icons.sort, color: Colors.white, size: screenWidth * 0.05),
          onSelected: (value) => viewModel.sortAlertes(value),
          itemBuilder: (context) => [
            PopupMenuItem(value: 'date', child: Text('Trier par date', style: TextStyle(fontSize: screenWidth * 0.035))),
            PopupMenuItem(value: 'priority', child: Text('Trier par priorité', style: TextStyle(fontSize: screenWidth * 0.035))),
          ],
        ),
        SizedBox(width: screenWidth * 0.02),
      ],
    );
  }

  Widget _buildBody(AlerteViewModel viewModel, double screenWidth) {
    if (viewModel.isLoading && viewModel.alertes.isEmpty) {
      return Center(
        child: CircularProgressIndicator(color: Color(0xFF005B96), strokeWidth: 3),
      );
    }

    if (viewModel.hasError && viewModel.alertes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: screenWidth * 0.12, color: Colors.red[300]),
            SizedBox(height: screenWidth * 0.03),
            Text(
              viewModel.error ?? 'Une erreur est survenue',
              style: TextStyle(color: Colors.red[700], fontSize: screenWidth * 0.035),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: screenWidth * 0.03),
            ElevatedButton(
              onPressed: () => viewModel.refresh(),
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
      onRefresh: () => viewModel.refresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            _buildHeaderGradient(screenWidth),
            Padding(
              padding: EdgeInsets.all(screenWidth * 0.03),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAlertsSection(viewModel, screenWidth),
                ],
              ),
            ),
          ],
        ),
      ),
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

  Widget _buildAlertsSection(AlerteViewModel viewModel, double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCardHeader(Icons.warning, "Incidents", screenWidth),
        SizedBox(height: screenWidth * 0.03),
        viewModel.alertes.isEmpty
            ? Center(
          child: Padding(
            padding: EdgeInsets.all(screenWidth * 0.06),
            child: Column(
              children: [
                Icon(Icons.notifications_none, size: screenWidth * 0.12, color: Colors.grey[400]),
                SizedBox(height: screenWidth * 0.03),
                Text(
                  'Aucun incident',
                  style: TextStyle(color: Colors.grey[600], fontSize: screenWidth * 0.035),
                ),
              ],
            ),
          ),
        )
            : ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: viewModel.alertes.length,
          itemBuilder: (context, index) => _buildAlertCard(viewModel.alertes[index], screenWidth),
        ),
      ],
    );
  }

  Widget _buildAlertCard(AlerteModel alert, double screenWidth) {
    return Container(
      margin: EdgeInsets.only(bottom: screenWidth * 0.03),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            alert.isCritical ? Colors.red.shade50 : Colors.white,
            alert.isCritical ? Colors.red.shade100.withOpacity(0.3) : const Color(0xFFF8F9FA),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: alert.isCritical ? Colors.red.withOpacity(0.3) : Colors.transparent,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: alert.isCritical ? Colors.red.withOpacity(0.1) : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.03),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(screenWidth * 0.015),
                  decoration: BoxDecoration(
                    color: alert.isCritical
                        ? Colors.red.withOpacity(0.1)
                        : alert.isModerate
                        ? Colors.orange.withOpacity(0.1)
                        : Colors.yellow.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
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
                    size: screenWidth * 0.05,
                  ),
                ),
                SizedBox(width: screenWidth * 0.02),
                Expanded(
                  child: Text(
                    alert.titre,
                    style: TextStyle(
                      fontSize: screenWidth * 0.035,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF005B96),
                      decoration: alert.isResolved ? TextDecoration.lineThrough : TextDecoration.none,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: screenWidth * 0.02),
            _buildInfoRow(Icons.access_time, "Date", alert.getFormattedDate(), screenWidth),
            SizedBox(height: screenWidth * 0.015),
            if (alert.lieu != null && alert.lieu!.isNotEmpty)
              _buildInfoRow(Icons.place, "Lieu", alert.lieu!, screenWidth),
            SizedBox(height: screenWidth * 0.02),
            Text(
              alert.description,
              style: TextStyle(
                fontSize: screenWidth * 0.03,
                color: Colors.grey[800],
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: screenWidth * 0.03),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02, vertical: screenWidth * 0.01),
                      decoration: BoxDecoration(
                        color: alert.isCritical
                            ? Colors.red.withOpacity(0.1)
                            : alert.isModerate
                            ? Colors.orange.withOpacity(0.1)
                            : Colors.yellow.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        alert.priorite,
                        style: TextStyle(
                          fontSize: screenWidth * 0.03,
                          fontWeight: FontWeight.w600,
                          color: alert.isCritical
                              ? Colors.red
                              : alert.isModerate
                              ? Colors.orange
                              : Colors.yellow,
                        ),
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.02),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02, vertical: screenWidth * 0.01),
                      decoration: BoxDecoration(
                        color: alert.isResolved
                            ? Colors.green.withOpacity(0.1)
                            : alert.isInProgress
                            ? Colors.blue.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        AlerteStatut.fromString(alert.statut).displayName,
                        style: TextStyle(
                          fontSize: screenWidth * 0.03,
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
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: const Color(0xFF005B96), size: screenWidth * 0.05),
                      onPressed: () => _showEditAlertDialog(alert),
                      padding: EdgeInsets.all(screenWidth * 0.01),
                      constraints: BoxConstraints(),
                    ),
                    SizedBox(width: screenWidth * 0.01),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red, size: screenWidth * 0.05),
                      onPressed: () => _showDeleteConfirmation(alert, screenWidth),
                      padding: EdgeInsets.all(screenWidth * 0.01),
                      constraints: BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton(double screenWidth) {
    return Container(
      decoration: _fabDecoration(),
      child: FloatingActionButton(
        onPressed: _showAddAlertDialog,
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Icon(Icons.add_alert, color: Colors.white, size: screenWidth * 0.06),
      ),
    );
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
          color: const Color(0xFF005B96).withOpacity(0.2),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  Widget _buildCardHeader(IconData icon, String title, double screenWidth) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(screenWidth * 0.015),
          decoration: BoxDecoration(
            color: const Color(0xFF005B96).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF005B96), size: screenWidth * 0.05),
        ),
        SizedBox(width: screenWidth * 0.02),
        Text(
          title,
          style: TextStyle(
            fontSize: screenWidth * 0.04,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF005B96),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, double screenWidth) {
    return Row(
      children: [
        Icon(icon, size: screenWidth * 0.04, color: Colors.grey[600]),
        SizedBox(width: screenWidth * 0.015),
        Text(
          "$label: ",
          style: TextStyle(
            fontSize: screenWidth * 0.03,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: screenWidth * 0.03,
              color: const Color(0xFF005B96),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}