import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/model/appointment_model.dart';
import 'package:flutter_application_1/model/app_user.dart';
import 'package:flutter_application_1/services/Appointment%20Service/appointment_services.dart';
import 'package:flutter_application_1/services/payment_service/stripe_payment_service.dart';
import 'package:flutter_application_1/services/payment_service/supabase_payment_storage.dart';
import 'package:flutter_application_1/services/notification%20service/notification_service.dart';
import 'package:flutter_application_1/view/Doctor/UserProfilePage.dart';
import 'package:flutter_application_1/view/User/ChatScreen.dart';

class AppointmentApprovalWithRefundPage extends StatefulWidget {
  final AppointmentModel appointment;

  const AppointmentApprovalWithRefundPage({super.key, required this.appointment});

  @override
  State<AppointmentApprovalWithRefundPage> createState() =>
      _AppointmentApprovalWithRefundPageState();
}

class _AppointmentApprovalWithRefundPageState
    extends State<AppointmentApprovalWithRefundPage> {
  final AppointmentService _appointmentService = AppointmentService();
  final StripePaymentService _paymentService = StripePaymentService();
  final NotificationService _notificationService = NotificationService();
  final SupabasePaymentStorage _paymentStorage = SupabasePaymentStorage();

  // DignoVet Theme Colors
  final Color primaryTeal = const Color(0xFF80CBC4);
  final Color darkTeal = const Color(0xFF00796B);
  final Color lightGrey = const Color(0xFFF5F5F5);

  AppUser? user;
  Map<String, dynamic>? animalData;
  bool isLoading = true;
  bool isProcessing = false;
  String? paymentImageUrl; // Signed URL for payment screenshot

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      print('[AppointmentWithRefund] Loading appointment data...');
      print('[AppointmentWithRefund] Payment Screenshot URL: ${widget.appointment.paymentScreenshotUrl}');
      
      // Fetch user data
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.appointment.userId)
          .get();
      if (userDoc.exists) {
        user = AppUser.fromMap(userDoc.data()!, userDoc.id);
      }

      // Fetch animal data
      final animalSnapshot = await FirebaseFirestore.instance
          .collection('animals')
          .where('userId', isEqualTo: widget.appointment.userId)
          .where('name', isEqualTo: widget.appointment.animalName)
          .get();

      if (animalSnapshot.docs.isNotEmpty) {
        animalData = animalSnapshot.docs.first.data();
      }

      // Load signed URL for payment screenshot
      if (widget.appointment.paymentScreenshotUrl != null && 
          widget.appointment.paymentScreenshotUrl!.isNotEmpty) {
        print('[AppointmentWithRefund] Loading signed URL for payment screenshot...');
        paymentImageUrl = await _paymentStorage.getSignedUrlForImage(
          widget.appointment.paymentScreenshotUrl!
        );
        print('[AppointmentWithRefund] Signed URL loaded: $paymentImageUrl');
      } else {
        print('[AppointmentWithRefund] No payment screenshot URL available');
      }

      setState(() => isLoading = false);
    } catch (e) {
      print('[AppointmentWithRefund] Error loading data: $e');
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Some data could not be loaded: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _approveAppointment() async {
    try {
      setState(() => isProcessing = true);

      await _appointmentService.updateStatus(widget.appointment.id, 'approved');
      
      await _notificationService.sendNotification(
        receiverId: widget.appointment.userId,
        title: 'Appointment Approved ✅',
        message:
            'Great news! Your appointment for ${animalData?['name'] ?? widget.appointment.animalName} has been approved. The doctor will contact you soon.',
        appointmentId: widget.appointment.id,
        type: 'appointment_approved',
      );

      setState(() => isProcessing = false);

      // Navigate to chat
      if (user != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              receiverId: widget.appointment.userId,
              receiverName: user!.name,
              receiverImage: user!.imageUrl,
              isOnline: true,
            ),
          ),
        );
      } else {
        Navigator.pop(context);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Appointment approved successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error approving appointment: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _declineAppointment() async {
    // Step 1: Show decline reason selection dialog
    final declineReason = await showDialog<String>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.cancel_outlined, color: Colors.red[700], size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Decline Appointment',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Please select a reason for declining:',
                style: TextStyle(fontSize: 15, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              // Reason 1: Fake/Invalid Screenshot (No Refund)
              _buildDeclineReasonCard(
                context: context,
                icon: Icons.report_problem_outlined,
                iconColor: Colors.red,
                title: 'Fake or Invalid Payment Screenshot',
                subtitle: 'Patient provided false payment proof',
                badge: 'No Refund',
                badgeColor: Colors.red,
                onTap: () => Navigator.pop(context, 'fake_screenshot'),
              ),
              const SizedBox(height: 12),
              // Reason 2: No Time/Busy (Full Refund)
              _buildDeclineReasonCard(
                context: context,
                icon: Icons.access_time_outlined,
                iconColor: Colors.orange,
                title: 'Schedule Conflict / No Time',
                subtitle: 'Unable to attend appointment',
                badge: 'Full Refund',
                badgeColor: Colors.green,
                onTap: () => Navigator.pop(context, 'no_time'),
              ),
              const SizedBox(height: 12),
              // Reason 3: Other Reason (Full Refund)
              _buildDeclineReasonCard(
                context: context,
                icon: Icons.info_outline,
                iconColor: Colors.blue,
                title: 'Other Reason',
                subtitle: 'Personal or medical reasons',
                badge: 'Full Refund',
                badgeColor: Colors.green,
                onTap: () => Navigator.pop(context, 'other'),
              ),
              const SizedBox(height: 16),
              // Cancel button
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (declineReason == null) return;

    // Step 2: Show confirmation dialog with refund info
    final confirmed = await _showDeclineConfirmation(declineReason);
    if (!confirmed) return;

    // Step 3: Process decline with appropriate refund handling
    try {
      setState(() => isProcessing = true);

      // Determine if refund is needed
      final bool needsRefund = declineReason != 'fake_screenshot';
      final String declineMessage = _getDeclineReasonMessage(declineReason);

      // Update appointment status with reason
      await _appointmentService.updateStatus(widget.appointment.id, 'declined');
      
      // Store decline reason in Firestore
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(widget.appointment.id)
          .update({
        'declineReason': declineReason,
        'declineReasonText': declineMessage,
        'declinedAt': Timestamp.now(),
        'declinedBy': 'doctor',
        'refundRequired': needsRefund,
      });

      // Handle refund based on reason
      if (needsRefund && widget.appointment.paymentAmount > 0) {
        // For manual payments (JazzCash/EasyPaisa), notify admin for manual refund
        await _notifyAdminForManualRefund(declineReason);
        
        // Send refund notification to user
        await _notificationService.sendNotification(
          receiverId: widget.appointment.userId,
          title: '💰 Refund Initiated',
          message:
              'Your appointment for ${animalData?['name'] ?? widget.appointment.animalName} has been declined. Refund of Rs. ${widget.appointment.paymentAmount.toStringAsFixed(0)} is being processed. You will receive your payment back within 24-48 hours via your payment method.',
          appointmentId: widget.appointment.id,
          type: 'refund_initiated',
        );

        // Create refund record in Firestore
        await FirebaseFirestore.instance.collection('refunds').add({
          'appointmentId': widget.appointment.id,
          'userId': widget.appointment.userId,
          'doctorId': widget.appointment.doctorId,
          'amount': widget.appointment.paymentAmount,
          'paymentMethod': 'manual', // JazzCash/EasyPaisa
          'status': 'pending',
          'reason': declineReason,
          'reasonText': declineMessage,
          'createdAt': Timestamp.now(),
          'processedAt': null,
        });
      } else {
        // No refund case (fake screenshot)
        await _notificationService.sendNotification(
          receiverId: widget.appointment.userId,
          title: '❌ Appointment Declined',
          message:
              'Your appointment for ${animalData?['name'] ?? widget.appointment.animalName} has been declined. Reason: $declineMessage. No refund will be processed due to invalid payment verification.',
          appointmentId: widget.appointment.id,
          type: 'appointment_declined',
        );
      }

      setState(() => isProcessing = false);

      Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              needsRefund
                  ? 'Appointment declined. Refund will be processed within 24-48 hours.'
                  : 'Appointment declined. No refund issued due to invalid payment proof.',
            ),
            backgroundColor: needsRefund ? Colors.orange : Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      setState(() => isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error declining appointment: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildDeclineReasonCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String badge,
    required Color badgeColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.grey[50],
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: badgeColor),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _showDeclineConfirmation(String reason) async {
    final bool needsRefund = reason != 'fake_screenshot';
    final String reasonText = _getDeclineReasonMessage(reason);
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              needsRefund ? Icons.info_outline : Icons.warning_amber_rounded,
              color: needsRefund ? Colors.orange : Colors.red,
            ),
            const SizedBox(width: 12),
            const Text('Confirm Decline'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reason: $reasonText', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (needsRefund) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Rs. ${widget.appointment.paymentAmount.toStringAsFixed(0)} will be refunded to the patient within 24-48 hours.',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.block, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'No refund will be issued due to invalid payment verification.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            const Text(
              'This action cannot be undone.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: needsRefund ? Colors.orange : Colors.red,
            ),
            child: const Text('Confirm Decline'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  String _getDeclineReasonMessage(String reason) {
    switch (reason) {
      case 'fake_screenshot':
        return 'Invalid or fake payment screenshot detected';
      case 'no_time':
        return 'Schedule conflict - Doctor unavailable';
      case 'other':
        return 'Personal or medical reasons';
      default:
        return 'Appointment declined';
    }
  }

  Future<void> _notifyAdminForManualRefund(String reason) async {
    try {
      // Get all admin users
      final adminSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'Admin')
          .get();

      final reasonText = _getDeclineReasonMessage(reason);

      // Send notification to all admins
      for (var adminDoc in adminSnapshot.docs) {
        await _notificationService.sendNotification(
          receiverId: adminDoc.id,
          title: '💰 Manual Refund Required',
          message:
              'Doctor declined appointment ${widget.appointment.id}. Please process manual refund of Rs. ${widget.appointment.paymentAmount.toStringAsFixed(0)} to ${user?.name ?? "User"}. Reason: $reasonText',
          appointmentId: widget.appointment.id,
          type: 'admin_refund_request',
        );
      }
    } catch (e) {
      print('[Refund] Error notifying admin: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: primaryTeal,
          title: const Text("Request Details"),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: primaryTeal,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Request Details",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusHeader(),
                const SizedBox(height: 20),

                // Payment Information (if available)
                if (widget.appointment.paymentAmount > 0) ...[
                  _sectionLabel("Payment Information"),
                  _buildPaymentCard(),
                  const SizedBox(height: 20),
                ],

                // User/Owner Section
                _sectionLabel("Owner Information"),
                _buildUserCard(),
                const SizedBox(height: 20),

                // Animal Section
                _sectionLabel("Animal Details"),
                _buildAnimalCard(),
                const SizedBox(height: 20),

                // Appointment Information Section
                _sectionLabel("Appointment Information"),
                _buildAppointmentDetails(),
                const SizedBox(height: 20),

                // Payment Information Section
                _sectionLabel("Payment Information"),
                _buildPaymentScreenshotSection(),
                const SizedBox(height: 30),

                // Action Buttons (Accept / Decline)
                _buildActionButtons(context),
                const SizedBox(height: 20),
              ],
            ),
          ),
          if (isProcessing)
            Container(
              color: Colors.black45,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black54,
        ),
      ),
    );
  }

  Widget _buildStatusHeader() {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.orange.shade300),
        ),
        child: const Text(
          "Requested",
          style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildPaymentCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryTeal.withOpacity(0.2), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: darkTeal, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Consultation Fee:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: darkTeal,
                ),
              ),
              Text(
                '\$${widget.appointment.paymentAmount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: darkTeal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                widget.appointment.consultationType == 'home_visit'
                    ? Icons.home
                    : Icons.video_call,
                color: darkTeal,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                widget.appointment.consultationType == 'home_visit'
                    ? 'Home Visit'
                    : 'Online Consultation',
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green),
            ),
            child: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.green, size: 18),
                SizedBox(width: 8),
                Text(
                  'Payment Received',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (widget.appointment.paymentScreenshotUrl != null) ...[
            const SizedBox(height: 15),
            const Text(
              'Payment Screenshot:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => _showImageDialog(widget.appointment.paymentScreenshotUrl!),
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: darkTeal),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.network(
                    widget.appointment.paymentScreenshotUrl!,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showImageDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Payment Screenshot'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Image.network(imageUrl),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard() {
    if (user == null) {
      return Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: lightGrey,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text("User data not available"),
      );
    }

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: lightGrey,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryTeal),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: primaryTeal.withOpacity(0.2),
            backgroundImage:
                user!.imageUrl != null ? NetworkImage(user!.imageUrl!) : null,
            child: user!.imageUrl == null ? Icon(Icons.person, color: darkTeal) : null,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user!.name,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  user!.email,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                Text(
                  user!.role,
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => UserProfilePage(userId: widget.appointment.userId),
                ),
              );
            },
            child: Text(
              "View Profile",
              style: TextStyle(
                color: darkTeal,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimalCard() {
    if (animalData == null) {
      return Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: lightGrey,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text("Animal data not available"),
      );
    }

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: lightGrey,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryTeal),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: primaryTeal.withOpacity(0.2),
            backgroundImage: animalData!['imageUrls'] != null &&
                    (animalData!['imageUrls'] as List).isNotEmpty
                ? NetworkImage(animalData!['imageUrls'][0])
                : null,
            child: animalData!['imageUrls'] == null ||
                    (animalData!['imageUrls'] as List).isEmpty
                ? Icon(Icons.pets, color: darkTeal)
                : null,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  animalData!['name'] ?? 'Unknown',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${animalData!['breed'] ?? 'Mixed'} • ${animalData!['species'] ?? 'Pet'}',
                  style: const TextStyle(color: Colors.grey),
                ),
                Text(
                  "Age: ${animalData!['age']?.toString() ?? 'N/A'}",
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentDetails() {
    final appointmentDate = widget.appointment.date.toDate();
    final formattedDate =
        "${appointmentDate.day}/${appointmentDate.month}/${appointmentDate.year}";

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: lightGrey,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryTeal),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _detailRow(Icons.calendar_today, "Date", formattedDate),
          const Divider(height: 20),
          _detailRow(Icons.access_time, "Time", widget.appointment.time),
          const Divider(height: 20),
          _detailRow(Icons.medical_services, "Problem", widget.appointment.problem),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: darkTeal, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentScreenshotSection() {
    // Check if we have a valid signed URL
    final bool hasValidUrl = paymentImageUrl != null && paymentImageUrl!.isNotEmpty;
    
    print('[Refund-Payment] Has Valid URL: $hasValidUrl');
    if (hasValidUrl) {
      print('[Refund-Payment] Display URL: $paymentImageUrl');
    }
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: lightGrey,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryTeal),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _detailRow(Icons.payment, "Payment Amount", 
              'Rs. ${widget.appointment.paymentAmount.toStringAsFixed(0)}'),
          const Divider(height: 20),
          _detailRow(Icons.call_to_action, "Consultation Type", 
              widget.appointment.consultationType == 'online' ? 'Online Consultation' : 'Home Visit'),
          if (hasValidUrl) ...[
            const Divider(height: 20),
            const Text(
              'Payment Screenshot',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _showFullScreenImage(paymentImageUrl!),
              child: Container(
                height: 250,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: primaryTeal.withOpacity(0.5), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: primaryTeal.withOpacity(0.2),
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
                        paymentImageUrl!,
                        fit: BoxFit.cover,
                        headers: const {
                          'Cache-Control': 'no-cache',
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) {
                            print('[Refund-Screenshot] ✅ Image loaded successfully');
                            return child;
                          }
                          final progress = loadingProgress.expectedTotalBytes != null
                              ? (loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes! * 100).toStringAsFixed(0)
                              : 'Loading';
                          print('[Refund-Screenshot] Loading: $progress%');
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                  color: primaryTeal,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '$progress%',
                                  style: TextStyle(color: Colors.grey[600], fontSize: 11),
                                ),
                              ],
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          print('[Refund-Screenshot] ❌ ERROR: $error');
                          print('[Refund-Screenshot] URL: $paymentImageUrl');
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
                                      'Failed to load screenshot',
                                      style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 8),
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        setState(() {
                                          isLoading = true;
                                        });
                                        _fetchData();
                                      },
                                      icon: const Icon(Icons.refresh, size: 16),
                                      label: const Text('Retry'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: primaryTeal,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      ),
                                    ),
                                    Text(
                                      'Check: Storage permissions | CORS | File exists',
                                      style: TextStyle(color: Colors.grey[600], fontSize: 9),
                                      textAlign: TextAlign.center,
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
                                'Tap to view',
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
          ] else
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange[700], size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No payment screenshot available',
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showFullScreenImage(String imageUrl) {
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
                    print('[Refund-FullScreen] Error: $error');
                    print('[Refund-FullScreen] URL: $imageUrl');
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
                          const Text(
                            'Try checking your connection',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
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

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: isProcessing ? null : _declineAppointment,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: const Text(
              "Decline & Refund",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: ElevatedButton(
            onPressed: isProcessing ? null : _approveAppointment,
            style: ElevatedButton.styleFrom(
              backgroundColor: darkTeal,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: const Text(
              "Accept",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
