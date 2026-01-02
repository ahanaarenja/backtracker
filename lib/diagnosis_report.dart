import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'colours.dart';

class DiagnosisReport extends StatefulWidget {
  final String diagnosis;
  final double? confidence;

  const DiagnosisReport({
    Key? key,
    required this.diagnosis,
    this.confidence,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return DiagnosisReportState();
  }
}

class DiagnosisReportState extends State<DiagnosisReport> {
  bool _isLoading = false;
  
  bool get isNonMechanical =>
      widget.diagnosis.toLowerCase().contains("further investigation");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: light,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: dark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "AI back analysis report:",
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20, color: dark),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.share, color: dark),
            onPressed: _isLoading ? null : _sharePdf,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  isNonMechanical
                      ? _buildNonMechanicalReport()
                      : _buildMechanicalReport(),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Share/Download buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _downloadPdf,
                    icon: _isLoading 
                        ? const SizedBox(
                            width: 20, 
                            height: 20, 
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                          )
                        : const Icon(Icons.download, color: Colors.white),
                    label: const Text('Download PDF', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: dark,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _sharePdf,
                    icon: const Icon(Icons.share, color: Colors.white),
                    label: const Text('Share', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4ECDC4),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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

  Future<File> _createPdfFile() async {
    final pdf = await _generatePdf();
    final bytes = await pdf.save();
    
    // Use Dart's built-in system temp directory (no plugin needed)
    final tempDir = Directory.systemTemp;
    final file = File('${tempDir.path}/BackTracker_Report.pdf');
    await file.writeAsBytes(bytes);
    
    return file;
  }

  Future<void> _downloadPdf() async {
    setState(() => _isLoading = true);
    
    try {
      final pdf = await _generatePdf();
      final bytes = await pdf.save();
      final fileName = 'BackTracker_Report_${DateTime.now().millisecondsSinceEpoch}.pdf';
      
      if (Platform.isAndroid) {
        // Android: Save to Downloads folder
        PermissionStatus status = await Permission.storage.request();
        
        if (!status.isGranted) {
          // For Android 11+, try MANAGE_EXTERNAL_STORAGE
          status = await Permission.manageExternalStorage.request();
        }
        
        if (!status.isGranted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please grant storage permission in settings'),
                backgroundColor: Colors.orange,
              ),
            );
            openAppSettings();
          }
          return;
        }
        
        final downloadsPath = '/storage/emulated/0/Download';
        final file = File('$downloadsPath/$fileName');
        await file.writeAsBytes(bytes);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✓ Saved to Downloads: $fileName'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else if (Platform.isIOS) {
        // iOS: Save to app's Documents folder (accessible via Files app)
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(bytes);
        
        if (mounted) {
          // Show success message with option to share
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('✓ Saved! Open in Files app or tap Share'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'Share',
                textColor: Colors.white,
                onPressed: () {
                  Share.shareXFiles(
                    [XFile(file.path)],
                    subject: 'My BackTracker Assessment Report',
                  );
                },
              ),
            ),
          );
        }
      } else {
        // Fallback for other platforms: use share
        final tempDir = Directory.systemTemp;
        final file = File('${tempDir.path}/$fileName');
        await file.writeAsBytes(bytes);
        
        await Share.shareXFiles(
          [XFile(file.path)],
          subject: 'My BackTracker Assessment Report',
        );
      }
      
    } catch (e) {
      debugPrint('Error downloading PDF: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _sharePdf() async {
    setState(() => _isLoading = true);
    
    try {
      final file = await _createPdfFile();
      
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'My BackTracker Assessment Report',
      );
      
    } catch (e) {
      debugPrint('Error sharing PDF: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<pw.Document> _generatePdf() async {
    final pdf = pw.Document();
    
    final reportType = isNonMechanical ? 'Non-Mechanical Back Pain' : 'Mechanical Back Pain';
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Center(
                child: pw.Text(
                  'BackTracker',
                  style: pw.TextStyle(
                    fontSize: 28,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900,
                  ),
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Text(
                  'AI Back Analysis Report',
                  style: pw.TextStyle(
                    fontSize: 18,
                    color: PdfColors.grey700,
                  ),
                ),
              ),
              pw.SizedBox(height: 30),
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 20),
              
              // Result
              _pdfSectionHeader('Your Result'),
              pw.Text(
                reportType,
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 20),
              
              if (isNonMechanical) ...[
                _pdfSectionHeader('What this means'),
                pw.Text(
                  'Your symptoms suggest that the pain may not be caused by posture, movement, or muscle strain. Instead, it could be linked to internal or systemic factors, such as:',
                  style: const pw.TextStyle(fontSize: 12),
                ),
                pw.SizedBox(height: 8),
                _pdfBulletList(['Inflammation', 'Infection', 'Other underlying medical conditions']),
                pw.SizedBox(height: 16),
                
                _pdfSectionHeader('Why this matters'),
                pw.Text(
                  'Non-mechanical back pain does not usually improve with exercises alone and may require:',
                  style: const pw.TextStyle(fontSize: 12),
                ),
                pw.SizedBox(height: 8),
                _pdfBulletList(['Medical evaluation', 'Further tests (if advised by a doctor)']),
                pw.SizedBox(height: 16),
                
                _pdfSectionHeader('What to do next'),
                _pdfBulletList([
                  'Monitor your symptoms closely',
                  'Seek medical advice for proper diagnosis and treatment',
                ]),
              ] else ...[
                _pdfSectionHeader('What this means'),
                pw.Text(
                  'Your pain is most consistent with mechanical back pain, meaning it is related to movement, posture, or muscle/joint strain. This type of pain is very common and often improves with the right care.',
                  style: const pw.TextStyle(fontSize: 12),
                ),
                pw.SizedBox(height: 16),
                
                _pdfSectionHeader('What helps'),
                pw.Text(
                  'Mechanical back pain usually responds well to:',
                  style: const pw.TextStyle(fontSize: 12),
                ),
                pw.SizedBox(height: 8),
                _pdfBulletList([
                  'Targeted exercises',
                  'Posture correction',
                  'Activity modification',
                  'Adequate rest',
                ]),
                pw.SizedBox(height: 16),
                
                _pdfSectionHeader('Do I need tests?'),
                pw.Text(
                  'Further investigations are not usually required unless pain worsens, symptoms last longer than expected, or new symptoms appear.',
                  style: const pw.TextStyle(fontSize: 12),
                ),
              ],
              
              pw.SizedBox(height: 30),
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 16),
              
              // Disclaimer
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Important Note',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'This is an AI-generated report for basic back health guidance only. It is not a medical diagnosis. If symptoms worsen or persist, please consult a doctor.',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),
              
              pw.Spacer(),
              
              // Footer
              pw.Center(
                child: pw.Text(
                  'Generated on ${DateTime.now().toString().split(' ')[0]}',
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey500,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
    
    return pdf;
  }

  pw.Widget _pdfSectionHeader(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 14,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.blue900,
        ),
      ),
    );
  }

  pw.Widget _pdfBulletList(List<String> items) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: items.map((item) => pw.Padding(
        padding: const pw.EdgeInsets.only(left: 16, bottom: 4),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('- ', style: const pw.TextStyle(fontSize: 12)),
            pw.Expanded(
              child: pw.Text(item, style: const pw.TextStyle(fontSize: 12)),
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildNonMechanicalReport() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("📍", "Your Result"),
        _buildResultText("Non-Mechanical Back Pain"),
        const SizedBox(height: 16),
        _buildSectionHeader("🧠", "What this means"),
        _buildParagraph(
          "Your symptoms suggest that the pain may not be caused by posture, movement, or muscle strain.",
        ),
        _buildParagraph(
          "Instead, it could be linked to internal or systemic factors, such as:",
        ),
        _buildBulletList([
          "Inflammation",
          "Infection",
          "Other underlying medical conditions",
        ]),
        const SizedBox(height: 16),
        _buildSectionHeader("🔍", "Why this matters"),
        _buildParagraph(
          "Non-mechanical back pain does not usually improve with exercises alone and may require:",
        ),
        _buildBulletList([
          "Medical evaluation",
          "Further tests (if advised by a doctor)",
        ]),
        const SizedBox(height: 16),
        _buildSectionHeader("⚠️", "What to do next"),
        _buildBulletList([
          "Monitor your symptoms closely",
          "Seek medical advice for proper diagnosis and treatment",
        ]),
        const SizedBox(height: 16),
        _buildSectionHeader("ℹ️", "Important Note"),
        _buildImportantNote(),
      ],
    );
  }

  Widget _buildMechanicalReport() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("📍", "Your Result"),
        _buildResultText("Mechanical Back Pain"),
        const SizedBox(height: 16),
        _buildSectionHeader("🧠", "What this means"),
        _buildParagraph(
          "Your pain is most consistent with mechanical back pain, meaning it is related to:",
        ),
        _buildBulletList([
          "Movement",
          "Posture",
          "Muscle or joint strain",
        ]),
        _buildParagraph(
          "This type of pain is very common and often improves with the right care.",
        ),
        const SizedBox(height: 16),
        _buildSectionHeader("💪", "What helps"),
        _buildParagraph(
          "Mechanical back pain usually responds well to:",
        ),
        _buildBulletList([
          "Targeted exercises",
          "Posture correction",
          "Activity modification",
          "Adequate rest",
        ]),
        const SizedBox(height: 16),
        _buildSectionHeader("🔍", "Do I need tests?"),
        _buildParagraph(
          "Further investigations are not usually required unless:",
        ),
        _buildBulletList([
          "Pain worsens",
          "Symptoms last longer than expected",
          "New symptoms appear",
        ]),
        const SizedBox(height: 16),
        _buildSectionHeader("ℹ️", "Important Note"),
        _buildImportantNote(),
      ],
    );
  }

  Widget _buildSectionHeader(String emoji, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: dark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultText(String result) {
    return Text(
      result,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.black87,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildBulletList(List<String> items) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items.map((item) => _buildBulletItem(item)).toList(),
      ),
    );
  }

  Widget _buildBulletItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("• ", style: TextStyle(fontSize: 14, color: Colors.black87)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImportantNote() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildParagraph(
          "This is an AI-generated report for basic back health guidance only.",
        ),
        const Text(
          "It is not a medical diagnosis.",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 8),
        _buildParagraph(
          "If symptoms worsen or persist, please consult a doctor.",
        ),
      ],
    );
  }
}
