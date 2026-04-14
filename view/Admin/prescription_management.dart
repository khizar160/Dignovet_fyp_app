import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminPrescriptionManagementPage extends StatefulWidget {
  const AdminPrescriptionManagementPage({super.key});

  @override
  State<AdminPrescriptionManagementPage> createState() =>
      _AdminPrescriptionManagementPageState();
}

class _AdminPrescriptionManagementPageState
    extends State<AdminPrescriptionManagementPage> {
  static const Color primaryTeal = Color(0xFF00796B);
  static const Color lightTeal = Color(0xFF4DB6AC);
  static const Color darkGrey = Color(0xFF2C3E50);

  final TextEditingController _searchController = TextEditingController();
  int _rowsPerPage = 20;
  int _currentPage = 1;
  String _statusFilter = 'all';
  String _sortBy = 'latest';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: const Text('Prescription Management'),
        backgroundColor: primaryTeal,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('prescriptions').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allDocs = snapshot.data?.docs ?? [];
          final filtered = _applyFilters(allDocs);
          final totalPages = filtered.isEmpty
              ? 1
              : (filtered.length / _rowsPerPage).ceil();
          final safePage = _currentPage.clamp(1, totalPages);
          final start = (safePage - 1) * _rowsPerPage;
          final end = (start + _rowsPerPage) > filtered.length
              ? filtered.length
              : start + _rowsPerPage;
          final pageDocs = filtered.sublist(start, end);

          return Column(
            children: [
              _buildFiltersBar(filtered.length),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(14),
                  itemCount: pageDocs.length,
                  itemBuilder: (context, index) {
                    final data = pageDocs[index].data() as Map<String, dynamic>;
                    return _buildPrescriptionTile(pageDocs[index].id, data);
                  },
                ),
              ),
              _buildPagination(totalPages, filtered.length, pageDocs),
            ],
          );
        },
      ),
    );
  }

  List<QueryDocumentSnapshot> _applyFilters(List<QueryDocumentSnapshot> docs) {
    final query = _searchController.text.trim().toLowerCase();

    final list = docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final owner = (data['patientName'] ?? '').toString().toLowerCase();
      final doctor = (data['doctorName'] ?? '').toString().toLowerCase();
      final appointmentId = (data['appointmentId'] ?? '').toString().toLowerCase();
      final animal = (data['animalName'] ?? '').toString().toLowerCase();
      final rawDownloads = data['downloadCount'] ?? 0;
      final downloadCount = rawDownloads is int
          ? rawDownloads
          : int.tryParse(rawDownloads.toString()) ?? 0;

      final normalizedStatus = downloadCount > 0 ? 'downloaded' : 'sent';
      final statusMatch = _statusFilter == 'all' || normalizedStatus == _statusFilter;
      final searchMatch = query.isEmpty ||
          owner.contains(query) ||
          doctor.contains(query) ||
          appointmentId.contains(query) ||
          animal.contains(query);

      return statusMatch && searchMatch;
    }).toList();

    list.sort((a, b) {
      final aData = a.data() as Map<String, dynamic>;
      final bData = b.data() as Map<String, dynamic>;

      if (_sortBy == 'most_downloaded') {
        final aRaw = aData['downloadCount'] ?? 0;
        final bRaw = bData['downloadCount'] ?? 0;
        final aCount = aRaw is int ? aRaw : int.tryParse(aRaw.toString()) ?? 0;
        final bCount = bRaw is int ? bRaw : int.tryParse(bRaw.toString()) ?? 0;
        if (aCount != bCount) return bCount.compareTo(aCount);
      }

      final aTs = aData['createdAt'];
      final bTs = bData['createdAt'];
      final aDate = aTs is Timestamp
          ? aTs.toDate()
          : DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = bTs is Timestamp
          ? bTs.toDate()
          : DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });

    return list;
  }

  Widget _buildFiltersBar(int totalFiltered) {
    return Container(
      margin: const EdgeInsets.all(14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() => _currentPage = 1),
                  decoration: InputDecoration(
                    hintText: 'Search doctor / owner / appointment / pet',
                    prefixIcon: const Icon(Icons.search_rounded),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SizedBox(
                width: 220,
                child: DropdownButtonFormField<String>(
                  value: _statusFilter,
                  isDense: true,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All')),
                    DropdownMenuItem(value: 'sent', child: Text('Sent')),
                    DropdownMenuItem(value: 'downloaded', child: Text('Downloaded')),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() {
                      _statusFilter = v;
                      _currentPage = 1;
                    });
                  },
                ),
              ),
              SizedBox(
                width: 220,
                child: DropdownButtonFormField<String>(
                  value: _sortBy,
                  isDense: true,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Sort',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'latest', child: Text('Latest')),
                    DropdownMenuItem(value: 'most_downloaded', child: Text('Most Downloads')),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() {
                      _sortBy = v;
                      _currentPage = 1;
                    });
                  },
                ),
              ),
              SizedBox(
                width: 140,
                child: DropdownButtonFormField<int>(
                  value: _rowsPerPage,
                  isDense: true,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Rows',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 10, child: Text('10')),
                    DropdownMenuItem(value: 20, child: Text('20')),
                    DropdownMenuItem(value: 50, child: Text('50')),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() {
                      _rowsPerPage = v;
                      _currentPage = 1;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Total records: $totalFiltered',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: darkGrey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrescriptionTile(String id, Map<String, dynamic> data) {
    final ts = data['createdAt'];
    final dateText = ts is Timestamp
        ? DateFormat('dd MMM yyyy, hh:mm a').format(ts.toDate())
        : 'Unknown date';
    final owner = (data['patientName'] ?? 'Pet Owner').toString();
    final doctor = (data['doctorName'] ?? 'Doctor').toString();
    final animal = (data['animalName'] ?? '').toString();
    final appointmentId = (data['appointmentId'] ?? '').toString();
    final pdfUrl = (data['pdfUrl'] ?? '').toString();
    final rawDownloads = data['downloadCount'] ?? 0;
    final downloadCount = rawDownloads is int
        ? rawDownloads
        : int.tryParse(rawDownloads.toString()) ?? 0;
    final followUpText = _normalizeFollowUpText((data['followUp'] ?? '').toString());
    final summary = (data['summary'] ?? '').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: lightTeal.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryTeal.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.receipt_long_rounded, color: primaryTeal, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '$owner ${animal.isEmpty ? '' : '• $animal'}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: darkGrey,
                    fontSize: 15,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: downloadCount > 0
                      ? Colors.green.withOpacity(0.12)
                      : Colors.orange.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  downloadCount > 0 ? 'Downloaded' : 'Sent',
                  style: TextStyle(
                    color: downloadCount > 0 ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildMetaChip(Icons.person_outline_rounded, 'Doctor: $doctor'),
              _buildMetaChip(
                Icons.confirmation_number_outlined,
                'Appointment: ${appointmentId.isEmpty ? 'Not linked' : appointmentId}',
              ),
              _buildMetaChip(Icons.download_rounded, 'Downloads: $downloadCount'),
              if (followUpText.isNotEmpty)
                _buildMetaChip(Icons.event_repeat_rounded, 'Follow-up: $followUpText'),
              _buildMetaChip(Icons.schedule_rounded, 'Created: $dateText'),
            ],
          ),
          if (summary.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF7FAFB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.withOpacity(0.18)),
              ),
              child: Text(
                summary,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 12.5),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: pdfUrl.isEmpty ? null : () => _openPdfUrl(pdfUrl),
                icon: const Icon(Icons.open_in_new_rounded, size: 17),
                label: const Text('Open PDF'),
              ),
              OutlinedButton.icon(
                onPressed: () => _exportSinglePrescriptionCsv(id, data),
                icon: const Icon(Icons.table_view_rounded, size: 17),
                label: const Text('Export CSV'),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryTeal,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => _exportSinglePrescriptionPdf(id, data),
                icon: const Icon(Icons.picture_as_pdf_rounded, size: 17),
                label: const Text('Export PDF'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetaChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.09),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: darkGrey.withOpacity(0.8)),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              color: darkGrey.withOpacity(0.85),
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _normalizeFollowUpText(String raw) {
    final value = raw.trim();
    if (value.isEmpty || value.toLowerCase() == 'n/a') return '';
    if (RegExp(r'^\d+$').hasMatch(value)) {
      return '$value days';
    }
    return value;
  }

  Widget _buildPagination(
    int totalPages,
    int totalRecords,
    List<QueryDocumentSnapshot> pageDocs,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _currentPage > 1
                      ? () => setState(() => _currentPage--)
                      : null,
                  icon: const Icon(Icons.chevron_left_rounded),
                  label: const Text('Previous'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _currentPage < totalPages
                      ? () => setState(() => _currentPage++)
                      : null,
                  icon: const Icon(Icons.chevron_right_rounded),
                  label: const Text('Next'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Page $_currentPage of $totalPages',
                  style: const TextStyle(fontWeight: FontWeight.w700, color: darkGrey),
                ),
              ),
              TextButton.icon(
                onPressed: pageDocs.isEmpty ? null : () => _exportCsv(pageDocs),
                icon: const Icon(Icons.table_chart_rounded, size: 18),
                label: const Text('Export CSV'),
              ),
              TextButton.icon(
                onPressed: pageDocs.isEmpty ? null : () => _exportPdf(pageDocs),
                icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                label: const Text('Export PDF'),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Records in page: ${pageDocs.length} / Total: $totalRecords',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportCsv(List<QueryDocumentSnapshot> pageDocs) async {
    final buffer = StringBuffer();
    buffer.writeln(
      'PrescriptionId,DoctorName,PatientName,AnimalName,AppointmentId,Status,DownloadCount,CreatedAt,PdfUrl',
    );

    for (final doc in pageDocs) {
      final data = doc.data() as Map<String, dynamic>;
      final status = ((data['downloadCount'] ?? 0) is int && (data['downloadCount'] ?? 0) > 0)
          ? 'downloaded'
          : 'sent';
      final createdAt = data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate().toIso8601String()
          : '';

      String cell(dynamic value) {
        final text = (value ?? '').toString().replaceAll('"', '""');
        return '"$text"';
      }

      buffer.writeln([
        cell(doc.id),
        cell(data['doctorName']),
        cell(data['patientName']),
        cell(data['animalName']),
        cell(data['appointmentId']),
        cell(status),
        cell(data['downloadCount'] ?? 0),
        cell(createdAt),
        cell(data['pdfUrl']),
      ].join(','));
    }

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/prescriptions_page_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(buffer.toString(), flush: true);

    await Share.shareXFiles([XFile(file.path)], text: 'Prescription CSV Export');
  }

  Future<void> _exportPdf(List<QueryDocumentSnapshot> pageDocs) async {
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (_) {
          return [
            pw.Text(
              'Prescription Management Export',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headers: const ['Doctor', 'Pet Owner', 'Pet', 'Appt', 'Downloads'],
              data: pageDocs.map((d) {
                final data = d.data() as Map<String, dynamic>;
                return [
                  (data['doctorName'] ?? '').toString(),
                  (data['patientName'] ?? '').toString(),
                  (data['animalName'] ?? '').toString(),
                  (data['appointmentId'] ?? '').toString(),
                  (data['downloadCount'] ?? 0).toString(),
                ];
              }).toList(),
            ),
          ];
        },
      ),
    );

    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: 'prescriptions_export_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  Future<void> _openPdfUrl(String pdfUrl) async {
    final uri = Uri.tryParse(pdfUrl);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _exportSinglePrescriptionCsv(String id, Map<String, dynamic> data) async {
    final createdAt = data['createdAt'] is Timestamp
        ? (data['createdAt'] as Timestamp).toDate().toIso8601String()
        : '';
    final rawDownloads = data['downloadCount'] ?? 0;
    final downloadCount = rawDownloads is int
        ? rawDownloads
        : int.tryParse(rawDownloads.toString()) ?? 0;
    final status = downloadCount > 0 ? 'downloaded' : 'sent';

    String cell(dynamic value) {
      final text = (value ?? '').toString().replaceAll('"', '""');
      return '"$text"';
    }

    final buffer = StringBuffer();
    buffer.writeln(
      'PrescriptionId,DoctorName,PatientName,AnimalName,AppointmentId,Status,DownloadCount,FollowUp,CreatedAt,PdfUrl',
    );
    buffer.writeln([
      cell(id),
      cell(data['doctorName']),
      cell(data['patientName']),
      cell(data['animalName']),
      cell(data['appointmentId']),
      cell(status),
      cell(downloadCount),
      cell(data['followUp']),
      cell(createdAt),
      cell(data['pdfUrl']),
    ].join(','));

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/prescription_$id.csv');
    await file.writeAsString(buffer.toString(), flush: true);
    await Share.shareXFiles([XFile(file.path)], text: 'Prescription $id CSV Export');
  }

  Future<void> _exportSinglePrescriptionPdf(String id, Map<String, dynamic> data) async {
    final doc = pw.Document();
    final createdAt = data['createdAt'] is Timestamp
        ? DateFormat('dd MMM yyyy, hh:mm a').format((data['createdAt'] as Timestamp).toDate())
        : 'Unknown';

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (_) {
          pw.Widget line(String label, dynamic value) {
            return pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 6),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.SizedBox(
                    width: 120,
                    child: pw.Text(
                      '$label:',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  pw.Expanded(child: pw.Text((value ?? '').toString())),
                ],
              ),
            );
          }

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Prescription Export',
                style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 14),
              line('Prescription ID', id),
              line('Doctor', data['doctorName']),
              line('Pet Owner', data['patientName']),
              line('Pet', data['animalName']),
              line('Appointment', data['appointmentId']),
              line('Follow-up', data['followUp']),
              line('Downloads', data['downloadCount'] ?? 0),
              line('Created', createdAt),
              line('Summary', data['summary']),
              line('PDF URL', data['pdfUrl']),
            ],
          );
        },
      ),
    );

    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: 'prescription_$id.pdf',
    );
  }
}
