import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/provider/language_provider.dart';

class AppointmentSentPage extends StatelessWidget {
  const AppointmentSentPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const Color primaryTeal = Color(0xFF80CBC4);
    const Color darkTeal = Color(0xFF00796B);

    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(30.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon Container
                  Container(
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: primaryTeal.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.mark_email_read_outlined,
                      size: 100,
                      color: darkTeal,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Title
                  Text(
                    languageProvider.t(
                      "Appointment Request Sent!",
                      "ملاقات کی درخواست بھیج دی گئی!",
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 15),

                  // Description
                  Text(
                    languageProvider.t(
                      "Your request has been successfully sent to the doctor.\nPlease wait for the doctor's response and approval.",
                      "آپ کی درخواست کامیابی سے ڈاکٹر کو بھیج دی گئی ہے۔\nبراہ کرم ڈاکٹر کے جواب اور منظوری کا انتظار کریں۔",
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 50),

                  // Waiting Status
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.orange),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Text(
                          languageProvider.t(
                            "Waiting for Response...",
                            "جواب کا انتظار ہے...",
                          ),
                          style: const TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 60),

                  // Back to Home Button
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    child: Text(
                      languageProvider.t("Back to Home", "ہوم پر واپس"),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: darkTeal,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
