import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/config/payment_config.dart';

/// Professional Payment Instructions Page
/// Shows complete payment guide with copyable details
class PaymentInstructionsPage extends StatelessWidget {
  final double amount;
  final String appointmentId;
  
  const PaymentInstructionsPage({
    super.key,
    required this.amount,
    required this.appointmentId,
  });

  static const Color primaryTeal = Color(0xFF00796B);
  static const Color lightTeal = Color(0xFF4DB6AC);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: primaryTeal,
        title: const Text(
          'Payment Instructions',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAmountCard(),
            const SizedBox(height: 24),
            _buildPaymentMethodCard(context, 'JazzCash', Icons.credit_card, true),
            const SizedBox(height: 12),
            _buildPaymentMethodCard(context, 'EasyPaisa', Icons.account_balance_wallet, false),
            const SizedBox(height: 28),
            _buildStepsCard(),
            const SizedBox(height: 24),
            _buildImportantNotice(),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryTeal, lightTeal],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
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
          const Icon(
            Icons.payment,
            color: Colors.white,
            size: 52,
          ),
          const SizedBox(height: 16),
          const Text(
            'Amount to Pay',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 15,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Rs. ${amount.toStringAsFixed(0)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              '⚠️ Pay exact amount',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodCard(BuildContext context, String method, IconData icon, bool isPreferred) {
    final number = method == 'JazzCash' 
        ? PaymentConfig.ADMIN_JAZZCASH_NUMBER 
        : PaymentConfig.ADMIN_EASYPAISA_NUMBER;
    
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isPreferred ? Colors.green : Colors.grey[200]!,
          width: isPreferred ? 2.5 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: primaryTeal.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: primaryTeal, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    method,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              if (isPreferred)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'RECOMMENDED',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(height: 1),
          const SizedBox(height: 18),
          
          // Account Number
          Row(
            children: [
              Icon(Icons.phone, color: Colors.grey[500], size: 18),
              const SizedBox(width: 10),
              const Text(
                'Account Number:',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                PaymentConfig.formatPhoneNumber(number),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: primaryTeal,
                  letterSpacing: 2,
                ),
              ),
              IconButton(
                onPressed: () => _copyToClipboard(context, number),
                icon: const Icon(Icons.copy, size: 22),
                style: IconButton.styleFrom(
                  backgroundColor: primaryTeal.withOpacity(0.1),
                  foregroundColor: primaryTeal,
                ),
                tooltip: 'Copy number',
              ),
            ],
          ),
          const SizedBox(height: 18),
          
          // Account Title
          Row(
            children: [
              Icon(Icons.person, color: Colors.grey[500], size: 18),
              const SizedBox(width: 10),
              const Text(
                'Account Title:',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            PaymentConfig.ADMIN_ACCOUNT_NAME,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepsCard() {
    final steps = [
      {'icon': Icons.phone_android, 'text': 'Open JazzCash or Easypaisa app'},
      {'icon': Icons.send, 'text': 'Select "Send Money" or "Transfer"'},
      {'icon': Icons.dialpad, 'text': 'Enter the account number shown above'},
      {'icon': Icons.attach_money, 'text': 'Enter exact amount: Rs. ${amount.toStringAsFixed(0)}'},
      {'icon': Icons.check_circle, 'text': 'Complete the transaction'},
      {'icon': Icons.camera_alt, 'text': 'Take screenshot of payment receipt'},
      {'icon': Icons.upload, 'text': 'Upload screenshot in the app'},
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.list_alt, color: Colors.blue[700], size: 26),
              ),
              const SizedBox(width: 14),
              const Text(
                'Step-by-Step Guide',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          ...steps.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: primaryTeal,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(step['icon'] as IconData, size: 21, color: Colors.grey[700]),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                step['text'] as String,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[800],
                                  height: 1.6,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (index < steps.length - 1)
                          Container(
                            margin: const EdgeInsets.only(left: 10, top: 8),
                            height: 20,
                            width: 2,
                            color: Colors.grey[300],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildImportantNotice() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange[200]!, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange[800], size: 26),
              const SizedBox(width: 12),
              Text(
                'Important Notice',
                style: TextStyle(
                  color: Colors.orange[900],
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildNoticeItem('Pay the EXACT amount shown'),
          _buildNoticeItem('DO NOT add any extra charges'),
          _buildNoticeItem('Screenshot must be clear and readable'),
          _buildNoticeItem('Fake screenshots will result in booking cancellation'),
          _buildNoticeItem('Payment verification takes 5-10 minutes'),
          _buildNoticeItem('Keep your payment receipt for refund purposes'),
        ],
      ),
    );
  }

  Widget _buildNoticeItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 5),
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: Colors.orange[800],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.orange[900],
                fontSize: 13,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            const Text('Number copied to clipboard!'),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
