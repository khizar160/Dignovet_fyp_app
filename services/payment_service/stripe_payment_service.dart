import 'dart:convert';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/model/payment_model.dart';
import 'package:flutter_application_1/services/payment_service/supabase_payment_storage.dart';
import 'dart:io';

class StripePaymentService {
  // TODO: Replace with your Stripe Secret Key (Keep this secure, ideally use Cloud Functions)
  static const String _stripeSecretKey = 'sk_test_YOUR_SECRET_KEY_HERE';
  static const String _stripePublishableKey = 'pk_test_YOUR_PUBLISHABLE_KEY_HERE';
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SupabasePaymentStorage _supabaseStorage = SupabasePaymentStorage();

  /// Initialize Stripe
  static Future<void> init() async {
    Stripe.publishableKey = _stripePublishableKey;
  }

  /// Create Payment Intent on Stripe
  Future<Map<String, dynamic>?> createPaymentIntent({
    required double amount,
    required String currency,
  }) async {
    try {
      print('\n💰 Creating Stripe Payment Intent...');
      print('   Amount: \$${amount.toStringAsFixed(2)}');
      print('   Currency: ${currency.toUpperCase()}');
      
      // Convert amount to smallest currency unit (cents for USD)
      final int amountInCents = (amount * 100).toInt();
      print('   Amount in cents: $amountInCents');

      final response = await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_intents'),
        headers: {
          'Authorization': 'Bearer $_stripeSecretKey',
          'Content-Type': 'application/x-www-form-urlencoded'
        },
        body: {
          'amount': amountInCents.toString(),
          'currency': currency.toLowerCase(),
          'payment_method_types[]': 'card',
        },
      );

      if (response.statusCode == 200) {
        final paymentIntent = json.decode(response.body);
        print('✅ Payment Intent created successfully!');
        print('   Payment Intent ID: ${paymentIntent['id']}');
        return paymentIntent;
      } else {
        print('❌ Failed to create payment intent: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Error creating payment intent: $e');
      return null;
    }
  }

  /// Initialize Payment Sheet
  Future<bool> initPaymentSheet({
    required String paymentIntentClientSecret,
    required String customerName,
    required String customerEmail,
  }) async {
    try {
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntentClientSecret,
          merchantDisplayName: 'DiagnoVet',
          billingDetails: BillingDetails(
            name: customerName,
            email: customerEmail,
          ),
        ),
      );
      return true;
    } catch (e) {
      print('Error initializing payment sheet: $e');
      return false;
    }
  }

  /// Present Payment Sheet
  Future<bool> presentPaymentSheet() async {
    try {
      await Stripe.instance.presentPaymentSheet();
      return true;
    } catch (e) {
      print('Error presenting payment sheet: $e');
      return false;
    }
  }

  /// Upload Payment Screenshot to Supabase Storage
  Future<String?> uploadPaymentScreenshot({
    required File imageFile,
    required String userId,
    required String appointmentId,
  }) async {
    try {
      print('📤 Uploading payment screenshot to Supabase...');
      print('   User ID: $userId');
      print('   Appointment ID: $appointmentId');
      print('   File path: ${imageFile.path}');
      
      final screenshotUrl = await _supabaseStorage.uploadPaymentScreenshot(
        file: imageFile,
        userId: userId,
        appointmentId: appointmentId,
      );

      if (screenshotUrl != null && screenshotUrl.isNotEmpty) {
        print('✅ Payment screenshot uploaded successfully!');
        print('   URL: $screenshotUrl');
        return screenshotUrl;
      } else {
        print('❌ Upload returned empty URL');
        throw Exception('Upload failed - no URL returned');
      }
    } catch (e) {
      print('❌ Error uploading payment screenshot: $e');
      rethrow; // Re-throw error to show in UI
    }
  }

  /// Save Payment to Firestore
  Future<String?> savePayment(PaymentModel payment) async {
    try {
      print('💾 Saving payment record to Firestore...');
      print('   User ID: ${payment.userId}');
      print('   Doctor ID: ${payment.doctorId}');
      print('   Amount: \$${payment.amount.toStringAsFixed(2)}');
      print('   Appointment ID: ${payment.appointmentId}');
      print('   Consultation Type: ${payment.consultationType}');
      
      final docRef = await _firestore.collection('payments').add(payment.toMap());
      
      print('✅ Payment record saved successfully!');
      print('   Payment ID: ${docRef.id}');
      print('   Screenshot URL: ${payment.paymentScreenshotUrl}');
      
      return docRef.id;
    } catch (e) {
      print('❌ Error saving payment to Firestore: $e');
      return null;
    }
  }

  /// Update Payment Status
  Future<void> updatePaymentStatus({
    required String paymentId,
    required String status,
    String? paymentScreenshotUrl,
  }) async {
    try {
      print('🔄 Updating payment status in Firestore...');
      print('   Payment ID: $paymentId');
      print('   New Status: $status');
      
      final Map<String, dynamic> updateData = {
        'status': status,
        'completedAt': Timestamp.now(),
      };

      if (paymentScreenshotUrl != null) {
        updateData['paymentScreenshotUrl'] = paymentScreenshotUrl;
        print('   Screenshot URL: $paymentScreenshotUrl');
      }

      await _firestore.collection('payments').doc(paymentId).update(updateData);
      
      print('✅ Payment status updated successfully!');
    } catch (e) {
      print('❌ Error updating payment status: $e');
      rethrow;
    }
  }

  /// Process Refund via Stripe
  Future<String?> processRefund({
    required String paymentIntentId,
    required double amount,
  }) async {
    try {
      print('\n💸 Processing Stripe Refund...');
      print('   Payment Intent ID: $paymentIntentId');
      print('   Refund Amount: \$${amount.toStringAsFixed(2)}');
      
      final int amountInCents = (amount * 100).toInt();
      print('   Amount in cents: $amountInCents');

      final response = await http.post(
        Uri.parse('https://api.stripe.com/v1/refunds'),
        headers: {
          'Authorization': 'Bearer $_stripeSecretKey',
          'Content-Type': 'application/x-www-form-urlencoded'
        },
        body: {
          'payment_intent': paymentIntentId,
          'amount': amountInCents.toString(),
        },
      );

      if (response.statusCode == 200) {
        final refundData = json.decode(response.body);
        print('✅ Refund processed successfully!');
        print('   Refund ID: ${refundData['id']}');
        print('   Status: ${refundData['status']}');
        return refundData['id'];
      } else {
        print('❌ Failed to process refund: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Error processing refund: $e');
      return null;
    }
  }

  /// Save Refund Information
  Future<void> saveRefund({
    required String paymentId,
    required String refundId,
    required String appointmentId,
  }) async {
    try {
      print('💸 Saving refund information to Firestore...');
      print('   Payment ID: $paymentId');
      print('   Refund ID: $refundId');
      print('   Appointment ID: $appointmentId');
      
      // Update payment record
      await _firestore.collection('payments').doc(paymentId).update({
        'status': 'refunded',
        'refundId': refundId,
        'refundedAt': Timestamp.now(),
      });
      print('✅ Payment record updated with refund info');

      // Update appointment record
      await _firestore.collection('appointments').doc(appointmentId).update({
        'paymentStatus': 'refunded',
        'refundId': refundId,
      });
      print('✅ Appointment record updated with refund info');
      
      print('✅ Refund information saved successfully!');
    } catch (e) {
      print('❌ Error saving refund information: $e');
      rethrow;
    }
  }

  /// Get Payment by Appointment ID
  Future<PaymentModel?> getPaymentByAppointmentId(String appointmentId) async {
    try {
      final querySnapshot = await _firestore
          .collection('payments')
          .where('appointmentId', isEqualTo: appointmentId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        return PaymentModel.fromMap(doc.data(), doc.id);
      }
      return null;
    } catch (e) {
      print('Error getting payment: $e');
      return null;
    }
  }

  /// Complete Payment Process (for screenshot-based verification)
  Future<bool> completePaymentWithScreenshot({
    required String appointmentId,
    required String paymentId,
    required File screenshotFile,
    required String userId,
  }) async {
    try {
      print('\n🎯 Starting complete payment process...');
      print('═══════════════════════════════════════');
      
      // Step 1: Upload screenshot to Supabase
      print('\n📸 Step 1: Uploading screenshot to Supabase...');
      final screenshotUrl = await uploadPaymentScreenshot(
        imageFile: screenshotFile,
        userId: userId,
        appointmentId: appointmentId,
      );

      if (screenshotUrl == null) {
        print('❌ Screenshot upload failed!');
        return false;
      }

      // Step 2: Update payment record in Firestore
      print('\n💳 Step 2: Updating payment record...');
      await updatePaymentStatus(
        paymentId: paymentId,
        status: 'completed',
        paymentScreenshotUrl: screenshotUrl,
      );

      // Step 3: Update appointment record in Firestore
      print('\n📅 Step 3: Updating appointment record...');
      await _firestore.collection('appointments').doc(appointmentId).update({
        'paymentStatus': 'paid',
        'paymentScreenshotUrl': screenshotUrl,
        'paymentDate': Timestamp.now(),
      });
      print('✅ Appointment record updated!');

      print('\n🎉 PAYMENT PROCESS COMPLETED SUCCESSFULLY!');
      print('═══════════════════════════════════════');
      print('Summary:');
      print('  ✅ Screenshot uploaded to Supabase');
      print('  ✅ Payment record saved to Firestore');
      print('  ✅ Appointment record updated');
      print('  📸 Screenshot URL: $screenshotUrl');
      print('═══════════════════════════════════════\n');
      
      return true;
    } catch (e) {
      print('❌ Error completing payment with screenshot: $e');
      return false;
    }
  }
}
