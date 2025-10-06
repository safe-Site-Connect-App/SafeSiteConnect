import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../../ViewsModels/pointage_viewmodel.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({Key? key}) : super(key: key);

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController controller = MobileScannerController();
  bool isFlashOn = false;
  bool isScanHandled = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _toggleFlash() {
    controller.toggleTorch();
    setState(() {
      isFlashOn = !isFlashOn;
    });
  }

  void _handleScan(String? barcode) {
    if (barcode == null || isScanHandled) return;
    isScanHandled = true;
    controller.stop();
    _showScanResult(barcode);
  }

  String _convertDateFormat(String date) {
    // Convertir DD/MM/YYYY en YYYY-MM-DD
    try {
      final parts = date.split('/');
      if (parts.length == 3) {
        final day = parts[0].padLeft(2, '0');
        final month = parts[1].padLeft(2, '0');
        final year = parts[2];
        return '$year-$month-$day';
      }
    } catch (e) {
      debugPrint('Erreur conversion date: $e');
    }
    return date;
  }

  void _showScanResult(String qrCode) {
    debugPrint('========== QR CODE SCANNÉ ==========');
    debugPrint('Contenu brut: $qrCode');
    debugPrint('Longueur: ${qrCode.length}');

    final cleanedQRCode = qrCode.trim();

    bool isValidFormat = false;
    String displayType = 'Inconnu';
    String displayDate = 'N/A';
    String displayTime = 'N/A';
    String normalizedQRCode = '';

    // Format 1: TYPE|DATE|HEURE (format avec pipes)
    final qrParts = cleanedQRCode.split('|');
    debugPrint('Format pipe - Nombre de parties: ${qrParts.length}');

    if (qrParts.length == 3) {
      final type = qrParts[0].trim().toUpperCase();
      final date = qrParts[1].trim();
      final time = qrParts[2].trim();

      debugPrint('Type: $type');
      debugPrint('Date: $date');
      debugPrint('Heure: $time');

      if (type == 'ENTREE' || type == 'SORTIE') {
        final dateRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
        final timeRegex = RegExp(r'^\d{2}:\d{2}$');

        if (dateRegex.hasMatch(date) && timeRegex.hasMatch(time)) {
          isValidFormat = true;
          displayType = type;
          displayDate = date;
          displayTime = time;
          normalizedQRCode = '$type|$date|$time';
        }
      }
    }
    // Format 2: TYPE: ENTREE\nDate: DD/MM/YYYY\nHeure: HH:MM (format multiligne)
    else {
      debugPrint('Essai format multiligne...');
      final lines = cleanedQRCode.split('\n');
      debugPrint('Nombre de lignes: ${lines.length}');

      String? type;
      String? date;
      String? time;

      for (var line in lines) {
        final trimmedLine = line.trim();
        debugPrint('Ligne: $trimmedLine');

        if (trimmedLine.toUpperCase().startsWith('TYPE:')) {
          type = trimmedLine.split(':').last.trim().toUpperCase();
          debugPrint('Type trouvé: $type');
        } else if (trimmedLine.toLowerCase().startsWith('date:')) {
          date = trimmedLine.split(':').last.trim();
          debugPrint('Date trouvée: $date');
        } else if (trimmedLine.toLowerCase().startsWith('heure:')) {
          // Gérer le cas où l'heure a un format "Heure: HH:MM"
          final parts = trimmedLine.split(':');
          if (parts.length >= 3) {
            time = '${parts[1].trim()}:${parts[2].trim()}';
          } else if (parts.length == 2) {
            time = parts[1].trim();
          }
          debugPrint('Heure trouvée: $time');
        }
      }

      if (type != null && date != null && time != null) {
        debugPrint('Toutes les parties trouvées - Validation...');

        if (type == 'ENTREE' || type == 'SORTIE') {
          // Vérifier et convertir le format de date
          final dateRegexDDMMYYYY = RegExp(r'^\d{1,2}/\d{1,2}/\d{4}$');
          final timeRegex = RegExp(r'^\d{2}:\d{2}$');

          if (dateRegexDDMMYYYY.hasMatch(date) && timeRegex.hasMatch(time)) {
            isValidFormat = true;
            displayType = type;
            displayDate = _convertDateFormat(date);
            displayTime = time;
            normalizedQRCode = '$type|$displayDate|$time';
            debugPrint('Format valide! QR normalisé: $normalizedQRCode');
          }
        }
      }
    }

    debugPrint('Format valide: $isValidFormat');
    debugPrint('====================================');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isValidFormat
                    ? const Color(0xFF7ED957).withOpacity(0.1)
                    : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isValidFormat ? Icons.qr_code_2 : Icons.warning,
                color: isValidFormat ? const Color(0xFF7ED957) : Colors.orange,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isValidFormat ? 'Code QR scanné' : 'Format invalide',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isValidFormat) ...[
                _buildInfoRow('Type', displayType,
                    displayType == 'ENTREE' ? Icons.login : Icons.logout),
                const SizedBox(height: 12),
                _buildInfoRow('Date', displayDate, Icons.calendar_today),
                const SizedBox(height: 12),
                _buildInfoRow('Heure', displayTime, Icons.access_time),
              ] else ...[
                const Text(
                  'Le code QR scanné n\'est pas au bon format.',
                  style: TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Format attendu:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 4),
                const Text(
                  'TYPE: ENTREE\nDate: 05/10/2025\nHeure: 14:30',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Contenu scanné:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    cleanedQRCode,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              setState(() {
                isScanHandled = false;
              });
              controller.start();
            },
            child: const Text('Scanner à nouveau'),
          ),
          if (isValidFormat)
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _processQRCode(normalizedQRCode);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF005B96),
                foregroundColor: Colors.white,
              ),
              child: const Text('Valider'),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF005B96)),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF005B96),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _processQRCode(String qrCode) async {
    final pointageVM = Provider.of<PointageViewModel>(context, listen: false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          margin: EdgeInsets.all(40),
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Enregistrement du pointage...'),
              ],
            ),
          ),
        ),
      ),
    );

    final success = await pointageVM.createPointageFromQR(
      qrCodeData: qrCode,
      context: context,
    );

    if (mounted) Navigator.of(context).pop();

    if (success) {
      if (mounted) {
        Navigator.of(context).pop(true);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Pointage ${pointageVM.lastPointage?.type.value ?? ''} enregistré avec succès',
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF7ED957),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      if (mounted) {
        showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(child: Text('Erreur')),
              ],
            ),
            content: Text(
              pointageVM.errorMessage ?? 'Une erreur est survenue',
              style: const TextStyle(fontSize: 15),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  Navigator.of(context).pop();
                },
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  setState(() {
                    isScanHandled = false;
                  });
                  controller.start();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF005B96),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white, size: 28),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Scanner QR Code',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isFlashOn ? Icons.flash_on : Icons.flash_off,
              color: Colors.white,
              size: 28,
            ),
            onPressed: _toggleFlash,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: Stack(
              children: [
                MobileScanner(
                  controller: controller,
                  onDetect: (capture) {
                    final List<Barcode> barcodes = capture.barcodes;
                    if (barcodes.isEmpty) return;
                    final String? code = barcodes.first.rawValue;
                    _handleScan(code);
                  },
                ),
                Center(
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 100,
                  left: 0,
                  right: 0,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Positionnez le code QR dans le cadre pour le scanner',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(20),
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.qr_code_scanner,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Alignez le code QR avec le cadre ci-dessus',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}