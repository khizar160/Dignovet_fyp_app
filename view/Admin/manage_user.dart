import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AppUser {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String imageUrl;
  final bool online;
  final bool isBlocked;
  final DateTime? createdAt;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.imageUrl,
    required this.online,
    required this.isBlocked,
    this.createdAt,
  });

  factory AppUser.fromMap(Map<String, dynamic> map, String id) {
    return AppUser(
      id: id,
      name: map['name'] ?? 'Unknown',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      role: map['role'] ?? 'user',
      imageUrl: map['imageUrl'] ?? '',
      online: map['online'] ?? false,
      isBlocked: map['isBlocked'] ?? false,
      createdAt: map['createdAt'] != null 
          ? (map['createdAt'] as Timestamp).toDate() 
          : null,
    );
  }

  get specialization => null;
}

class ManageUsersPage extends StatefulWidget {
  const ManageUsersPage({super.key});

  @override
  State<ManageUsersPage> createState() => _ManageUsersPageState();
}

class _ManageUsersPageState extends State<ManageUsersPage> {
  // Professional Colors
  static const Color primaryTeal = Color(0xFF00796B);
  static const Color lightTeal = Color(0xFF4DB6AC);
  static const Color cardGrey = Color(0xFFF8F9FA);
  static const Color darkGrey = Color(0xFF2C3E50);

  final _firestore = FirebaseFirestore.instance;
  final _searchController = TextEditingController();
  
  String _searchQuery = '';
  bool _loading = true;
  List<AppUser> _allUsers = [];
  List<AppUser> _filteredUsers = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Load all users with role 'user'
  Future<void> _loadUsers() async {
    setState(() => _loading = true);
    log('Loading users from Firebase...');

    try {
      // First check if we need to create index
      QuerySnapshot snapshot;
      
      try {
        // Try with orderBy first
        snapshot = await _firestore
            .collection('users')
            .where('role', isEqualTo: 'user')
            .orderBy('createdAt', descending: true)
            .get();
      } catch (e) {
        // If index error, fallback to without orderBy
        log('Trying without orderBy due to: $e');
        snapshot = await _firestore
            .collection('users')
            .where('role', isEqualTo: 'user')
            .get();
      }

      _allUsers = snapshot.docs
          .map((doc) => AppUser.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      
      // Sort manually if no orderBy was used
      _allUsers.sort((a, b) {
        if (a.createdAt == null && b.createdAt == null) return 0;
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });
      
      _filteredUsers = _allUsers;
      log('✅ Successfully loaded ${_allUsers.length} users from Firebase');
      
      if (_allUsers.isEmpty) {
        log('⚠️ No users found with role "user"');
      }
    } catch (e) {
      log('❌ Load Users Error: $e');
      _showSnackBar('Failed to load users: ${e.toString()}', isError: true);
      
      // Set empty list on error
      _allUsers = [];
      _filteredUsers = [];
    }

    setState(() => _loading = false);
  }

  /// Search users by name or email
  void _searchUsers(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      if (_searchQuery.isEmpty) {
        _filteredUsers = _allUsers;
      } else {
        _filteredUsers = _allUsers.where((user) {
          return user.name.toLowerCase().contains(_searchQuery) ||
                 user.email.toLowerCase().contains(_searchQuery);
        }).toList();
      }
    });
  }

  /// Toggle block/unblock user
  Future<void> _toggleBlockUser(AppUser user) async {
    final shouldBlock = !user.isBlocked;
    
    // Confirm dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(shouldBlock ? 'Block User?' : 'Unblock User?'),
        content: Text(
          shouldBlock
              ? 'This user will not be able to login anymore.'
              : 'This user will be able to login again.',
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(shouldBlock ? 'Block' : 'Unblock'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _firestore.collection('users').doc(user.id).update({
        'isBlocked': shouldBlock,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      log('User ${user.name} ${shouldBlock ? "blocked" : "unblocked"}');
      _showSnackBar(
        shouldBlock ? 'User blocked successfully' : 'User unblocked successfully',
      );
      
      await _loadUsers(); // Reload users
    } catch (e) {
      log('Toggle Block Error: $e');
      _showSnackBar('Failed to update user status', isError: true);
    }
  }

  /// Show user details
  void _showUserDetails(AppUser user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _UserDetailsSheet(user: user),
    );
  }

  /// Show SnackBar
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
                  ? Center(
                      child: CircularProgressIndicator(color: primaryTeal),
                    )
                  : _filteredUsers.isEmpty
                      ? _buildEmptyState()
                      : _buildUsersList(),
            ),
          ],
        ),
      ),
    );
  }

  /// Header
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
                  'Manage Users',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'View and manage user accounts',
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
            onPressed: _loadUsers,
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }

  /// Search Bar
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        onChanged: _searchUsers,
        decoration: InputDecoration(
          hintText: 'Search users by name or email...',
          prefixIcon: const Icon(Icons.search, color: primaryTeal),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _searchUsers('');
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

  /// Stats Bar
  Widget _buildStats() {
    final totalUsers = _allUsers.length;
    final activeUsers = _allUsers.where((u) => !u.isBlocked).length;
    final blockedUsers = _allUsers.where((u) => u.isBlocked).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          _buildStatCard('Total', totalUsers, Icons.people, Colors.blue),
          const SizedBox(width: 12),
          _buildStatCard('Active', activeUsers, Icons.check_circle, Colors.green),
          const SizedBox(width: 12),
          _buildStatCard('Blocked', blockedUsers, Icons.block, Colors.red),
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

  /// Users List
  Widget _buildUsersList() {
    return RefreshIndicator(
      onRefresh: _loadUsers,
      color: primaryTeal,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredUsers.length,
        itemBuilder: (context, index) {
          final user = _filteredUsers[index];
          return _buildUserCard(user);
        },
      ),
    );
  }

  /// User Card
  Widget _buildUserCard(AppUser user) {
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
          onTap: () => _showUserDetails(user),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Profile Image
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: cardGrey,
                      backgroundImage: user.imageUrl.isNotEmpty
                          ? NetworkImage(user.imageUrl)
                          : null,
                      child: user.imageUrl.isEmpty
                          ? Icon(Icons.person, size: 30, color: Colors.grey[400])
                          : null,
                    ),
                    if (user.online)
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
                // User Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              user.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: darkGrey,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (user.isBlocked)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
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
                      Text(
                        user.email,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (user.phone.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            user.phone,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Block/Unblock Button
                IconButton(
                  onPressed: () => _toggleBlockUser(user),
                  icon: Icon(
                    user.isBlocked ? Icons.lock_open : Icons.block,
                    color: user.isBlocked ? Colors.green : Colors.red,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: user.isBlocked
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

  /// Empty State
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_off_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty ? 'No users found' : 'No users yet',
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
                : 'Users will appear here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}

/// User Details Bottom Sheet
class _UserDetailsSheet extends StatelessWidget {
  final AppUser user;

  const _UserDetailsSheet({required this.user});

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
            // Handle Bar
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
            // Profile Image
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: const Color(0xFFF8F9FA),
                    backgroundImage: user.imageUrl.isNotEmpty
                        ? NetworkImage(user.imageUrl)
                        : null,
                    child: user.imageUrl.isEmpty
                        ? Icon(Icons.person, size: 50, color: Colors.grey[400])
                        : null,
                  ),
                  if (user.online)
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
            // Name
            Center(
              child: Text(
                user.name,
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
                  color: user.isBlocked
                      ? Colors.red.withOpacity(0.1)
                      : Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  user.isBlocked ? 'BLOCKED' : 'ACTIVE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: user.isBlocked ? Colors.red : Colors.green,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            // Details
            _DetailRow(icon: Icons.email, label: 'Email', value: user.email),
            const SizedBox(height: 16),
            _DetailRow(icon: Icons.phone, label: 'Phone', value: user.phone.isNotEmpty ? user.phone : 'Not provided'),
            const SizedBox(height: 16),
            _DetailRow(icon: Icons.badge, label: 'Role', value: user.role.toUpperCase()),
            const SizedBox(height: 16),
            _DetailRow(
              icon: Icons.calendar_today,
              label: 'Joined',
              value: user.createdAt != null
                  ? '${user.createdAt!.day}/${user.createdAt!.month}/${user.createdAt!.year}'
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