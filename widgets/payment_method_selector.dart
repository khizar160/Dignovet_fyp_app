import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/payment_config.dart';

/// Professional Payment Method Selector
/// Allows user to select between JazzCash and EasyPaisa
/// Shows account details based on selection
class PaymentMethodSelector extends StatefulWidget {
  final String? selectedMethod;
  final Function(String) onMethodSelected;
  final bool showAccountDetails;

  const PaymentMethodSelector({
    Key? key,
    this.selectedMethod,
    required this.onMethodSelected,
    this.showAccountDetails = true,
  }) : super(key: key);

  @override
  State<PaymentMethodSelector> createState() => _PaymentMethodSelectorState();
}

class _PaymentMethodSelectorState extends State<PaymentMethodSelector> {
  String? _selectedMethod;

  @override
  void initState() {
    super.initState();
    _selectedMethod = widget.selectedMethod;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal.shade700, Colors.teal.shade500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: const Row(
            children: [
              Icon(Icons.payment, color: Colors.white, size: 28),
              SizedBox(width: 12),
              Text(
                'Select Payment Method',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        // Payment Options
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
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
              const SizedBox(height: 16),
              
              // JazzCash Option
              _buildPaymentOption(
                method: 'JazzCash',
                icon: Icons.account_balance_wallet,
                color: Colors.red,
                number: PaymentConfig.ADMIN_JAZZCASH_NUMBER,
                accountName: PaymentConfig.ADMIN_ACCOUNT_NAME,
              ),
              
              const SizedBox(height: 12),
              
              // EasyPaisa Option
              _buildPaymentOption(
                method: 'EasyPaisa',
                icon: Icons.mobile_friendly,
                color: Colors.green,
                number: PaymentConfig.ADMIN_EASYPAISA_NUMBER,
                accountName: PaymentConfig.ADMIN_ACCOUNT_NAME,
              ),
              
              const SizedBox(height: 16),
              
              // Account Details Section (shown after selection)
              if (_selectedMethod != null && widget.showAccountDetails)
                _buildAccountDetails(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentOption({
    required String method,
    required IconData icon,
    required Color color,
    required String number,
    required String accountName,
  }) {
    final isSelected = _selectedMethod == method;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMethod = method;
        });
        widget.onMethodSelected(method);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey[50],
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2.5 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            // Icon Container
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isSelected ? color : Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 32,
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Method Name & Description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    method,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? color : Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Fast & Secure Payment',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            
            // Selection Indicator
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isSelected ? color : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? color : Colors.grey[400]!,
                  width: 2,
                ),
              ),
              child: Icon(
                isSelected ? Icons.check : null,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountDetails() {
    final String number = _selectedMethod == 'JazzCash'
        ? PaymentConfig.ADMIN_JAZZCASH_NUMBER
        : PaymentConfig.ADMIN_EASYPAISA_NUMBER;
    
    final Color methodColor = _selectedMethod == 'JazzCash' ? Colors.red : Colors.green;
    final MaterialColor materialColor = _selectedMethod == 'JazzCash' ? Colors.red : Colors.green;
    final String formattedNumber = _formatPhoneNumber(number);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [materialColor.shade50, materialColor.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: materialColor.shade300, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: methodColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _selectedMethod == 'JazzCash' ? Icons.account_balance_wallet : Icons.mobile_friendly,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedMethod!,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: materialColor.shade900,
                      ),
                    ),
                    Text(
                      'Account Details',
                      style: TextStyle(
                        fontSize: 13,
                        color: materialColor.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Account Name
          _buildDetailRow(
            icon: Icons.person,
            label: 'Account Name',
            value: PaymentConfig.ADMIN_ACCOUNT_NAME,
            color: materialColor,
          ),
          
          const SizedBox(height: 16),
          
          // Phone Number with Copy Button
          _buildDetailRow(
            icon: Icons.phone,
            label: 'Account Number',
            value: formattedNumber,
            color: materialColor,
            showCopy: true,
            rawValue: number,
          ),
          
          const SizedBox(height: 16),
          
          // Instructions
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: materialColor.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: materialColor.shade700, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Send payment to this number and upload screenshot as proof',
                    style: TextStyle(
                      fontSize: 12,
                      color: materialColor.shade900,
                      height: 1.4,
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

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required MaterialColor color,
    bool showCopy = false,
    String? rawValue,
  }) {
    return Row(
      children: [
        Icon(icon, color: color.shade700, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: color.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color.shade900,
                ),
              ),
            ],
          ),
        ),
        if (showCopy)
          IconButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: rawValue ?? value));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white),
                      const SizedBox(width: 12),
                      Text('$label copied: ${rawValue ?? value}'),
                    ],
                  ),
                  backgroundColor: color.shade700,
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.shade700,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.copy, color: Colors.white, size: 18),
            ),
            tooltip: 'Copy Number',
          ),
      ],
    );
  }

  String _formatPhoneNumber(String number) {
    // Format: 0309-449-2737
    if (number.length == 11) {
      return '${number.substring(0, 4)}-${number.substring(4, 7)}-${number.substring(7)}';
    }
    return number;
  }
}
