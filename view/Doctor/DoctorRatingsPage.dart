import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/services/firebase_authentication/auth_api.dart';
import 'package:flutter_application_1/view/RatingsDebugPage.dart';

class DoctorRatingsPage extends StatefulWidget {
  const DoctorRatingsPage({super.key});

  @override
  State<DoctorRatingsPage> createState() => _DoctorRatingsPageState();
}

class _DoctorRatingsPageState extends State<DoctorRatingsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late String _doctorId;

  @override
  void initState() {
    super.initState();
    _doctorId = AuthService.currentUser?.uid ?? '';
  }

  Stream<QuerySnapshot> _getRatingsStream() {
    return _firestore
        .collection('consultation_ratings')
        .where('doctorId', isEqualTo: _doctorId)
        .orderBy('ratedAt', descending: true)
        .limit(100)
        .snapshots()
        .handleError((error) {
          print('[DoctorRatings] Error fetching ratings: $error');
          // If error is about composite index, create it automatically
          if (error.toString().contains('composite')) {
            print('[DoctorRatings] Composite index needed - Firebase will create it');
          }
        });
  }

  double _calculateAverageRating(List<DocumentSnapshot> ratings) {
    if (ratings.isEmpty) return 0.0;
    double total = 0;
    for (var rating in ratings) {
      final data = rating.data() as Map<String, dynamic>;
      total += (data['doctorRating'] as num?)?.toDouble() ?? 0;
    }
    return total / ratings.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Ratings & Reviews'),
        backgroundColor: const Color(0xFF00796B),
        elevation: 2,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getRatingsStream(),
        builder: (context, snapshot) {
          print('[DoctorRatings] Stream state: ${snapshot.connectionState}, doctorId: $_doctorId');
          
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            print('[DoctorRatings] Error: ${snapshot.error}');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      children: [
                        const Text(
                          'Failed to load ratings',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => setState(() {}),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          final ratings = snapshot.data?.docs ?? [];
          print('[DoctorRatings] Loaded ${ratings.length} ratings for doctor: $_doctorId');

          if (ratings.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.star_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No Ratings Yet',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your ratings will appear here after consultations',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          final averageRating = _calculateAverageRating(ratings);
          final totalRatings = ratings.length;

          return SingleChildScrollView(
            child: Column(
              children: [
                // Statistics Card
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00796B), Color(0xFF4DB6AC)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Average Rating',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Text(
                                    averageRating.toStringAsFixed(1),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    children: [
                                      Row(
                                        children: List.generate(
                                          5,
                                          (index) => Icon(
                                            index < averageRating.round()
                                                ? Icons.star
                                                : Icons.star_outline,
                                            color: Colors.amber[300],
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  'Total Reviews',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  totalRatings.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Ratings List
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: ratings.length,
                  itemBuilder: (context, index) {
                    final ratingDoc = ratings[index];
                    final data = ratingDoc.data() as Map<String, dynamic>;
                    return _buildRatingCard(data);
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => RatingsDebugPage()),
          );
        },
        backgroundColor: Colors.deepOrange,
        tooltip: 'Debug Ratings Issues',
        child: const Icon(Icons.bug_report),
      ),
    );
  }

  Widget _buildRatingCard(Map<String, dynamic> data) {
    final doctorRating = (data['doctorRating'] as num?)?.toInt() ?? 0;
    final appRating = (data['appRating'] as num?)?.toInt() ?? 0;
    final userName = data['userName'] as String? ?? 'Anonymous';
    final animalName = data['animalName'] as String? ?? 'Unknown';
    final doctorFeedback = data['doctorFeedback'] as String? ?? '';
    final appFeedback = data['appFeedback'] as String? ?? '';
    final ratedAt = (data['ratedAt'] as Timestamp?)?.toDate();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with user and date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '🐾 ${animalName}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                if (ratedAt != null)
                  Text(
                    _formatDate(ratedAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: Colors.grey[200], height: 1),
            const SizedBox(height: 12),
            // Doctor Rating
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '👨‍⚕️ Doctor Rating',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    ...List.generate(
                      5,
                      (index) => Icon(
                        index < doctorRating ? Icons.star : Icons.star_outline,
                        color: Colors.amber,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$doctorRating/5',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // App Rating
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '📱 App Rating',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    ...List.generate(
                      5,
                      (index) => Icon(
                        index < appRating ? Icons.star : Icons.star_outline,
                        color: Colors.blue,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$appRating/5',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
            // Feedback
            if (doctorFeedback.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Doctor Feedback:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      doctorFeedback,
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
            ],
            if (appFeedback.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'App Feedback:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      appFeedback,
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return '${diff.inMinutes}m ago';
      }
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
