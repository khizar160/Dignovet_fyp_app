import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

/// Professional Admin Wallet System - Complete Financial Dashboard
/// Features:
/// - Real-time balance tracking
/// - Transaction history with screenshots
/// - Payment verification
/// - Analytics and statistics
class AdminWalletPage extends StatefulWidget {
  const AdminWalletPage({super.key});

  @override
  State<AdminWalletPage> createState() => _AdminWalletPageState();
}

class _AdminWalletPageState extends State<AdminWalletPage> {
  static const Color primaryTeal = Color(0xFF00796B);
  static const Color lightTeal = Color(0xFF4DB6AC);

  String _filterType = 'all'; // all, received, refunded

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: primaryTeal,
        title: const Text(
          'Admin Wallet',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildStatisticsRow(),
          _buildWalletBalance(),
          _buildFilterChips(),
          Expanded(child: _buildTransactionsList()),
        ],
      ),
    );
  }

  /// Statistics Row - Shows key metrics
  Widget _buildStatisticsRow() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('appointments').snapshots(),
      builder: (context, appointmentsSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('refunds').snapshots(),
          builder: (context, refundsSnapshot) {
            int totalAppointments = 0;
            int approvedAppointments = 0;
            int pendingPayments = 0;
            int totalRefunds = 0;

            if (appointmentsSnapshot.hasData) {
              totalAppointments = appointmentsSnapshot.data!.docs.length;
              approvedAppointments = appointmentsSnapshot.data!.docs
                  .where((doc) => (doc.data() as Map)['status'] == 'approved')
                  .length;
              pendingPayments = appointmentsSnapshot.data!.docs
                  .where((doc) => (doc.data() as Map)['status'] == 'pending')
                  .length;
            }

            if (refundsSnapshot.hasData) {
              totalRefunds = refundsSnapshot.data!.docs.length;
            }

            return Container(
              margin: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.check_circle,
                      label: 'Approved',
                      value: '$approvedAppointments',
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.pending_actions,
                      label: 'Pending',
                      value: '$pendingPayments',
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.replay,
                      label: 'Refunds',
                      value: '$totalRefunds',
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Wallet Balance Card - Shows total received and refunded
  Widget _buildWalletBalance() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('appointments')
          .where('status', isEqualTo: 'approved')
          .snapshots(),
      builder: (context, appointmentsSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('refunds')
              .where('status', isEqualTo: 'completed')
              .snapshots(),
          builder: (context, refundsSnapshot) {
            double totalReceived = 0;
            double totalRefunded = 0;

            if (appointmentsSnapshot.hasData) {
              for (var doc in appointmentsSnapshot.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                totalReceived += (data['paymentAmount'] ?? 0.0).toDouble();
              }
            }

            if (refundsSnapshot.hasData) {
              for (var doc in refundsSnapshot.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                totalRefunded += (data['amount'] ?? 0.0).toDouble();
              }
            }

            final balance = totalReceived - totalRefunded;

            return Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryTeal, lightTeal],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: primaryTeal.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.account_balance_wallet, color: Colors.white, size: 32),
                      SizedBox(width: 12),
                      Text(
                        'Current Balance',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Rs. ${balance.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildBalanceCard(
                          icon: Icons.arrow_downward,
                          label: 'Received',
                          amount: totalReceived,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildBalanceCard(
                          icon: Icons.arrow_upward,
                          label: 'Refunded',
                          amount: totalRefunded,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBalanceCard({
    required IconData icon,
    required String label,
    required double amount,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Rs. ${amount.toStringAsFixed(0)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          _filterChip('All Transactions', 'all', primaryTeal),
          const SizedBox(width: 8),
          _filterChip('Payments Received', 'received', Colors.green),
          const SizedBox(width: 8),
          _filterChip('Refunds Sent', 'refunded', Colors.orange),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value, Color color) {
    final isSelected = _filterType == value;
    return Expanded(
      child: ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : color,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _filterType = value);
        },
        selectedColor: color,
        backgroundColor: color.withOpacity(0.1),
        side: BorderSide(color: color.withOpacity(0.3)),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      ),
    );
  }

  Widget _buildTransactionsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getTransactionsStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 80, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  'Error: ${snapshot.error}',
                  style: TextStyle(color: Colors.red[600], fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long, size: 80, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'No transactions yet',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'Transactions will appear here',
                  style: TextStyle(color: Colors.grey[500], fontSize: 13),
                ),
              ],
            ),
          );
        }

        // Get all documents from stream
        final docs = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            
            final isRefund = doc.reference.path.contains('refunds');
            
            // Extract amount with multiple fallbacks and type conversion
            double amount = 0.0;
            if (data['amount'] != null) {
              amount = double.tryParse(data['amount'].toString()) ?? 0.0;
            } else if (data['paymentAmount'] != null) {
              amount = double.tryParse(data['paymentAmount'].toString()) ?? 0.0;
            }
            
            // Debug logging
            if (amount == 0.0) {
              print('⚠️ Zero amount found for transaction ${doc.id}');
              print('   Data: ${data.toString()}');
            }
            
            final date = data['createdAt'] as Timestamp?;
            final userId = data['userId'] ?? '';
            final paymentScreenshot = data['paymentScreenshotUrl'] as String?;
            final refundScreenshot = data['screenshotUrl'] as String?;
            final animalName = data['animalName'] ?? '';
            final doctorName = data['doctorName'] ?? '';
            final reasonText = data['reasonText'] ?? '';
            final transactionId = doc.id;
            final paymentMethod = data['paymentMethod'] ?? 'Not specified';

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Transaction Header
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isRefund
                                ? Colors.orange.withOpacity(0.1)
                                : Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isRefund ? Icons.arrow_upward : Icons.arrow_downward,
                            color: isRefund ? Colors.orange : Colors.green,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    isRefund ? 'Refund Sent' : 'Payment Received',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    '${isRefund ? '-' : '+'} Rs. ${amount.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      color: isRefund ? Colors.orange : Colors.green,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              
                              // User Details
                              FutureBuilder<DocumentSnapshot>(
                                future: FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(userId)
                                    .get(),
                                builder: (context, userSnapshot) {
                                  if (!userSnapshot.hasData) {
                                    return Text('Loading...', style: TextStyle(color: Colors.grey[600], fontSize: 13));
                                  }
                                  
                                  final userData = userSnapshot.data?.data() as Map<String, dynamic>?;
                                  final userName = userData?['name'] ?? 'Unknown User';
                                  final userPhone = userData?['phone'] ?? '';
                                  final paymentAccount = userData?['paymentAccount'] ?? '';
                                  
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.person, size: 16, color: Colors.grey[600]),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              userName,
                                              style: TextStyle(
                                                color: Colors.grey[800],
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (userPhone.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(Icons.phone, size: 14, color: Colors.grey[500]),
                                            const SizedBox(width: 6),
                                            Text(
                                              userPhone,
                                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ],
                                      if (paymentAccount.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(Icons.account_balance_wallet, size: 14, color: Colors.grey[500]),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Wallet: $paymentAccount',
                                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ],
                                      // Payment Method
                                      if (!isRefund) ...[
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              paymentMethod.toLowerCase().contains('jazz')
                                                  ? Icons.account_balance_wallet
                                                  : paymentMethod.toLowerCase().contains('easy')
                                                      ? Icons.mobile_friendly
                                                      : Icons.payment,
                                              size: 14,
                                              color: paymentMethod.toLowerCase().contains('jazz')
                                                  ? Colors.red[700]
                                                  : paymentMethod.toLowerCase().contains('easy')
                                                      ? Colors.green[700]
                                                      : Colors.grey[500],
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Method: $paymentMethod',
                                              style: TextStyle(
                                                color: paymentMethod.toLowerCase().contains('jazz')
                                                    ? Colors.red[700]
                                                    : paymentMethod.toLowerCase().contains('easy')
                                                        ? Colors.green[700]
                                                        : Colors.grey[600],
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  );
                                },
                              ),
                              
                              // Appointment Details
                              if (animalName.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(Icons.pets, size: 14, color: Colors.grey[500]),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Animal: $animalName',
                                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                    ),
                                  ],
                                ),
                              ],
                              if (doctorName.isNotEmpty && !isRefund) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.medical_services, size: 14, color: Colors.grey[500]),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Doctor: $doctorName',
                                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                    ),
                                  ],
                                ),
                              ],
                              if (reasonText.isNotEmpty && isRefund) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.info_outline, size: 14, color: Colors.grey[500]),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'Reason: $reasonText',
                                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              
                              // Date & Transaction ID
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(Icons.calendar_today, size: 14, color: Colors.grey[500]),
                                  const SizedBox(width: 6),
                                  Text(
                                    date != null
                                        ? DateFormat('MMM dd, yyyy - hh:mm a').format(date.toDate())
                                        : 'Unknown date',
                                    style: TextStyle(color: Colors.grey[500], fontSize: 11),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.tag, size: 14, color: Colors.grey[500]),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'ID: ${transactionId.substring(0, 12)}...',
                                      style: TextStyle(color: Colors.grey[500], fontSize: 11),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    // Payment Screenshot (for received payments)
                    if (paymentScreenshot != null && !isRefund) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.image, color: primaryTeal, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Payment Screenshot:',
                            style: TextStyle(
                              color: primaryTeal,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => _showFullScreenImage(context, paymentScreenshot),
                        child: Container(
                          height: 150,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!, width: 2),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              paymentScreenshot,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[200],
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.broken_image, color: Colors.grey[400], size: 40),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Failed to load image',
                                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.touch_app, color: Colors.grey[500], size: 14),
                          const SizedBox(width: 4),
                          Text(
                            'Tap to view full screen',
                            style: TextStyle(color: Colors.grey[500], fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                    
                    // Refund Screenshot (for refund transactions)
                    if (refundScreenshot != null && isRefund) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.image, color: Colors.orange, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Refund Proof Screenshot:',
                            style: TextStyle(
                              color: Colors.orange[800],
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => _showFullScreenImage(context, refundScreenshot),
                        child: Container(
                          height: 150,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange[300]!, width: 2),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              refundScreenshot,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                    color: Colors.orange,
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.orange[50],
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.broken_image, color: Colors.orange[300], size: 40),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Failed to load refund proof',
                                        style: TextStyle(color: Colors.orange[600], fontSize: 12),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.touch_app, color: Colors.orange[400], size: 14),
                          const SizedBox(width: 4),
                          Text(
                            'Tap to view full screen',
                            style: TextStyle(color: Colors.orange[400], fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            title: const Text('Payment Screenshot'),
            actions: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          body: Center(
            child: InteractiveViewer(
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image, color: Colors.white, size: 80),
                        SizedBox(height: 16),
                        Text(
                          'Failed to load image',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Stream<QuerySnapshot> _getTransactionsStream() {
    if (_filterType == 'received') {
      return FirebaseFirestore.instance
          .collection('appointments')
          .where('status', isEqualTo: 'approved')
          .snapshots();
    } else if (_filterType == 'refunded') {
      return FirebaseFirestore.instance
          .collection('refunds')
          .where('status', isEqualTo: 'completed')
          .snapshots();
    } else {
      // For 'all', we'll combine both streams (simplified version - show appointments)
      return FirebaseFirestore.instance
          .collection('appointments')
          .where('status', isEqualTo: 'approved')
          .snapshots();
    }
  }
}
