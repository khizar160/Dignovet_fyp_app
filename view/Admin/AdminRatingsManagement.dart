import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/view/RatingsDebugPage.dart';

class AdminRatingsManagement extends StatefulWidget {
  const AdminRatingsManagement({super.key});

  @override
  State<AdminRatingsManagement> createState() => _AdminRatingsManagementState();
}

class _AdminRatingsManagementState extends State<AdminRatingsManagement> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _filterBy = 'all'; // all, doctor, app, low-ratings

  Stream<QuerySnapshot> _getRatingsStream() {
    Query query = _firestore
        .collection('consultation_ratings')
        .orderBy('ratedAt', descending: true)
        .limit(500);

    if (_filterBy == 'doctor') {
      // This would need a separate query - for now show all
      return query.snapshots();
    } else if (_filterBy == 'app') {
      return query.snapshots();
    } else if (_filterBy == 'low-ratings') {
      // Filter for ratings below 3 stars
      return query.snapshots();
    }

    return query.snapshots();
  }

  double _calculateOverallAverageRating(List<DocumentSnapshot> ratings) {
    if (ratings.isEmpty) return 0.0;
    double total = 0;
    for (var rating in ratings) {
      final data = rating.data() as Map<String, dynamic>;
      total += (data['doctorRating'] as num?)?.toDouble() ?? 0;
    }
    return total / ratings.length;
  }

  double _calculateAppAverageRating(List<DocumentSnapshot> ratings) {
    if (ratings.isEmpty) return 0.0;
    double total = 0;
    for (var rating in ratings) {
      final data = rating.data() as Map<String, dynamic>;
      total += (data['appRating'] as num?)?.toDouble() ?? 0;
    }
    return total / ratings.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rating Management'),
        backgroundColor: const Color(0xFF1565C0),
        elevation: 2,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getRatingsStream(),
        builder: (context, snapshot) {
          print('[AdminRatings] Stream state: ${snapshot.connectionState}');
          
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            print('[AdminRatings] Error: ${snapshot.error}');
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
          print('[AdminRatings] Loaded ${ratings.length} total ratings');
          
          final filteredRatings = _filterRatings(ratings);
          print('[AdminRatings] After filtering: ${filteredRatings.length} ratings (filter: $_filterBy)');

          if (filteredRatings.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text('No ratings found', style: TextStyle(fontSize: 16)),
                ],
              ),
            );
          }

          final doctorAvg = _calculateOverallAverageRating(filteredRatings);
          final appAvg = _calculateAppAverageRating(filteredRatings);

          return SingleChildScrollView(
            child: Column(
              children: [
                // Statistics Cards
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Top Stats
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Total Ratings',
                              filteredRatings.length.toString(),
                              const Color(0xFF4CAF50),
                              Icons.rate_review,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              'Doctor Avg',
                              doctorAvg.toStringAsFixed(1),
                              const Color(0xFFFF9800),
                              Icons.person,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              'App Avg',
                              appAvg.toStringAsFixed(1),
                              const Color(0xFF2196F3),
                              Icons.phone_android,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Filter Buttons
                      Row(
                        children: [
                          Expanded(
                            child: _buildFilterButton('All', 'all'),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildFilterButton('Low Ratings', 'low-ratings'),
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
                  itemCount: filteredRatings.length,
                  itemBuilder: (context, index) {
                    final ratingDoc = filteredRatings[index];
                    final data = ratingDoc.data() as Map<String, dynamic>;
                    return _buildRatingCard(data, ratingDoc.id);
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

  List<DocumentSnapshot> _filterRatings(List<DocumentSnapshot> ratings) {
    if (_filterBy == 'low-ratings') {
      return ratings.where((rating) {
        final data = rating.data() as Map<String, dynamic>;
        final doctorRating = data['doctorRating'] as num? ?? 0;
        return doctorRating < 3;
      }).toList();
    }
    return ratings;
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(icon, color: Colors.white, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String label, String value) {
    final isSelected = _filterBy == value;
    return GestureDetector(
      onTap: () {
        setState(() => _filterBy = value);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1565C0) : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF1565C0) : Colors.transparent,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[700],
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRatingCard(Map<String, dynamic> data, String docId) {
    final doctorRating = (data['doctorRating'] as num?)?.toInt() ?? 0;
    final appRating = (data['appRating'] as num?)?.toInt() ?? 0;
    final userName = data['userName'] as String? ?? 'Anonymous';
    final doctorName = data['doctorName'] as String? ?? 'Unknown Doctor';
    final animalName = data['animalName'] as String? ?? 'Unknown';
    final doctorFeedback = data['doctorFeedback'] as String? ?? '';
    final appFeedback = data['appFeedback'] as String? ?? '';
    final ratedAt = (data['ratedAt'] as Timestamp?)?.toDate();
    final appointmentId = data['appointmentId'] as String? ?? '';

    final isLowRating = doctorRating < 3;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(
          color: isLowRating ? Colors.red[300]! : Colors.grey[300]!,
          width: isLowRating ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
        color: isLowRating ? Colors.red[50] : Colors.white,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            userName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          if (isLowRating)
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(
                                  color: Colors.red[300],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  '⚠️ Low Rating',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '👨‍⚕️ Dr. ${doctorName} • 🐾 ${animalName}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                if (ratedAt != null)
                  Text(
                    _formatDate(ratedAt),
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: Colors.grey[200], height: 1),
            const SizedBox(height: 12),
            // Ratings
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Doctor Rating',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        ...List.generate(
                          5,
                          (index) => Icon(
                            index < doctorRating ? Icons.star : Icons.star_outline,
                            color: Colors.amber,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text('$doctorRating/5',
                            style: const TextStyle(fontWeight: FontWeight.bold))
                      ],
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('App Rating',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        ...List.generate(
                          5,
                          (index) => Icon(
                            index < appRating ? Icons.star : Icons.star_outline,
                            color: Colors.blue,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text('$appRating/5',
                            style: const TextStyle(fontWeight: FontWeight.bold))
                      ],
                    ),
                  ],
                ),
              ],
            ),
            // Feedback
            if (doctorFeedback.isNotEmpty || appFeedback.isNotEmpty) ...[
              const SizedBox(height: 12),
              if (doctorFeedback.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Doctor Feedback:',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              color: Colors.blue)),
                      const SizedBox(height: 4),
                      Text(doctorFeedback,
                          style: TextStyle(fontSize: 12, color: Colors.grey[700]))
                    ],
                  ),
                ),
              if (appFeedback.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('App Feedback:',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              color: Colors.green)),
                      const SizedBox(height: 4),
                      Text(appFeedback,
                          style: TextStyle(fontSize: 12, color: Colors.grey[700]))
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
