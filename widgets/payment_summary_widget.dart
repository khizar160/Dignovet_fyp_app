import 'package:flutter/material.dart';
import 'package:flutter_application_1/config/payment_config.dart';

/// Professional Payment Summary Widget
/// Shows comprehensive payment breakdown with all details
class PaymentSummaryCard extends StatelessWidget {
  final double amount;
  final String paymentMethod;
  final String? transactionId;
  final DateTime? paymentDate;
  final String status;
  
  const PaymentSummaryCard({
    super.key,
    required this.amount,
    this.paymentMethod = 'JazzCash/EasyPaisa',
    this.transactionId,
    this.paymentDate,
    this.status = 'pending',
  });

  static const Color primaryTeal = Color(0xFF00796B);

  @override
  Widget build(BuildContext context) {
    final breakdown = PaymentConfig.getPaymentBreakdown(amount);
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Payment Summary',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              _buildStatusBadge(),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 16),
          
          // Payment Details
          _buildDetailRow('Total Amount', 'Rs. ${amount.toStringAsFixed(0)}', isBold: true),
          const SizedBox(height: 12),
          _buildDetailRow('App Commission (${(PaymentConfig.COMMISSION_RATE * 100).toInt()}%)', 
              'Rs. ${breakdown['commission']!.toStringAsFixed(0)}', 
              color: Colors.orange[700]),
          const SizedBox(height: 12),
          _buildDetailRow('Doctor Receives', 
              'Rs. ${breakdown['doctorPayout']!.toStringAsFixed(0)}', 
              color: Colors.green[700]),
          
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          
          // Payment Method
          Row(
            children: [
              Icon(Icons.payment, color: Colors.grey[600], size: 20),
              const SizedBox(width: 8),
              Text(
                'Payment Method:',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                paymentMethod,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          
          if (paymentDate != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.grey[600], size: 20),
                const SizedBox(width: 8),
                Text(
                  'Payment Date:',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDate(paymentDate!),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
          
          if (transactionId != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.receipt, color: Colors.grey[600], size: 20),
                const SizedBox(width: 8),
                Text(
                  'Transaction ID:',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    transactionId!,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          
          const SizedBox(height: 20),
          
          // Info Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Payment is manually verified. Approval takes 5-10 minutes.',
                    style: TextStyle(
                      color: Colors.blue[900],
                      fontSize: 12,
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

  Widget _buildDetailRow(String label, String value, {Color? color, bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
            fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 18 : 15,
            fontWeight: FontWeight.bold,
            color: color ?? (isBold ? primaryTeal : Colors.black87),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge() {
    Color badgeColor;
    String badgeText;
    IconData badgeIcon;
    
    switch (status.toLowerCase()) {
      case 'approved':
      case 'completed':
        badgeColor = Colors.green;
        badgeText = 'VERIFIED';
        badgeIcon = Icons.check_circle;
        break;
      case 'pending':
        badgeColor = Colors.orange;
        badgeText = 'PENDING';
        badgeIcon = Icons.pending;
        break;
      case 'declined':
      case 'rejected':
        badgeColor = Colors.red;
        badgeText = 'DECLINED';
        badgeIcon = Icons.cancel;
        break;
      default:
        badgeColor = Colors.grey;
        badgeText = 'UNKNOWN';
        badgeIcon = Icons.help;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badgeColor, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badgeIcon, color: badgeColor, size: 16),
          const SizedBox(width: 6),
          Text(
            badgeText,
            style: TextStyle(
              color: badgeColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays == 0) {
      return 'Today ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

/// Payment Instructions Banner Widget
/// Shows quick payment guide at top of screens
class PaymentInstructionsBanner extends StatelessWidget {
  final VoidCallback? onTapDetails;
  
  const PaymentInstructionsBanner({
    super.key,
    this.onTapDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green[400]!, Colors.teal[400]!],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white30,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.payment, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Payment via Mobile Wallet',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'JazzCash or EasyPaisa',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 13,
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
              _buildQuickStep('1', 'Send Money'),
              const SizedBox(width: 8),
              _buildQuickStep('2', 'Upload Screenshot'),
              const SizedBox(width: 8),
              _buildQuickStep('3', 'Get Approved'),
            ],
          ),
          if (onTapDetails != null) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: onTapDetails,
              icon: const Icon(Icons.info_outline, color: Colors.white, size: 18),
              label: const Text(
                'View Detailed Instructions',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
              style: TextButton.styleFrom(
                backgroundColor: Colors.white24,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickStep(String number, String text) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  number,
                  style: const TextStyle(
                    color: Colors.teal,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
