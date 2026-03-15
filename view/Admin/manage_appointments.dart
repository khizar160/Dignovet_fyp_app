import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_application_1/services/payment_service/supabase_payment_storage.dart';

class AppointmentModel {
  final String id;
  final String userId;
  final String doctorId;
  final String animalName;
  final Timestamp date;
  final String time;
  final String problem;
  final String status;
  final DateTime? createdAt;
  final String consultationType; // 'online' or 'home_visit'
  final double paymentAmount;
  final String? paymentScreenshotUrl;
  final String? paymentStatus;
  final String? declineReason; // Reason code for decline
  final String? declineReasonText; // Human-readable reason
  final bool? refundRequired; // Whether refund is needed
  final Timestamp? declinedAt; // When was it declined

  // User and Doctor details (fetched separately)
  String? userName;
  String? doctorName;
  String? userImage;
  String? doctorImage;

  AppointmentModel({
    required this.id,
    required this.userId,
    required this.doctorId,
    required this.animalName,
    required this.date,
    required this.time,
    required this.problem,
    required this.status,
    this.createdAt,
    this.consultationType = 'online',
    this.paymentAmount = 0.0,
    this.paymentScreenshotUrl,
    this.paymentStatus = 'pending',
    this.declineReason,
    this.declineReasonText,
    this.refundRequired,
    this.declinedAt,
    this.userName,
    this.doctorName,
    this.userImage,
    this.doctorImage,
  });

  factory AppointmentModel.fromMap(Map<String, dynamic> map, String id) {
    return AppointmentModel(
      id: id,
      userId: map['userId'] ?? '',
      doctorId: map['doctorId'] ?? '',
      animalName: map['animalName'] ?? '',
      date: map['date'] ?? Timestamp.now(),
      time: map['time'] ?? '',
      problem: map['problem'] ?? '',
      status: map['status'] ?? 'pending',
      consultationType: map['consultationType'] ?? 'online',
      paymentAmount: (map['paymentAmount'] ?? 0.0).toDouble(),
      paymentScreenshotUrl: map['paymentScreenshotUrl'],
      paymentStatus: map['paymentStatus'] ?? 'pending',
      declineReason: map['declineReason'],
      declineReasonText: map['declineReasonText'],
      refundRequired: map['refundRequired'],
      declinedAt: map['declinedAt'],
      createdAt: map['createdAt'] != null 
          ? (map['createdAt'] as Timestamp).toDate() 
          : null,
    );
  }
}

class ManageAppointmentsPage extends StatefulWidget {
  const ManageAppointmentsPage({super.key});

  @override
  State<ManageAppointmentsPage> createState() => _ManageAppointmentsPageState();
}

class _ManageAppointmentsPageState extends State<ManageAppointmentsPage> {
  static const Color primaryTeal = Color(0xFF00796B);
  static const Color lightTeal = Color(0xFF4DB6AC);
  static const Color darkGrey = Color(0xFF2C3E50);

  final _firestore = FirebaseFirestore.instance;
  final _searchController = TextEditingController();
  final _paymentStorage = SupabasePaymentStorage();
  
  String _searchQuery = '';
  String _filterStatus = 'all'; // all, pending, approved, declined
  bool _loading = true;
  List<AppointmentModel> _allAppointments = [];
  List<AppointmentModel> _filteredAppointments = [];
  Map<String, String> _signedUrls = {}; // Cache for signed URLs

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAppointments() async {
    setState(() => _loading = true);
    log('Loading appointments from Firebase...');

    try {
      QuerySnapshot snapshot;
      
      try {
        snapshot = await _firestore
            .collection('appointments')
            .orderBy('createdAt', descending: true)
            .get();
      } catch (e) {
        log('Trying without orderBy due to: $e');
        snapshot = await _firestore.collection('appointments').get();
      }

      List<AppointmentModel> appointments = [];
      
      for (var doc in snapshot.docs) {
        var appointment = AppointmentModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
        
        // Fetch user details
        try {
          final userDoc = await _firestore.collection('users').doc(appointment.userId).get();
          if (userDoc.exists) {
            appointment.userName = userDoc.data()?['name'] ?? 'Unknown User';
            appointment.userImage = userDoc.data()?['imageUrl'] ?? '';
          }
        } catch (e) {
          log('Error fetching user: $e');
          appointment.userName = 'Unknown User';
        }
        
        // Fetch doctor details
        try {
          final doctorDoc = await _firestore.collection('users').doc(appointment.doctorId).get();
          if (doctorDoc.exists) {
            appointment.doctorName = doctorDoc.data()?['name'] ?? 'Unknown Doctor';
            appointment.doctorImage = doctorDoc.data()?['imageUrl'] ?? '';
          }
        } catch (e) {
          log('Error fetching doctor: $e');
          appointment.doctorName = 'Unknown Doctor';
        }
        
        appointments.add(appointment);
      }

      _allAppointments = appointments;
      _applyFilters();
      
      log('✅ Successfully loaded ${_allAppointments.length} appointments');
      
    } catch (e) {
      log('❌ Load Appointments Error: $e');
      _showSnackBar('Failed to load appointments: ${e.toString()}', isError: true);
      _allAppointments = [];
      _filteredAppointments = [];
    }

    setState(() => _loading = false);
  }

  void _applyFilters() {
    setState(() {
      var filtered = _allAppointments;
      
      // Filter by status
      if (_filterStatus != 'all') {
        filtered = filtered.where((apt) => apt.status == _filterStatus).toList();
      }
      
      // Filter by search query
      if (_searchQuery.isNotEmpty) {
        filtered = filtered.where((apt) {
          return apt.animalName.toLowerCase().contains(_searchQuery) ||
                 apt.userName?.toLowerCase().contains(_searchQuery) == true ||
                 apt.doctorName?.toLowerCase().contains(_searchQuery) == true ||
                 apt.problem.toLowerCase().contains(_searchQuery);
        }).toList();
      }
      
      _filteredAppointments = filtered;
    });
  }

  void _searchAppointments(String query) {
    _searchQuery = query.toLowerCase();
    _applyFilters();
  }

  Future<void> _updateAppointmentStatus(AppointmentModel appointment, String newStatus) async {
    try {
      await _firestore.collection('appointments').doc(appointment.id).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      log('Appointment ${appointment.id} status updated to $newStatus');
      
      setState(() {
        final index = _allAppointments.indexWhere((a) => a.id == appointment.id);
        if (index != -1) {
          _allAppointments[index] = AppointmentModel(
            id: appointment.id,
            userId: appointment.userId,
            doctorId: appointment.doctorId,
            animalName: appointment.animalName,
            date: appointment.date,
            time: appointment.time,
            problem: appointment.problem,
            status: newStatus,
            createdAt: appointment.createdAt,
            consultationType: appointment.consultationType,
            paymentAmount: appointment.paymentAmount,
            paymentScreenshotUrl: appointment.paymentScreenshotUrl,
            paymentStatus: appointment.paymentStatus,
            declineReason: appointment.declineReason,
            declineReasonText: appointment.declineReasonText,
            refundRequired: appointment.refundRequired,
            declinedAt: appointment.declinedAt,
            userName: appointment.userName,
            doctorName: appointment.doctorName,
            userImage: appointment.userImage,
            doctorImage: appointment.doctorImage,
          );
        }
        _applyFilters();
      });
      
      _showSnackBar('Appointment status updated to $newStatus');
    } catch (e) {
      log('Update Status Error: $e');
      _showSnackBar('Failed to update appointment status', isError: true);
    }
  }

  void _showAppointmentDetails(AppointmentModel appointment) async {
    // Load signed URL if payment screenshot exists
    String? signedUrl;
    if (appointment.paymentScreenshotUrl != null && 
        appointment.paymentScreenshotUrl!.isNotEmpty) {
      // Check cache first
      if (_signedUrls.containsKey(appointment.id)) {
        signedUrl = _signedUrls[appointment.id];
        print('[Admin] Using cached signed URL for appointment ${appointment.id}');
      } else {
        print('[Admin] Loading signed URL for payment screenshot...');
        signedUrl = await _paymentStorage.getSignedUrlForImage(
          appointment.paymentScreenshotUrl!
        );
        _signedUrls[appointment.id] = signedUrl ?? '';
        print('[Admin] Signed URL loaded: $signedUrl');
      }
    }
    
    if (!mounted) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AppointmentDetailsSheet(
        appointment: appointment,
        signedImageUrl: signedUrl,
        onStatusUpdate: (status) => _updateAppointmentStatus(appointment, status),
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            _buildFilterChips(),
            _buildStats(),
            Expanded(
              child: _loading
                  ? Center(child: CircularProgressIndicator(color: primaryTeal))
                  : _filteredAppointments.isEmpty
                      ? _buildEmptyState()
                      : _buildAppointmentsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryTeal, lightTeal],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryTeal.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Manage Appointments',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'View and manage all appointments',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _loadAppointments,
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: TextField(
        controller: _searchController,
        onChanged: _searchAppointments,
        decoration: InputDecoration(
          hintText: 'Search by animal, user, doctor or problem...',
          prefixIcon: const Icon(Icons.search, color: primaryTeal),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _searchAppointments('');
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: primaryTeal, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 50,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        children: [
          _buildFilterChip('All', 'all'),
          const SizedBox(width: 20),
          _buildFilterChip('Pending', 'pending'),
          const SizedBox(width: 8),
          _buildFilterChip('Approved', 'approved'),
          const SizedBox(width: 8),
          _buildFilterChip('Declined', 'declined'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterStatus == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filterStatus = value;
          _applyFilters();
        });
      },
      backgroundColor: Colors.white,
      selectedColor: primaryTeal.withOpacity(0.2),
      checkmarkColor: primaryTeal,
      labelStyle: TextStyle(
        color: isSelected ? primaryTeal : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? primaryTeal : Colors.grey[300]!,
        width: isSelected ? 2 : 1,
      ),
    );
  }

  Widget _buildStats() {
    final total = _allAppointments.length;
    final pending = _allAppointments.where((a) => a.status == 'pending').length;
    final approved = _allAppointments.where((a) => a.status == 'approved').length;
    final declined = _allAppointments.where((a) => a.status == 'declined').length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          _buildStatCard('Total', total, Icons.event_note, Colors.blue),
          const SizedBox(width: 10),
          _buildStatCard('Pending', pending, Icons.schedule, Colors.orange),
          const SizedBox(width: 10),
          _buildStatCard('approved', approved, Icons.check_circle, Colors.green),
          const SizedBox(width: 10),
          _buildStatCard('declined', declined, Icons.cancel, Colors.red),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, int count, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: darkGrey,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentsList() {
    return RefreshIndicator(
      onRefresh: _loadAppointments,
      color: primaryTeal,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredAppointments.length,
        itemBuilder: (context, index) {
          final appointment = _filteredAppointments[index];
          return _buildAppointmentCard(appointment);
        },
      ),
    );
  }

  Widget _buildAppointmentCard(AppointmentModel appointment) {
    final dateTime = appointment.date.toDate();
    final formattedDate = DateFormat('MMM dd, yyyy').format(dateTime);
    
    Color statusColor;
    IconData statusIcon;
    
    switch (appointment.status) {
      case 'approved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'declined':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showAppointmentDetails(appointment),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.pets, color: primaryTeal, size: 24),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        appointment.animalName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: darkGrey,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(statusIcon, size: 14, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            appointment.status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.person_outline, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Text(
                      'User: ${appointment.userName ?? "Unknown"}',
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.medical_services_outlined, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Text(
                      'Doctor: ${appointment.doctorName ?? "Unknown"}',
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Text(
                      '$formattedDate at ${appointment.time}',
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  appointment.problem,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                // Show decline information if declined
                if (appointment.status == 'declined' && appointment.declineReasonText != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200, width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, size: 16, color: Colors.red.shade700),
                            const SizedBox(width: 6),
                            Text(
                              'Decline Reason:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade900,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          appointment.declineReasonText!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red.shade800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              appointment.refundRequired == true 
                                  ? Icons.monetization_on 
                                  : Icons.money_off,
                              size: 14,
                              color: appointment.refundRequired == true 
                                  ? Colors.green.shade700 
                                  : Colors.red.shade700,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              appointment.refundRequired == true
                                  ? 'Refund Required'
                                  : 'No Refund',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: appointment.refundRequired == true 
                                    ? Colors.green.shade700 
                                    : Colors.red.shade700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty || _filterStatus != 'all'
                ? 'No appointments found'
                : 'No appointments yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty || _filterStatus != 'all'
                ? 'Try adjusting your filters'
                : 'Appointments will appear here',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

class _AppointmentDetailsSheet extends StatelessWidget {
  final AppointmentModel appointment;
  final String? signedImageUrl; // Signed URL for payment screenshot
  final Function(String) onStatusUpdate;

  const _AppointmentDetailsSheet({
    required this.appointment,
    this.signedImageUrl,
    required this.onStatusUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final dateTime = appointment.date.toDate();
    final formattedDate = DateFormat('MMMM dd, yyyy').format(dateTime);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Appointment Details',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 24),
            _DetailRow(icon: Icons.pets, label: 'Animal Name', value: appointment.animalName),
            const SizedBox(height: 16),
            _DetailRow(icon: Icons.person, label: 'User', value: appointment.userName ?? 'Unknown'),
            const SizedBox(height: 16),
            _DetailRow(icon: Icons.medical_services, label: 'Doctor', value: appointment.doctorName ?? 'Unknown'),
            const SizedBox(height: 16),
            _DetailRow(icon: Icons.calendar_today, label: 'Date', value: formattedDate),
            const SizedBox(height: 16),
            _DetailRow(icon: Icons.access_time, label: 'Time', value: appointment.time),
            const SizedBox(height: 16),
            _DetailRow(icon: Icons.description, label: 'Problem', value: appointment.problem),
            const SizedBox(height: 16),
            _DetailRow(icon: Icons.info, label: 'Status', value: appointment.status.toUpperCase()),
            const SizedBox(height: 16),
            _DetailRow(
              icon: Icons.attach_money, 
              label: 'Payment Amount', 
              value: 'Rs. ${appointment.paymentAmount.toStringAsFixed(0)}'
            ),
            const SizedBox(height: 16),
            _DetailRow(
              icon: Icons.payment, 
              label: 'Consultation Type', 
              value: appointment.consultationType == 'online' ? 'Online Consultation' : 'Home Visit'
            ),
            
            // Show decline information if appointment is declined
            if (appointment.status == 'declined') ...[
              const SizedBox(height: 20),
              const Divider(thickness: 2),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200, width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.cancel_outlined, color: Colors.red.shade700, size: 28),
                        const SizedBox(width: 12),
                        const Text(
                          'Appointment Declined',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _DetailRow(
                      icon: Icons.report_problem,
                      label: 'Decline Reason',
                      value: appointment.declineReasonText ?? 'Not specified',
                    ),
                    const SizedBox(height: 12),
                    _DetailRow(
                      icon: Icons.access_time,
                      label: 'Declined At',
                      value: appointment.declinedAt != null
                          ? DateFormat('MMM dd, yyyy - hh:mm a').format(appointment.declinedAt!.toDate())
                          : 'N/A',
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          appointment.refundRequired == true 
                              ? Icons.monetization_on 
                              : Icons.money_off,
                          size: 20,
                          color: appointment.refundRequired == true 
                              ? Colors.green.shade700 
                              : Colors.red.shade700,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Refund Status: ',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: appointment.refundRequired == true
                                  ? Colors.green.shade100
                                  : Colors.red.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: appointment.refundRequired == true
                                    ? Colors.green.shade700
                                    : Colors.red.shade700,
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              appointment.refundRequired == true
                                  ? '✓ FULL REFUND REQUIRED'
                                  : '✗ NO REFUND',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: appointment.refundRequired == true
                                    ? Colors.green.shade900
                                    : Colors.red.shade900,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (appointment.refundRequired == true) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Admin needs to process refund of Rs. ${appointment.paymentAmount.toStringAsFixed(0)} manually via JazzCash/EasyPaisa.',
                                style: TextStyle(
                                  color: Colors.orange.shade900,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            
            if (signedImageUrl != null && signedImageUrl!.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 20),
              const Text(
                'Payment Screenshot',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => _showFullScreenImage(context, signedImageUrl!),
                child: Container(
                  height: 250,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF00796B).withOpacity(0.3), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00796B).withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          signedImageUrl!,
                          fit: BoxFit.cover,
                          headers: const {
                            'Cache-Control': 'no-cache',
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) {
                              print('[Admin-Screenshot] ✅ Image loaded successfully');
                              return child;
                            }
                            final progress = loadingProgress.expectedTotalBytes != null
                                ? (loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes! * 100).toStringAsFixed(0)
                                : 'Loading';
                            print('[Admin-Screenshot] Loading: $progress%');
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                    color: const Color(0xFF00796B),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Loading... $progress%',
                                    style: TextStyle(color: Colors.grey[600], fontSize: 11),
                                  ),
                                ],
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            print('[Admin-Screenshot] ❌ ERROR: $error');
                            print('[Admin-Screenshot] URL: $signedImageUrl');
                            return Container(
                              color: Colors.red.shade50,
                              child: Center(
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.error_outline, size: 50, color: Colors.red[400]),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Failed to Load Image',
                                        style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        error.toString(),
                                        style: TextStyle(color: Colors.grey[700], fontSize: 10),
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        Positioned(
                          bottom: 10,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.zoom_in, color: Colors.white, size: 18),
                                SizedBox(width: 4),
                                Text(
                                  'Tap to view full size',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            const Text(
              'Update Status',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: appointment.status != 'approved'
                        ? () {
                            onStatusUpdate('approved');
                            Navigator.pop(context);
                          }
                        : null,
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Confirm'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: appointment.status != 'declined'
                        ? () {
                            onStatusUpdate('declined');
                            Navigator.pop(context);
                          }
                        : null,
                    icon: const Icon(Icons.cancel),
                    label: const Text('Cancel'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
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

  static void _showFullScreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  headers: const {
                    'Cache-Control': 'no-cache',
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                        color: Colors.white,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    print('[Admin-FullScreen] Error: $error');
                    print('[Admin-FullScreen] URL: $imageUrl');
                    return Container(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 60, color: Colors.white),
                          const SizedBox(height: 16),
                          const Text(
                            'Failed to load image',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'URL: ${imageUrl.length > 50 ? imageUrl.substring(0, 50) + "..." : imageUrl}',
                            style: const TextStyle(color: Colors.white70, fontSize: 10),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            Positioned(
              top: 20,
              right: 20,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF00796B).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF00796B), size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}