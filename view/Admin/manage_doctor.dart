import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Doctor {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String specialization;
  final String imageUrl;
  final bool online;
  final bool isBlocked;
  final DateTime? createdAt;

  Doctor({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.specialization,
    required this.imageUrl,
    required this.online,
    required this.isBlocked,
    this.createdAt,
  });

  factory Doctor.fromMap(Map<String, dynamic> map, String id) {
    return Doctor(
      id: id,
      name: map['name'] ?? 'Unknown',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      specialization: map['specialization'] ?? 'General',
      imageUrl: map['imageUrl'] ?? '',
      online: map['online'] ?? false,
      isBlocked: map['isBlocked'] ?? false,
      createdAt: map['createdAt'] != null 
          ? (map['createdAt'] as Timestamp).toDate() 
          : null,
    );
  }
}

class ManageDoctorsPage extends StatefulWidget {
  const ManageDoctorsPage({super.key});

  @override
  State<ManageDoctorsPage> createState() => _ManageDoctorsPageState();
}

class _ManageDoctorsPageState extends State<ManageDoctorsPage> {
  static const Color primaryTeal = Color(0xFF00796B);
  static const Color lightTeal = Color(0xFF4DB6AC);
  static const Color cardGrey = Color(0xFFF8F9FA);
  static const Color darkGrey = Color(0xFF2C3E50);

  final _firestore = FirebaseFirestore.instance;
  final _searchController = TextEditingController();
  
  String _searchQuery = '';
  bool _loading = true;
  List<Doctor> _allDoctors = [];
  List<Doctor> _filteredDoctors = [];

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDoctors() async {
    setState(() => _loading = true);
    log('Loading doctors from Firebase...');

    try {
      QuerySnapshot snapshot;
      
      try {
        snapshot = await _firestore
            .collection('users')
            .where('role', isEqualTo: 'doctor')
            .orderBy('createdAt', descending: true)
            .get();
      } catch (e) {
        log('Trying without orderBy due to: $e');
        snapshot = await _firestore
            .collection('users')
            .where('role', isEqualTo: 'doctor')
            .get();
      }

      _allDoctors = snapshot.docs
          .map((doc) => Doctor.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      
      _allDoctors.sort((a, b) {
        if (a.createdAt == null && b.createdAt == null) return 0;
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });
      
      _filteredDoctors = _allDoctors;
      log('✅ Successfully loaded ${_allDoctors.length} doctors');
      
    } catch (e) {
      log('❌ Load Doctors Error: $e');
      _showSnackBar('Failed to load doctors: ${e.toString()}', isError: true);
      _allDoctors = [];
      _filteredDoctors = [];
    }

    setState(() => _loading = false);
  }

  void _searchDoctors(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      if (_searchQuery.isEmpty) {
        _filteredDoctors = _allDoctors;
      } else {
        _filteredDoctors = _allDoctors.where((doctor) {
          return doctor.name.toLowerCase().contains(_searchQuery) ||
                 doctor.email.toLowerCase().contains(_searchQuery) ||
                 doctor.specialization.toLowerCase().contains(_searchQuery);
        }).toList();
      }
    });
  }

  Future<void> _toggleBlockDoctor(Doctor doctor) async {
    final shouldBlock = !doctor.isBlocked;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(shouldBlock ? 'Block Doctor?' : 'Unblock Doctor?'),
        content: Text(
          shouldBlock
              ? 'This doctor will not be able to login anymore.'
              : 'This doctor will be able to login again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: shouldBlock ? Colors.red : Colors.green,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(shouldBlock ? 'Block' : 'Unblock'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _firestore.collection('users').doc(doctor.id).update({
        'isBlocked': shouldBlock,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      log('Doctor ${doctor.name} ${shouldBlock ? "blocked" : "unblocked"}');
      
      setState(() {
        final index = _allDoctors.indexWhere((d) => d.id == doctor.id);
        if (index != -1) {
          _allDoctors[index] = Doctor(
            id: doctor.id,
            name: doctor.name,
            email: doctor.email,
            phone: doctor.phone,
            specialization: doctor.specialization,
            imageUrl: doctor.imageUrl,
            online: doctor.online,
            isBlocked: shouldBlock,
            createdAt: doctor.createdAt,
          );
        }
        
        final filteredIndex = _filteredDoctors.indexWhere((d) => d.id == doctor.id);
        if (filteredIndex != -1) {
          _filteredDoctors[filteredIndex] = _allDoctors[index];
        }
      });
      
      _showSnackBar(
        shouldBlock ? 'Doctor blocked successfully' : 'Doctor unblocked successfully',
      );
    } catch (e) {
      log('Toggle Block Error: $e');
      _showSnackBar('Failed to update doctor status', isError: true);
    }
  }

  void _showDoctorDetails(Doctor doctor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DoctorDetailsSheet(doctor: doctor),
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
            _buildStats(),
            Expanded(
              child: _loading
                  ? Center(child: CircularProgressIndicator(color: primaryTeal))
                  : _filteredDoctors.isEmpty
                      ? _buildEmptyState()
                      : _buildDoctorsList(),
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
                  'Manage Doctors',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'View and manage doctor accounts',
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
            onPressed: _loadDoctors,
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        onChanged: _searchDoctors,
        decoration: InputDecoration(
          hintText: 'Search doctors by name, email or specialization...',
          prefixIcon: const Icon(Icons.search, color: primaryTeal),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _searchDoctors('');
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

  Widget _buildStats() {
    final totalDoctors = _allDoctors.length;
    final activeDoctors = _allDoctors.where((d) => !d.isBlocked).length;
    final blockedDoctors = _allDoctors.where((d) => d.isBlocked).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          _buildStatCard('Total', totalDoctors, Icons.medical_services, Colors.blue),
          const SizedBox(width: 12),
          _buildStatCard('Active', activeDoctors, Icons.check_circle, Colors.green),
          const SizedBox(width: 12),
          _buildStatCard('Blocked', blockedDoctors, Icons.block, Colors.red),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, int count, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: darkGrey,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorsList() {
    return RefreshIndicator(
      onRefresh: _loadDoctors,
      color: primaryTeal,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredDoctors.length,
        itemBuilder: (context, index) {
          final doctor = _filteredDoctors[index];
          return _buildDoctorCard(doctor);
        },
      ),
    );
  }

  Widget _buildDoctorCard(Doctor doctor) {
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
          onTap: () => _showDoctorDetails(doctor),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: cardGrey,
                      backgroundImage: doctor.imageUrl.isNotEmpty
                          ? NetworkImage(doctor.imageUrl)
                          : null,
                      child: doctor.imageUrl.isEmpty
                          ? Icon(Icons.person, size: 30, color: Colors.grey[400])
                          : null,
                    ),
                    if (doctor.online)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              doctor.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: darkGrey,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (doctor.isBlocked)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'BLOCKED',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.medical_services, size: 14, color: Colors.blue[600]),
                          const SizedBox(width: 4),
                          Text(
                            doctor.specialization,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blue[600],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        doctor.email,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _toggleBlockDoctor(doctor),
                  icon: Icon(
                    doctor.isBlocked ? Icons.lock_open : Icons.block,
                    color: doctor.isBlocked ? Colors.green : Colors.red,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: doctor.isBlocked
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                  ),
                ),
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
          Icon(Icons.medical_services_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty ? 'No doctors found' : 'No doctors yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try a different search term'
                : 'Doctors will appear here',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

class _DoctorDetailsSheet extends StatelessWidget {
  final Doctor doctor;

  const _DoctorDetailsSheet({required this.doctor});

  @override
  Widget build(BuildContext context) {
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
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: const Color(0xFFF8F9FA),
                    backgroundImage: doctor.imageUrl.isNotEmpty
                        ? NetworkImage(doctor.imageUrl)
                        : null,
                    child: doctor.imageUrl.isEmpty
                        ? Icon(Icons.person, size: 50, color: Colors.grey[400])
                        : null,
                  ),
                  if (doctor.online)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                doctor.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: doctor.isBlocked
                      ? Colors.red.withOpacity(0.1)
                      : Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  doctor.isBlocked ? 'BLOCKED' : 'ACTIVE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: doctor.isBlocked ? Colors.red : Colors.green,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            _DetailRow(
              icon: Icons.medical_services,
              label: 'Specialization',
              value: doctor.specialization,
            ),
            const SizedBox(height: 16),
            _DetailRow(icon: Icons.email, label: 'Email', value: doctor.email),
            const SizedBox(height: 16),
            _DetailRow(
              icon: Icons.phone,
              label: 'Phone',
              value: doctor.phone.isNotEmpty ? doctor.phone : 'Not provided',
            ),
            const SizedBox(height: 16),
            _DetailRow(
              icon: Icons.calendar_today,
              label: 'Joined',
              value: doctor.createdAt != null
                  ? '${doctor.createdAt!.day}/${doctor.createdAt!.month}/${doctor.createdAt!.year}'
                  : 'N/A',
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