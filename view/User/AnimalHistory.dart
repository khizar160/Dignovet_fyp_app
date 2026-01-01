import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/provider/language_provider.dart';
import 'package:intl/intl.dart';

class AnimalHistoryPage extends StatefulWidget {
  const AnimalHistoryPage({super.key});

  @override
  State<AnimalHistoryPage> createState() => _AnimalHistoryPageState();
}

class _AnimalHistoryPageState extends State<AnimalHistoryPage> {
  final Color primaryDark = const Color(0xFF00796B);
  final Color primaryMedium = const Color(0xFF4DB6AC);
  final Color primaryLight = const Color(0xFF80CBC4);
  final Color darkText = const Color(0xFF2C3E50);
  
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get _userId => _auth.currentUser?.uid ?? '';

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [primaryDark, primaryMedium, primaryLight],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _buildAppBar(languageProvider),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(top: 20),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                      child: Column(
                        children: [
                          _buildHeader(languageProvider),
                          Expanded(
                            child: StreamBuilder<QuerySnapshot>(
                              stream: _firestore
                                  .collection('animals')
                                  .where('userId', isEqualTo: _userId)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return Center(
                                    child: CircularProgressIndicator(color: primaryDark),
                                  );
                                }

                                if (snapshot.hasError) {
                                  return Center(
                                    child: Text(
                                      'Error: ${snapshot.error}',
                                      style: const TextStyle(color: Colors.red),
                                    ),
                                  );
                                }

                                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                                  return _buildEmptyState(languageProvider);
                                }

                                // Sort documents by createdAt in Dart
                                final docs = snapshot.data!.docs;
                                docs.sort((a, b) {
                                  final aData = a.data() as Map<String, dynamic>;
                                  final bData = b.data() as Map<String, dynamic>;
                                  final aTime = (aData['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
                                  final bTime = (bData['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
                                  return bTime.compareTo(aTime);
                                });

                                return ListView.builder(
                                  padding: const EdgeInsets.all(24),
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: docs.length,
                                  itemBuilder: (context, index) {
                                    final doc = docs[index];
                                    final data = doc.data() as Map<String, dynamic>;
                                    return _buildAnimalCard(
                                      doc.id,
                                      data,
                                      languageProvider,
                                    );
                                  },
                                );
                              },
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
        );
      },
    );
  }

  Widget _buildAppBar(LanguageProvider languageProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const Spacer(),
          Text(
            languageProvider.t('Animal History', 'جانوروں کی تاریخ'),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildHeader(LanguageProvider languageProvider) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              primaryDark.withOpacity(0.1),
              primaryMedium.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: primaryDark.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primaryDark.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.pets, size: 32, color: primaryDark),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    languageProvider.t('Medical Records', 'طبی ریکارڈ'),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: darkText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('animals')
                        .where('userId', isEqualTo: _userId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      final count = snapshot.data?.docs.length ?? 0;
                      return Text(
                        '$count ${languageProvider.t("Registered Pets", "رجسٹرڈ پالتو جانور")}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimalCard(
    String animalId,
    Map<String, dynamic> data,
    LanguageProvider languageProvider,
  ) {
    final imageUrls = List<String>.from(data['imageUrls'] ?? []);
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: primaryLight.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryDark.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Animal Profile Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [primaryMedium.withOpacity(0.3), primaryLight.withOpacity(0.2)],
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.transparent,
                    backgroundImage: imageUrls.isNotEmpty 
                      ? NetworkImage(imageUrls.first) 
                      : null,
                    child: imageUrls.isEmpty
                        ? Icon(Icons.pets, size: 35, color: primaryDark)
                        : null,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['name'] ?? 'N/A',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: darkText,
                        ),
                      ),
                      Text(
                        data['breed'] ?? 'N/A',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      Text(
                        '${languageProvider.t("Age", "عمر")}: ${data['age']} ${languageProvider.t("years", "سال")}',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: data['gender'] == 'Male' 
                      ? Colors.blue.withOpacity(0.1) 
                      : Colors.pink.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: data['gender'] == 'Male' ? Colors.blue : Colors.pink,
                    ),
                  ),
                  child: Text(
                    data['gender'] == 'Male' 
                      ? languageProvider.t('Male', 'نر') 
                      : languageProvider.t('Female', 'مادہ'),
                    style: TextStyle(
                      color: data['gender'] == 'Male' ? Colors.blue : Colors.pink,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Registration Details
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  languageProvider.t('Registration Details', 'رجسٹریشن کی تفصیلات'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: darkText,
                  ),
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  Icons.medical_services_outlined,
                  languageProvider.t('Suspected Disease', 'مشتبہ بیماری'),
                  data['suspectedDisease'] ?? languageProvider.t('Not specified', 'مخصوص نہیں'),
                  Colors.redAccent,
                  languageProvider,
                ),
                const SizedBox(height: 10),
                _buildInfoRow(
                  Icons.description_outlined,
                  languageProvider.t('Symptoms', 'علامات'),
                  data['symptoms'] ?? languageProvider.t('None', 'کوئی نہیں'),
                  primaryDark,
                  languageProvider,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      '${languageProvider.t("Registered", "رجسٹرڈ")}: ${createdAt != null ? DateFormat('MMM dd, yyyy').format(createdAt) : 'N/A'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Disease Predictions & Prescriptions
          _buildHistorySection(animalId, languageProvider),
        ],
      ),
    );
  }

  Widget _buildHistorySection(String animalId, LanguageProvider languageProvider) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('diseasePredictions')
          .where('animalId', isEqualTo: animalId)
          .limit(3)
          .snapshots(),
      builder: (context, predictionSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('prescriptions')
              .where('animalId', isEqualTo: animalId)
              .limit(3)
              .snapshots(),
          builder: (context, prescriptionSnapshot) {
            final hasPredictions = predictionSnapshot.hasData && predictionSnapshot.data!.docs.isNotEmpty;
            final hasPrescriptions = prescriptionSnapshot.hasData && prescriptionSnapshot.data!.docs.isNotEmpty;
            
            if (!hasPredictions && !hasPrescriptions) {
              return const SizedBox.shrink();
            }
            
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasPredictions) ...[
                    Text(
                      languageProvider.t('Disease Predictions', 'بیماری کی پیشن گوئیاں'),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: darkText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...predictionSnapshot.data!.docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.orange.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.analytics, size: 16, color: Colors.orange[700]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data['predictedDisease'] ?? 'N/A',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  if (timestamp != null)
                                    Text(
                                      DateFormat('MMM dd, yyyy').format(timestamp),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 12),
                  ],
                  if (hasPrescriptions) ...[
                    Text(
                      languageProvider.t('Prescriptions', 'نسخے'),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: darkText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...prescriptionSnapshot.data!.docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: primaryDark.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: primaryDark.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.medication, size: 16, color: primaryDark),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data['medicine'] ?? 'N/A',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  if (data['doctorName'] != null)
                                    Text(
                                      '${languageProvider.t("By", "از")}: ${data['doctorName']}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  if (timestamp != null)
                                    Text(
                                      DateFormat('MMM dd, yyyy').format(timestamp),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(LanguageProvider languageProvider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.pets_outlined,
            size: 100,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 20),
          Text(
            languageProvider.t('No Animals Registered', 'کوئی جانور رجسٹر نہیں'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            languageProvider.t('Register your first pet', 'اپنا پہلا پالتو رجسٹر کریں'),
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
    Color iconColor,
    LanguageProvider languageProvider,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 14, color: Colors.black87),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
