import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf/pdf.dart';
import 'package:provider/provider.dart';
import '../../../ViewsModels/pointage_viewmodel.dart';
import '../../../models/pointage_model.dart';
import '../../../utils/storage_helper.dart';
import '../../../utils/dio_client.dart'; // Ajout pour vérifier l'authentification via DioClient
import 'CustomBottomNavigationBarAdmin.dart';
import 'dart:io';

class PointageEmployScreen extends StatefulWidget {
  const PointageEmployScreen({super.key});

  @override
  State<PointageEmployScreen> createState() => _PointageEmployScreenState();
}

class _PointageEmployScreenState extends State<PointageEmployScreen> {
  int _currentIndex = 4;
  final String _adminName = "Admin Principal";
  String _searchQuery = '';
  String _sortBy = 'date';
  String? _selectedSite;
  bool _showPresentOnly = false;
  DateTime _startDate = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
  DateTime _endDate = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1)).add(Duration(days: 6));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Vérifier l'état de connexion via StorageHelper et DioClient
      final isLoggedIn = await StorageHelper.isLoggedIn();
      final isAuthenticated = await DioClient.instance.isAuthenticated();
      print('🔍 [SCREEN] Vérification connexion: isLoggedIn=$isLoggedIn, isAuthenticated=$isAuthenticated');

      if (!isLoggedIn && !isAuthenticated) {
        print('❌ [SCREEN] Utilisateur non connecté');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez vous reconnecter')),
        );
        // Rediriger vers l'écran de connexion
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      // Si l'un des deux indique une connexion valide, charger les pointages
      try {
        print('📥 [SCREEN] Chargement des pointages pour la semaine...');
        await Provider.of<PointageViewModel>(context, listen: false).fetchAllPointagesByWeek(
          start: _startDate,
          end: _endDate,
        );
        print('✅ [SCREEN] Pointages chargés avec succès');
      } catch (e) {
        print('❌ [SCREEN] Erreur lors du chargement des pointages: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement des pointages: $e')),
        );
      }
    });
  }

  List<Map<String, dynamic>> _processPointages(List<PointageModel> pointages) {
    final Map<String, Map<String, Map<String, dynamic>>> grouped = {};
    for (var pointage in pointages) {
      final dateKey = DateFormat('yyyy-MM-dd').format(pointage.date);
      final userKey = pointage.user;
      grouped[userKey] ??= {};
      grouped[userKey]![dateKey] ??= {
        'userId': userKey,
        'employee': pointage.userName,
        'date': pointage.date.toIso8601String(),
        'entryTime': pointage.type == PointageType.entree ? pointage.heure : null,
        'exitTime': null,
        'isPresent': pointage.etat == PointageEtat.present && pointage.type == PointageType.entree,
      };

      if (pointage.type == PointageType.sortie) {
        if (grouped[userKey]![dateKey] != null) {
          grouped[userKey]![dateKey]!['exitTime'] = pointage.heure;
          grouped[userKey]![dateKey]!['isPresent'] = false;
        }
      } else if (pointage.type == PointageType.entree) {
        grouped[userKey]![dateKey]!['entryTime'] = pointage.heure;
      }
    }

    final List<Map<String, dynamic>> attendances = [];
    grouped.forEach((user, dates) {
      dates.forEach((date, data) {
        attendances.add(data);
      });
    });
    return attendances;
  }

  List<Map<String, dynamic>> getFilteredAttendances(List<Map<String, dynamic>> attendances) {
    var result = attendances.where((a) {
      final matchesSearch = _searchQuery.isEmpty ||
          a['employee'].toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesSite = _selectedSite == null;
      final matchesPresence = !_showPresentOnly || (a['isPresent'] == true && a['exitTime'] == null);
      return matchesSearch && matchesSite && matchesPresence;
    }).toList();

    if (_sortBy == 'date') {
      result.sort((a, b) => b['date'].compareTo(a['date']));
    } else {
      result.sort((a, b) => a['employee'].compareTo(b['employee']));
    }
    return result;
  }

  void _sortItems(String sortBy) {
    setState(() {
      _sortBy = sortBy;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PointageViewModel>(
      builder: (context, viewModel, child) {
        final attendances = _processPointages(viewModel.weekPointages);
        final presentCount = attendances.where((a) => a['isPresent'] == true && a['exitTime'] == null).length;
        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          appBar: _buildAppBar(presentCount),
          body: viewModel.isLoading
              ? Center(child: CircularProgressIndicator(color: Color(0xFF005B96)))
              : viewModel.errorMessage != null
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 40, color: Colors.red),
                SizedBox(height: 8),
                Text(
                  viewModel.errorMessage!,
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => viewModel.fetchAllPointagesByWeek(start: _startDate, end: _endDate),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF005B96),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text('Réessayer'),
                ),
              ],
            ),
          )
              : _buildBody(attendances),
          bottomNavigationBar: CustomBottomNavigationBarAdmin(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
          ),
        );
      },
    );
  }

  AppBar _buildAppBar(int presentCount) {
    return AppBar(
      backgroundColor: const Color(0xFF005B96),
      elevation: 0,
      title: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Suivi des présences",
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
              ),
              Text(
                _adminName,
                style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 10, fontWeight: FontWeight.w400),
              ),
            ],
          ),
          if (presentCount > 0)
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: CircleAvatar(
                radius: 8,
                backgroundColor: Colors.green,
                child: Text(
                  presentCount.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
      automaticallyImplyLeading: false,
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.sort, color: Colors.white, size: 20),
          onSelected: _sortItems,
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'date', child: Text('Trier par date')),
            const PopupMenuItem(value: 'employee', child: Text('Trier par employé')),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.filter_list, color: Colors.white, size: 20),
          onPressed: _showFilterDialog,
        ),
        IconButton(
          icon: const Icon(Icons.download, color: Colors.white, size: 20),
          onPressed: _showExportOptions,
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildBody(List<Map<String, dynamic>> attendances) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildHeaderGradient(),
          Padding(
            padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.03),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSearchSection(),
                const SizedBox(height: 12),
                _buildUsersSection(attendances),
              ],
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

  Widget _buildSearchSection() {
    return Container(
      decoration: _cardDecoration(),
      padding: const EdgeInsets.all(8),
      child: TextField(
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: "Rechercher par employé...",
          hintStyle: TextStyle(color: Colors.grey[500], fontSize: 12),
          prefixIcon: Icon(Icons.search, color: Colors.grey[500], size: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: const Color(0xFFF1F5F9),
          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        ),
        style: const TextStyle(fontSize: 12),
      ),
    );
  }

  Widget _buildUsersSection(List<Map<String, dynamic>> attendances) {
    return Container(
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF005B96),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.people, color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  const Text(
                    "Pointages",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            height: MediaQuery.of(context).size.height * 0.7,
            padding: const EdgeInsets.all(12),
            child: _buildAttendanceList(attendances),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceList(List<Map<String, dynamic>> attendances) {
    final filteredList = getFilteredAttendances(attendances);
    if (filteredList.isEmpty) return _buildEmptyState();
    return ListView.separated(
      itemCount: filteredList.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final attendance = filteredList[i];
        if (attendance['isPresent'] == true && attendance['exitTime'] == null) {
          return _buildPresenceCard(attendance);
        } else {
          return _buildHistoryCard(attendance);
        }
      },
    );
  }

  Widget _buildPresenceCard(Map<String, dynamic> attendance) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: _cardDecoration(),
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
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.login, color: Color(0xFF10B981), size: 20),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    attendance['employee'],
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF005B96),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.access_time, "Entrée", attendance['entryTime'] ?? 'N/A'),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> attendance) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: _cardDecoration(),
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
                    color: const Color(0xFF005B96).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    attendance['exitTime'] == null ? Icons.login : Icons.logout,
                    color: const Color(0xFF005B96),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    attendance['employee'],
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF005B96),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.access_time, "Entrée", attendance['entryTime'] ?? 'N/A'),
            if (attendance['exitTime'] != null) ...[
              const SizedBox(height: 6),
              _buildInfoRow(Icons.access_time, "Sortie", attendance['exitTime']),
            ],
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
            "Aucun pointage trouvé",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[600]),
          ),
          Text(
            "Essayez d'autres filtres ou termes de recherche",
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
        ],
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

  void _showFilterDialog() {
    bool tempShowPresentOnly = _showPresentOnly;
    DateTime tempStartDate = _startDate;
    DateTime tempEndDate = _endDate;

    showDialog(
      context: context,
      builder: (context) => Dialog(
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
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              return SingleChildScrollView(
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
                          "Filtrer les pointages",
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
                      value: tempShowPresentOnly ? 'present' : 'all',
                      decoration: _buildInputDecoration('Afficher', Icons.filter_alt_outlined),
                      items: [
                        const DropdownMenuItem(
                          value: 'all',
                          child: Text('Tous les pointages', style: TextStyle(fontSize: 12)),
                        ),
                        const DropdownMenuItem(
                          value: 'present',
                          child: Text('Présences en cours', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                      onChanged: (value) => setDialogState(() {
                        tempShowPresentOnly = value == 'present';
                      }),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: tempStartDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setDialogState(() => tempStartDate = picked);
                        }
                      },
                      child: InputDecorator(
                        decoration: _buildInputDecoration('Date de début', Icons.calendar_today),
                        child: Text(
                          DateFormat('dd/MM/yyyy').format(tempStartDate),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: tempEndDate,
                          firstDate: tempStartDate,
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setDialogState(() => tempEndDate = picked);
                        }
                      },
                      child: InputDecorator(
                        decoration: _buildInputDecoration('Date de fin', Icons.calendar_today),
                        child: Text(
                          DateFormat('dd/MM/yyyy').format(tempEndDate),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
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
                              setState(() {
                                _showPresentOnly = tempShowPresentOnly;
                                _startDate = tempStartDate;
                                _endDate = tempEndDate;
                              });
                              Provider.of<PointageViewModel>(context, listen: false).fetchAllPointagesByWeek(
                                start: tempStartDate,
                                end: tempEndDate,
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
              );
            },
          ),
        ),
      ),
    );
  }

  void _showExportOptions() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
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
                    child: const Icon(Icons.download, color: Color(0xFF005B96), size: 18),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: const Text(
                      "Options d'exportation",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF005B96),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showEmployeeSelectionDialog();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF005B96),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                child: const Text("Rapport individuel", style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEmployeeSelectionDialog() {
    String? selectedEmployee;
    final viewModel = Provider.of<PointageViewModel>(context, listen: false);
    final attendances = _processPointages(viewModel.weekPointages);
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, Color(0xFFF8F9FA)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
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
                          child: const Icon(Icons.person, color: Color(0xFF005B96), size: 20),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: const Text(
                            "Sélectionner un employé",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF005B96),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 16),
                          onPressed: () => Navigator.pop(context),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedEmployee,
                      decoration: _buildInputDecoration('Employé', Icons.person_outlined),
                      items: attendances
                          .map((e) => e['employee'] as String)
                          .toSet()
                          .toList()
                          .map((emp) => DropdownMenuItem(
                        value: emp,
                        child: Text(emp, style: const TextStyle(fontSize: 12)),
                      ))
                          .toList(),
                      onChanged: (value) => selectedEmployee = value,
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
                            onPressed: () async {
                              if (selectedEmployee != null) {
                                await _exportEmployeeHistoryPdf(selectedEmployee!);
                                Navigator.pop(context);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF005B96),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                            child: const Text(
                              "Exporter",
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
          ),
        ),
      ),
    );
  }

  Future<void> _exportEmployeeHistoryPdf(String employee) async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final viewModel = Provider.of<PointageViewModel>(context, listen: false);
    final attendances = _processPointages(viewModel.weekPointages);

    // Trouver l'userId correspondant à l'employé
    final matchingAttendance = attendances.firstWhere(
          (a) => a['employee'] == employee,
      orElse: () => <String, dynamic>{},
    );

    final userId = matchingAttendance['userId'] as String?;
    if (userId == null) {
      print('❌ [SCREEN] Utilisateur non trouvé pour employé: $employee');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Utilisateur non trouvé')),
      );
      return;
    }

    // Vérifier si l'utilisateur est connecté
    final isLoggedIn = await StorageHelper.isLoggedIn();
    final isAuthenticated = await DioClient.instance.isAuthenticated();
    print('🔍 [SCREEN] Vérification connexion pour export: isLoggedIn=$isLoggedIn, isAuthenticated=$isAuthenticated');

    if (!isLoggedIn && !isAuthenticated) {
      print('❌ [SCREEN] Utilisateur non connecté');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez vous reconnecter')),
      );
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    // Fetch des pointages pour le mois pour cet utilisateur
    try {
      final startStr = DateFormat('yyyy-MM-dd').format(startOfMonth);
      final endStr = DateFormat('yyyy-MM-dd').format(now);
      print('📥 [SCREEN] Récupération historique pour userId: $userId, période: $startStr à $endStr');

      final historyJson = await viewModel.repository.getPointageHistory(
        startDate: startStr,
        endDate: endStr,
        userId: userId,
      );

      final historyPointages = historyJson.map((json) => PointageModel.fromJson(json)).toList();
      final records = _processPointages(historyPointages);

      print('✅ [SCREEN] Historique récupéré: ${records.length} enregistrements');
      await _generateHistoryPdf(records, 'Historique des pointages de $employee');
    } catch (e) {
      print('❌ [SCREEN] Erreur lors de la récupération: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la récupération: $e')),
      );
    }
  }

  Future<void> _generateHistoryPdf(List<Map<String, dynamic>> records, String title) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              title,
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 16),
          if (records.isEmpty)
            pw.Center(
              child: pw.Text('Aucun pointage trouvé.', style: const pw.TextStyle(fontSize: 12)),
            )
          else
            pw.Table.fromTextArray(
              headers: ['Employé', 'Date', 'Entrée', 'Sortie'],
              data: records.map((record) {
                final date = DateTime.parse(record['date']);
                return [
                  record['employee'],
                  DateFormat('dd/MM/yyyy').format(date),
                  record['entryTime'] ?? 'Non enregistrée',
                  record['exitTime'] ?? 'Non enregistrée',
                ];
              }).toList(),
              border: pw.TableBorder.all(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellAlignment: pw.Alignment.centerLeft,
              cellPadding: pw.EdgeInsets.all(6),
            ),
        ],
      ),
    );

    final dir = await getTemporaryDirectory();
    final fileName = title.toLowerCase().replaceAll(' ', '_') + '_history_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(await pdf.save());

    final result = await OpenFile.open(file.path);
    if (result.type != ResultType.done) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'ouverture du PDF: ${result.message}')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF généré avec succès')),
      );
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
          style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12, color: Color(0xFF005B96), fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}