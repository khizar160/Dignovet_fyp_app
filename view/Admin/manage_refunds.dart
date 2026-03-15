import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/services/notification%20service/notification_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter_application_1/services/payment_service/supabase_payment_storage.dart';

class ManageRefundsPage extends StatefulWidget {
  const ManageRefundsPage({super.key});

  @override
  State<ManageRefundsPage> createState() => _ManageRefundsPageState();
}

class _ManageRefundsPageState extends State<ManageRefundsPage> {
  static const Color primaryTeal = Color(0xFF00796B);
  static const Color lightTeal = Color(0xFF4DB6AC);
  
  final _notificationService = NotificationService();
  final _paymentStorage = SupabasePaymentStorage();
  final _imagePicker = ImagePicker();
  String _filterStatus = 'pending'; // pending, completed, all

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: primaryTeal,
        title: const Text(
          'Refund Management',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          _buildRefundStats(),
          Expanded(child: _buildRefundsList()),
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
          _filterChip('Pending', 'pending', Colors.orange),
          const SizedBox(width: 8),
          _filterChip('Completed', 'completed', Colors.green),
          const SizedBox(width: 8),
          _filterChip('All', 'all', primaryTeal),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value, Color color) {
    final isSelected = _filterStatus == value;
    return Expanded(
      child: FilterChip(
        label: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        selected: isSelected,
        backgroundColor: Colors.grey[100],
        selectedColor: color,
        onSelected: (selected) {
          if (selected) setState(() => _filterStatus = value);
        },
      ),
    );
  }

  Widget _buildRefundStats() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('refunds').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();

        final refunds = snapshot.data!.docs;
        final pending = refunds.where((r) => r['status'] == 'pending').length;
        final completed = refunds.where((r) => r['status'] == 'completed').length;
        final totalAmount = refunds
            .where((r) => r['status'] == 'pending')
            .fold<double>(0, (sum, r) => sum + (r['amount'] ?? 0.0));

        return Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryTeal, lightTeal],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: primaryTeal.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statBox('Pending', pending.toString(), Icons.pending_actions),
              _statBox('Completed', completed.toString(), Icons.check_circle),
              _statBox('Amount', 'Rs. ${totalAmount.toStringAsFixed(0)}', Icons.attach_money),
            ],
          ),
        );
      },
    );
  }

  Widget _statBox(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildRefundsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getRefundsStream(),
      builder: (context, snapshot) {
        // Show loading indicator
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // Handle errors
        if (snapshot.hasError) {
          print('[Refunds] Error loading refunds: ${snapshot.error}');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 80, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  'Error loading refunds',
                  style: TextStyle(color: Colors.red[700], fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => setState(() {}),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(backgroundColor: primaryTeal),
                ),
              ],
            ),
          );
        }

        // Handle empty data
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'No ${_filterStatus == 'all' ? '' : _filterStatus} refunds',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'Refund requests will appear here',
                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
                ),
              ],
            ),
          );
        }

        final refunds = snapshot.data!.docs;
        print('[Refunds] Loaded ${refunds.length} ${_filterStatus} refunds');

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: refunds.length,
          itemBuilder: (context, index) => _buildRefundCard(refunds[index]),
        );
      },
    );
  }

  Stream<QuerySnapshot> _getRefundsStream() {
    print('[Refunds] Getting refunds stream with filter: $_filterStatus');
    
    Query query = FirebaseFirestore.instance.collection('refunds');
    
    if (_filterStatus == 'all') {
      // Show all refunds, sorted by date (single field index - no composite needed)
      return query.orderBy('createdAt', descending: true).snapshots();
    } else {
      // Filter by status WITHOUT orderBy to avoid composite index requirement
      // Refunds will display but not sorted by date
      print('[Refunds] ⚠️ Filtering by status: $_filterStatus (unsorted to avoid index)');
      return query.where('status', isEqualTo: _filterStatus).snapshots();
    }
  }

  Widget _buildRefundCard(DocumentSnapshot refund) {
    final data = refund.data() as Map<String, dynamic>;
    final status = data['status'] ?? 'pending';
    final amount = data['amount'] ?? 0.0;
    final reason = data['reasonText'] ?? data['reason'] ?? 'No reason';
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
    final userId = data['userId'];
    final refundScreenshotUrl = data['refundScreenshotUrl']; // Check if screenshot exists

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, userSnapshot) {
        final userName = userSnapshot.data?.get('name') ?? 'Unknown User';
        final userPhone = userSnapshot.data?.get('phone') ?? 'N/A';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: status == 'completed'
                            ? Colors.green.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        status == 'completed'
                            ? Icons.check_circle
                            : Icons.pending_actions,
                        color: status == 'completed' ? Colors.green : Colors.orange,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            userPhone,
                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: status == 'completed'
                            ? Colors.green.withOpacity(0.15)
                            : Colors.orange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: status == 'completed' ? Colors.green : Colors.orange,
                        ),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          color: status == 'completed' ? Colors.green : Colors.orange,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                _detailRow(Icons.monetization_on, 'Amount', 'Rs. ${amount.toStringAsFixed(0)}'),
                const SizedBox(height: 8),
                _detailRow(Icons.info_outline, 'Reason', reason),
                const SizedBox(height: 8),
                _detailRow(
                  Icons.access_time,
                  'Requested',
                  createdAt != null
                      ? '${createdAt.day}/${createdAt.month}/${createdAt.year} ${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}'
                      : 'N/A',
                ),
                // Show refund proof indicator if completed
                if (status == 'completed' && refundScreenshotUrl != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.verified, size: 16, color: Colors.green),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Payment proof sent to user',
                            style: TextStyle(
                              color: Colors.green.shade800,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (status == 'pending') ...[
                  const Divider(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _copyPaymentDetails(userName, userPhone, amount),
                          icon: const Icon(Icons.copy, size: 18),
                          label: const Text('Copy Details'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: primaryTeal,
                            side: const BorderSide(color: primaryTeal),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _markAsCompleted(refund.id, userId, amount),
                          icon: const Icon(Icons.check, size: 18),
                          label: const Text('Mark Paid'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
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
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  void _copyPaymentDetails(String name, String phone, double amount) {
    final details = '''
━━━━━ REFUND DETAILS ━━━━━
Name: $name
Phone: $phone
Amount: Rs. ${amount.toStringAsFixed(0)}
Method: JazzCash/EasyPaisa
━━━━━━━━━━━━━━━━━━━━━━━
''';

    Clipboard.setData(ClipboardData(text: details));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Text('Payment details copied!'),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _markAsCompleted(String refundId, String userId, double amount) async {
    // Step 1: Ask admin to upload refund screenshot
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.receipt_long, color: Colors.orange),
            SizedBox(width: 12),
            Expanded(child: Text('Upload Refund Proof')),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📸 Please upload screenshot of the refund transaction.',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 12),
            Text(
              '✓ JazzCash/EasyPaisa receipt\n'
              '✓ Clear transaction details\n'
              '✓ User will receive this proof',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.upload, size: 18),
            label: const Text('Upload Screenshot'),
            style: ElevatedButton.styleFrom(backgroundColor: primaryTeal),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Step 2: Pick and upload screenshot
    String? refundScreenshotUrl;
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Screenshot is required to complete refund'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Show loading
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Uploading refund proof...'),
                  ],
                ),
              ),
            ),
          ),
        );
      }

      // Upload to Supabase
      refundScreenshotUrl = await _paymentStorage.uploadPaymentScreenshot(
        file: File(pickedFile.path),
        userId: userId,
        appointmentId: refundId, // Using refundId as identifier
      );

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      if (refundScreenshotUrl == null || refundScreenshotUrl.isEmpty) {
        throw Exception('Failed to upload screenshot');
      }

      print('[Refund] ✅ Screenshot uploaded: $refundScreenshotUrl');
    } catch (e) {
      // Close loading if open
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Upload failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Step 3: Confirm payment completion
    final finalConfirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.green),
            SizedBox(width: 12),
            Text('Confirm Payment'),
          ],
        ),
        content: Text(
          'Screenshot uploaded successfully!\n\n'
          'Confirm you have sent Rs. ${amount.toStringAsFixed(0)} to the user?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Confirm Paid'),
          ),
        ],
      ),
    );

    if (finalConfirm != true) return;

    try {
      // Get refund document to retrieve appointmentId
      final refundDoc = await FirebaseFirestore.instance
          .collection('refunds')
          .doc(refundId)
          .get();
      
      final appointmentId = refundDoc.data()?['appointmentId'] ?? '';

      // Update refund status with screenshot URL
      await FirebaseFirestore.instance.collection('refunds').doc(refundId).update({
        'status': 'completed',
        'processedAt': Timestamp.now(),
        'refundScreenshotUrl': refundScreenshotUrl,
      });

      print('[Refund] ✅ Refund marked as completed with screenshot');

      // Notify user with professional message
      final now = DateTime.now();
      final refNum = refundId.substring(0, 8).toUpperCase();
      
      await _notificationService.sendNotification(
        receiverId: userId,
        appointmentId: appointmentId,
        title: '✅ Refund Processed Successfully',
        message:
            '━━━━━━━━━━━━━━━━━━━━\n'
            '💰 REFUND DETAILS\n'
            '━━━━━━━━━━━━━━━━━━━━\n\n'
            '✓ Amount: Rs. ${amount.toStringAsFixed(0)}\n'
            '✓ Method: JazzCash/EasyPaisa\n'
            '✓ Status: Completed\n'
            '✓ Reference: #$refNum\n'
            '✓ Date: ${now.day}/${now.month}/${now.year}\n'
            '✓ Time: ${now.hour}:${now.minute.toString().padLeft(2, '0')}\n\n'
            '📸 Payment proof attached below.\n\n'
            '━━━━━━━━━━━━━━━━━━━━\n'
            'Please check your JazzCash/EasyPaisa wallet within 5-10 minutes. If you have any questions, contact support.\n\n'
            'Thank you for your patience! 🙏',
        type: 'refund_completed',
        screenshotUrl: refundScreenshotUrl,
      );

      print('[Refund] ✅ Notification sent with screenshot URL');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Refund marked as completed!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
