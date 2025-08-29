import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:typed_data';
import '../providers/database_provider.dart';
import '../models/student.dart' as models;
import '../models/item.dart' as models;
import '../models/storage.dart' as models;
import '../core/design_system.dart';
import '../shared/widgets/app_card.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  bool _isGenerating = false;
  Map<String, dynamic> _reportData = {};

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  Future<void> _loadReportData() async {
    try {
      final databaseService = ref.read(databaseServiceProvider);
      
      final students = await databaseService.getAllStudents();
      final storages = await databaseService.getAllStorages();
      final items = await databaseService.getAllItems();
      
      // Calculate statistics
      int activeBorrows = 0;
      int totalItemsBorrowed = 0;
      List<Map<String, dynamic>> borrowHistory = [];
      
      for (final student in students) {
        final borrows = await databaseService.getActiveBorrowsByStudent(student.id);
        activeBorrows += borrows.length;
        
        for (final record in borrows) {
          totalItemsBorrowed += record.items.length;
          borrowHistory.add({
            'studentName': student.name,
            'studentId': student.studentId,
            'borrowId': record.borrowId,
            'borrowDate': record.borrowedAt,
            'itemCount': record.items.length,
            'status': record.status.name,
          });
        }
      }
      
      // Calculate inventory statistics
      final totalQuantity = items.fold(0, (sum, item) => sum + item.totalQuantity);
      final availableQuantity = items.fold(0, (sum, item) => sum + item.availableQuantity);
      final borrowedQuantity = totalQuantity - availableQuantity;
      
      // Low stock items (< 20% available)
      final lowStockItems = items.where((item) => 
        item.availableQuantity <= (item.totalQuantity * 0.2)).toList();
      
      setState(() {
        _reportData = {
          'students': students,
          'storages': storages,
          'items': items,
          'activeBorrows': activeBorrows,
          'totalItemsBorrowed': totalItemsBorrowed,
          'borrowHistory': borrowHistory,
          'totalQuantity': totalQuantity,
          'availableQuantity': availableQuantity,
          'borrowedQuantity': borrowedQuantity,
          'lowStockItems': lowStockItems,
          'generatedAt': DateTime.now(),
        };
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading report data: $e')),
        );
      }
    }
  }

  Future<void> _generatePDFReport(String reportType) async {
    setState(() {
      _isGenerating = true;
    });

    try {
      final pdf = pw.Document();
      
      switch (reportType) {
        case 'inventory':
          await _generateInventoryReport(pdf);
          break;
        case 'students':
          await _generateStudentsReport(pdf);
          break;
        case 'borrows':
          await _generateBorrowsReport(pdf);
          break;
        case 'summary':
          await _generateSummaryReport(pdf);
          break;
      }
      
      final pdfBytes = await pdf.save();
      
      if (mounted) {
        _showPreviewDialog(reportType, pdfBytes);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating report: $e')),
        );
      }
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  void _showPreviewDialog(String reportType, Uint8List pdfBytes) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _PDFPreviewDialog(
        reportType: reportType,
        pdfBytes: pdfBytes,
        onSave: () => _savePDF(reportType, pdfBytes),
      ),
    );
  }

  Future<void> _savePDF(String reportType, Uint8List pdfBytes) async {
    try {
      final fileName = 'ToolEase_${reportType}_Report_${DateTime.now().millisecondsSinceEpoch}.pdf';
      
      // For Android, we'll save to Downloads directory
      final directory = Directory('/storage/emulated/0/Download');
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(pdfBytes);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report saved to Downloads: $fileName'),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'OK',
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving report: $e')),
        );
      }
    }
  }

  Future<void> _generateInventoryReport(pw.Document pdf) async {
    final items = _reportData['items'] as List<models.Item>;
    final storages = _reportData['storages'] as List<models.Storage>;
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => [
          pw.Header(level: 0, child: pw.Text('ToolEase - Inventory Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold))),
          pw.Paragraph(text: 'Generated on: ${DateTime.now().toString().split('.')[0]}'),
          pw.SizedBox(height: 20),
          
          pw.Text('Summary', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.Text('Total Items: ${items.length}'),
          pw.Text('Total Storages: ${storages.length}'),
          pw.Text('Total Quantity: ${_reportData['totalQuantity']}'),
          pw.Text('Available Quantity: ${_reportData['availableQuantity']}'),
          pw.Text('Borrowed Quantity: ${_reportData['borrowedQuantity']}'),
          pw.SizedBox(height: 20),
          
          pw.Text('Items by Storage', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          ...storages.map((storage) {
            final storageItems = items.where((item) => item.storageId == storage.id).toList();
            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 10),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('${storage.name} (${storageItems.length} items)', 
                    style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  ...storageItems.map((item) => pw.Padding(
                    padding: const pw.EdgeInsets.only(left: 20),
                    child: pw.Text('• ${item.name}: ${item.availableQuantity}/${item.totalQuantity} available'),
                  )),
                ],
              ),
            );
          }),
          
          if ((_reportData['lowStockItems'] as List).isNotEmpty) ...[
            pw.SizedBox(height: 20),
            pw.Text('Low Stock Items', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            ...(_reportData['lowStockItems'] as List<models.Item>).map((item) => 
              pw.Text('• ${item.name}: ${item.availableQuantity}/${item.totalQuantity} available (${item.totalQuantity > 0 ? (item.availableQuantity / item.totalQuantity * 100).round() : 0}%)')
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _generateStudentsReport(pw.Document pdf) async {
    final students = _reportData['students'] as List<models.Student>;
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => [
          pw.Header(level: 0, child: pw.Text('ToolEase - Students Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold))),
          pw.Paragraph(text: 'Generated on: ${DateTime.now().toString().split('.')[0]}'),
          pw.SizedBox(height: 20),
          
          pw.Text('Total Students: ${students.length}', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 20),
          
          pw.TableHelper.fromTextArray(
            headers: ['Student ID', 'Name', 'Year Level', 'Section', 'Registered'],
            data: students.map((student) => [
              student.studentId,
              student.name,
              student.yearLevel,
              student.section,
              student.createdAt.toString().split(' ')[0],
            ]).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellAlignment: pw.Alignment.centerLeft,
          ),
        ],
      ),
    );
  }

  Future<void> _generateBorrowsReport(pw.Document pdf) async {
    final borrowHistory = _reportData['borrowHistory'] as List<Map<String, dynamic>>;
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => [
          pw.Header(level: 0, child: pw.Text('ToolEase - Borrow Records Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold))),
          pw.Paragraph(text: 'Generated on: ${DateTime.now().toString().split('.')[0]}'),
          pw.SizedBox(height: 20),
          
          pw.Text('Active Borrows: ${_reportData['activeBorrows']}', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.Text('Total Items Borrowed: ${_reportData['totalItemsBorrowed']}'),
          pw.SizedBox(height: 20),
          
          if (borrowHistory.isNotEmpty)
            pw.TableHelper.fromTextArray(
              headers: ['Borrow ID', 'Student', 'Student ID', 'Date', 'Items', 'Status'],
              data: borrowHistory.map((record) => [
                record['borrowId'],
                record['studentName'],
                record['studentId'],
                (record['borrowDate'] as DateTime).toString().split(' ')[0],
                record['itemCount'].toString(),
                record['status'].toUpperCase(),
              ]).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellAlignment: pw.Alignment.centerLeft,
            )
          else
            pw.Text('No active borrow records found.'),
        ],
      ),
    );
  }

  Future<void> _generateSummaryReport(pw.Document pdf) async {
    if (_reportData.isEmpty) {
      throw Exception('Report data not loaded. Please refresh and try again.');
    }
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => [
          pw.Header(level: 0, child: pw.Text('ToolEase - Summary Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold))),
          pw.Paragraph(text: 'Generated on: ${DateTime.now().toString().split('.')[0]}'),
          pw.SizedBox(height: 20),
          
          pw.Text('Overview', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.Text('Students: ${(_reportData['students'] as List).length}'),
          pw.Text('Storages: ${(_reportData['storages'] as List).length}'),
          pw.Text('Items: ${(_reportData['items'] as List).length}'),
          pw.Text('Active Borrows: ${_reportData['activeBorrows'] ?? 0}'),
          pw.SizedBox(height: 20),
          
          pw.Text('Inventory Status', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.Text('Total Items: ${_reportData['totalQuantity'] ?? 0}'),
          pw.Text('Available: ${_reportData['availableQuantity'] ?? 0}'),
          pw.Text('Currently Borrowed: ${_reportData['borrowedQuantity'] ?? 0}'),
          pw.Text('Utilization Rate: ${(_reportData['totalQuantity'] ?? 0) > 0 ? ((_reportData['borrowedQuantity'] ?? 0) / (_reportData['totalQuantity'] ?? 1) * 100).round() : 0}%'),
          pw.SizedBox(height: 20),
          
          if ((_reportData['lowStockItems'] as List?)?.isNotEmpty == true) ...[
            pw.Text('Alerts', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.Text('Low Stock Items: ${(_reportData['lowStockItems'] as List).length}', style: pw.TextStyle(color: PdfColors.red)),
            ...(_reportData['lowStockItems'] as List<models.Item>).take(5).map((item) => 
              pw.Text('• ${item.name}: ${item.availableQuantity}/${item.totalQuantity} available')
            ),
            if ((_reportData['lowStockItems'] as List).length > 5)
              pw.Text('... and ${(_reportData['lowStockItems'] as List).length - 5} more items'),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Reports & Analytics', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: _loadReportData,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: _reportData.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Section
                  _buildHeaderSection(),
                  
                  const SizedBox(height: AppSpacing.xl),
                  
                  // Quick Stats Dashboard
                  _buildQuickStats(),
                  
                  const SizedBox(height: AppSpacing.xl),
                  
                  // Report Generation Section
                  _buildReportGeneration(),
                  
                  const SizedBox(height: AppSpacing.xl),
                  
                  // System Information
                  _buildSystemInformation(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.onPrimary.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.analytics_outlined,
              color: AppColors.onPrimary,
              size: 32,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'System Reports & Analytics',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Generate comprehensive reports and view system analytics',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.onPrimary.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.dashboard_outlined, color: AppColors.primary),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Quick Statistics',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.6,
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
          children: [
            _buildStatCard(
              'Students',
              (_reportData['students'] as List).length,
              Icons.people_outline,
              AppColors.info,
              'Total registered',
            ),
            _buildStatCard(
              'Items',
              (_reportData['items'] as List).length,
              Icons.inventory_2_outlined,
              AppColors.accent,
              'In inventory',
            ),
            _buildStatCard(
              'Active Borrows',
              _reportData['activeBorrows'] ?? 0,
              Icons.assignment_outlined,
              AppColors.secondary,
              'Currently active',
            ),
            _buildStatCard(
              'Low Stock',
              (_reportData['lowStockItems'] as List).length,
              Icons.warning_outlined,
              AppColors.error,
              'Need attention',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, int value, IconData icon, Color color, String description) {
    return AppCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 28, color: color),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value.toString(),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildReportGeneration() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.description_outlined, color: AppColors.primary),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Generate Reports',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        
        if (_isGenerating) ...[
          AppCard(
            variant: AppCardVariant.outlined,
            child: Column(
              children: [
                const CircularProgressIndicator(color: AppColors.primary),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Generating Report...',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Please wait while we compile your data',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.1,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            children: [
              _buildReportCard(
                'Summary Report',
                'Complete system overview',
                Icons.summarize_outlined,
                AppColors.primary,
                () => _generatePDFReport('summary'),
              ),
              _buildReportCard(
                'Inventory Report',
                'Stock levels and items',
                Icons.inventory_2_outlined,
                AppColors.accent,
                () => _generatePDFReport('inventory'),
              ),
              _buildReportCard(
                'Students Report',
                'All registered users',
                Icons.people_outline,
                AppColors.info,
                () => _generatePDFReport('students'),
              ),
              _buildReportCard(
                'Borrow Records',
                'Active transactions',
                Icons.assignment_outlined,
                AppColors.secondary,
                () => _generatePDFReport('borrows'),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildReportCard(String title, String description, IconData icon, Color color, VoidCallback onTap) {
    return AppCard(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 32, color: color),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSystemInformation() {
    return AppCard(
      variant: AppCardVariant.outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'System Information',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          
          _buildInfoRow(Icons.picture_as_pdf_outlined, 'Reports are generated in PDF format'),
          const SizedBox(height: AppSpacing.sm),
          _buildInfoRow(Icons.preview_outlined, 'Preview reports before saving'),
          const SizedBox(height: AppSpacing.sm),
          _buildInfoRow(Icons.download_outlined, 'Saved to device Downloads folder'),
          const SizedBox(height: AppSpacing.sm),
          _buildInfoRow(Icons.refresh_outlined, 'Data refreshed automatically'),
          
          if (_reportData['generatedAt'] != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Row(
                children: [
                  Icon(Icons.schedule_outlined, color: AppColors.textSecondary, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Last updated: ${(_reportData['generatedAt'] as DateTime).toString().split('.')[0]}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _PDFPreviewDialog extends StatefulWidget {
  final String reportType;
  final Uint8List pdfBytes;
  final VoidCallback onSave;

  const _PDFPreviewDialog({
    required this.reportType,
    required this.pdfBytes,
    required this.onSave,
  });

  @override
  State<_PDFPreviewDialog> createState() => _PDFPreviewDialogState();
}

class _PDFPreviewDialogState extends State<_PDFPreviewDialog> {
  String? _tempFilePath;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _createTempFile();
  }

  Future<void> _createTempFile() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/temp_preview_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await tempFile.writeAsBytes(widget.pdfBytes);
      
      setState(() {
        _tempFilePath = tempFile.path;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error creating preview: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    if (_tempFilePath != null) {
      final file = File(_tempFilePath!);
      if (file.existsSync()) {
        file.deleteSync();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          title: Text('${widget.reportType.toUpperCase()} Report Preview'),
          backgroundColor: Colors.purple,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: () {
                widget.onSave();
                Navigator.of(context).pop();
              },
              tooltip: 'Save PDF',
            ),
          ],
        ),
        body: _isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading PDF preview...'),
                  ],
                ),
              )
            : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  )
                : PDFView(
                    filePath: _tempFilePath!,
                    enableSwipe: true,
                    swipeHorizontal: false,
                    autoSpacing: false,
                    pageFling: true,
                    backgroundColor: Colors.grey.shade100,
                    onError: (error) {
                      setState(() {
                        _errorMessage = 'Error displaying PDF: $error';
                      });
                    },
                  ),
        bottomNavigationBar: !_isLoading && _errorMessage == null
            ? Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                        label: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          widget.onSave();
                          Navigator.of(context).pop();
                        },
                        icon: const Icon(Icons.download),
                        label: const Text('Save to Downloads'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : null,
      ),
    );
  }
}