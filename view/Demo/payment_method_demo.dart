import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/payment_method_selector.dart';

/// DEMO PAGE - Shows Payment Method Selector in action
/// This is an example of how to use PaymentMethodSelector
/// You can run this to see how it looks before integrating
class PaymentMethodDemo extends StatefulWidget {
  const PaymentMethodDemo({Key? key}) : super(key: key);

  @override
  State<PaymentMethodDemo> createState() => _PaymentMethodDemoState();
}

class _PaymentMethodDemoState extends State<PaymentMethodDemo> {
  String? _selectedPaymentMethod;
  final double _appointmentAmount = 500.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Method Demo'),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount Display
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.teal.shade700, Colors.teal.shade500],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.teal.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'Total Amount to Pay',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Rs. ${_appointmentAmount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Payment Method Selector
            Container(
              margin: const EdgeInsets.all(16),
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
              child: PaymentMethodSelector(
                selectedMethod: _selectedPaymentMethod,
                onMethodSelected: (String method) {
                  setState(() {
                    _selectedPaymentMethod = method;
                  });
                  
                  // Show confirmation
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(
                            method == 'JazzCash' 
                                ? Icons.account_balance_wallet 
                                : Icons.mobile_friendly,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 12),
                          Text('Selected: $method'),
                        ],
                      ),
                      backgroundColor: method == 'JazzCash' ? Colors.red : Colors.green,
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                },
                showAccountDetails: true,
              ),
            ),

            // Next Steps Info (shown after selection)
            if (_selectedPaymentMethod != null) ...[
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue[200]!, width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.lightbulb,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Next Steps',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[900],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildStep(1, 'Copy the account number using the copy button'),
                    _buildStep(2, 'Open your $_selectedPaymentMethod app'),
                    _buildStep(3, 'Send Rs. ${_appointmentAmount.toStringAsFixed(0)} to the account'),
                    _buildStep(4, 'Take a screenshot of the payment confirmation'),
                    _buildStep(5, 'Return to this app and upload the screenshot'),
                    _buildStep(6, 'Submit your appointment booking'),
                  ],
                ),
              ),

              // Proceed Button
              Container(
                margin: const EdgeInsets.all(16),
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Show success dialog
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        title: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 32,
                            ),
                            const SizedBox(width: 12),
                            const Text('Ready!'),
                          ],
                        ),
                        content: Text(
                          'You selected $_selectedPaymentMethod.\n\n'
                          'In the real app, you would now:\n'
                          '1. Upload payment screenshot\n'
                          '2. Submit appointment\n'
                          '3. Wait for admin approval',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedPaymentMethod == 'JazzCash'
                        ? Colors.red
                        : Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.arrow_forward, size: 24),
                      const SizedBox(width: 12),
                      const Text(
                        'Proceed to Upload Screenshot',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Warning if not selected
            if (_selectedPaymentMethod == null)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange[300]!, width: 2),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange[700], size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Please select a payment method to continue',
                        style: TextStyle(
                          color: Colors.orange[900],
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(int number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$number',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.blue[900],
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
