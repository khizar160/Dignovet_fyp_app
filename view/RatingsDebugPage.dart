import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/services/firebase_authentication/auth_api.dart';

class RatingsDebugPage extends StatefulWidget {
  const RatingsDebugPage({super.key});

  @override
  State<RatingsDebugPage> createState() => _RatingsDebugPageState();
}

class _RatingsDebugPageState extends State<RatingsDebugPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late String _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = AuthService.currentUser?.uid ?? 'NO_USER';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 Ratings Debug'),
        backgroundColor: Colors.orange,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current User Info
            _buildSection(
              title: 'Current User Info',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('User ID:', _currentUserId),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // All Ratings in System
            _buildSection(
              title: 'All Ratings in consultation_ratings',
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('consultation_ratings')
                    .orderBy('ratedAt', descending: true)
                    .limit(50)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Text('❌ Error: ${snapshot.error}');
                  }

                  final ratings = snapshot.data?.docs ?? [];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '✅ Total: ${ratings.length} ratings',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...ratings.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInfoRow('Rating ID:', doc.id),
                              _buildInfoRow('User:', data['userName'] ?? 'N/A'),
                              _buildInfoRow('Doctor:', data['doctorName'] ?? 'N/A'),
                              _buildInfoRow('Animal:', data['animalName'] ?? 'N/A'),
                              _buildInfoRow(
                                'Doctor Rating:',
                                '${data['doctorRating']}/5',
                              ),
                              _buildInfoRow(
                                'App Rating:',
                                '${data['appRating']}/5',
                              ),
                              _buildInfoRow(
                                'Rated At:',
                                _formatTimestamp(data['ratedAt']),
                              ),
                              if ((data['doctorFeedback'] as String?)?.isNotEmpty ==
                                  true)
                                _buildInfoRow(
                                  'Doctor Feedback:',
                                  data['doctorFeedback'],
                                ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Ratings for Current User (as Patient)
            _buildSection(
              title: 'Ratings I Submitted (as Patient)',
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('consultation_ratings')
                    .where('userId', isEqualTo: _currentUserId)
                    .orderBy('ratedAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Text('❌ Error: ${snapshot.error}');
                  }

                  final ratings = snapshot.data?.docs ?? [];
                  if (ratings.isEmpty) {
                    return const Text('No ratings submitted yet');
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '✅ Found: ${ratings.length} ratings',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...ratings.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.blue),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.blue[50],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInfoRow('Doctor:', data['doctorName'] ?? 'N/A'),
                              _buildInfoRow(
                                'Rating:',
                                '${data['doctorRating']}/5',
                              ),
                              _buildInfoRow(
                                'Submitted:',
                                _formatTimestamp(data['ratedAt']),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Ratings About Current User (as Doctor)
            _buildSection(
              title: 'Ratings About Me (as Doctor)',
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('consultation_ratings')
                    .where('doctorId', isEqualTo: _currentUserId)
                    .orderBy('ratedAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Text('❌ Error: ${snapshot.error}');
                  }

                  final ratings = snapshot.data?.docs ?? [];
                  if (ratings.isEmpty) {
                    return const Text('No ratings received yet');
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '✅ Found: ${ratings.length} ratings',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...ratings.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.green),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.green[50],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInfoRow('From:', data['userName'] ?? 'N/A'),
                              _buildInfoRow(
                                'Rating:',
                                '${data['doctorRating']}/5',
                              ),
                              _buildInfoRow(
                                'Received:',
                                _formatTimestamp(data['ratedAt']),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    }
    return 'N/A';
  }
}
