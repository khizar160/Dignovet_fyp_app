

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import '../../model/app_user.dart';
// import '../User/AppoiintmentBooking.dart';
// import '../../services/firebase_authentication/auth_api.dart';

// class AppointmentDashboardPage extends StatefulWidget {
//   const AppointmentDashboardPage({super.key});

//   @override
//   State<AppointmentDashboardPage> createState() => _AppointmentDashboardPageState();
// }

// class _AppointmentDashboardPageState extends State<AppointmentDashboardPage> {
//   String _selectedSpecialist = 'All Specialists';

//   final Color primaryTeal = const Color(0xFFB2DFDB);
//   final Color darkTeal = const Color(0xFF00796B);
//   final Color accentTeal = const Color(0xFF80CBC4);

//   final List<String> _specialties = [
//     'All Specialists',
//     'General Medicine',
//     'Surgery',
//     'Dermatology',
//     'Pathology',
//     'Cardiology',
//     'Orthopedics',
//   ];

//   @override
//   Widget build(BuildContext context) {
//     final currentUserId = AuthService.currentUser?.uid;

//     return Scaffold(
//       backgroundColor: primaryTeal,
//       appBar: _buildAppBar(),
//       body: SafeArea(
//         child: SingleChildScrollView(
//           physics: const BouncingScrollPhysics(),
//           padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               _buildSectionHeader('Appointment Dashboard', isMainTitle: true),
//               const SizedBox(height: 20),
//               _buildWelcomeCard(),
//               const SizedBox(height: 35),
//               _buildSectionHeader('Select Specialist'),
//               const SizedBox(height: 15),
//               _buildFilterList(),
//               const SizedBox(height: 25),
//               _buildDoctorsGrid(currentUserId ?? ''),
//               const SizedBox(height: 40),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   PreferredSizeWidget _buildAppBar() {
//     return AppBar(
//       backgroundColor: Colors.transparent,
//       elevation: 0,
//       leading: IconButton(
//         icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 22),
//         onPressed: () => Navigator.pop(context),
//       ),
//       title: const Text(
//         'DignoVet',
//         style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 24),
//       ),
//       centerTitle: true,
//       actions: [
//         _buildCircleAction(Icons.search),
//         _buildCircleAction(Icons.notifications_none),
//         const SizedBox(width: 10),
//       ],
//     );
//   }

//   Widget _buildCircleAction(IconData icon) {
//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 5),
//       decoration: BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
//       child: IconButton(
//         icon: Icon(icon, color: Colors.white, size: 22),
//         onPressed: () {},
//       ),
//     );
//   }

//   Widget _buildSectionHeader(String title, {bool isMainTitle = false}) {
//     return Text(
//       title,
//       style: TextStyle(
//         fontSize: isMainTitle ? 28 : 22,
//         fontWeight: FontWeight.bold,
//         color: isMainTitle ? Colors.white : Colors.teal[900],
//         letterSpacing: -0.5,
//       ),
//     );
//   }

//   Widget _buildWelcomeCard() {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(24),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(28),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.08),
//             blurRadius: 20,
//             offset: const Offset(0, 10),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           Expanded(
//             flex: 3,
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'Book an appointment with the best veterinarians.',
//                   style: TextStyle(fontSize: 16, color: Colors.grey[800], height: 1.5),
//                 ),
//                 const SizedBox(height: 15),
//                 Text(
//                   'Have a good Day!',
//                   style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: darkTeal),
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(width: 10),
//           Expanded(
//             flex: 2,
//             child: ClipRRect(
//               borderRadius: BorderRadius.circular(20),
//               child: Image.network(
//                 'https://img.freepik.com/free-vector/veterinarian-taking-care-dog_52683-50665.jpg?w=740',
//                 fit: BoxFit.cover,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildFilterList() {
//     return SizedBox(
//       height: 45,
//       child: ListView.builder(
//         scrollDirection: Axis.horizontal,
//         itemCount: _specialties.length,
//         itemBuilder: (context, index) {
//           final specialty = _specialties[index];
//           final isSelected = _selectedSpecialist == specialty;
//           return Padding(
//             padding: const EdgeInsets.only(right: 10),
//             child: ChoiceChip(
//               label: Text(specialty),
//               selected: isSelected,
//               onSelected: (val) => setState(() => _selectedSpecialist = specialty),
//               selectedColor: darkTeal,
//               backgroundColor: Colors.white,
//               labelStyle: TextStyle(
//                 color: isSelected ? Colors.white : darkTeal,
//                 fontWeight: FontWeight.w600,
//               ),
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
//               side: BorderSide(color: isSelected ? Colors.transparent : darkTeal),
//               showCheckmark: false,
//               elevation: isSelected ? 4 : 0,
//             ),
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildDoctorsGrid(String currentUserId) {
//     return StreamBuilder<QuerySnapshot>(
//       stream: FirebaseFirestore.instance
//           .collection('users')
//           .where('role', isEqualTo: 'doctor')
//           .where('profileCompleted', isEqualTo: true)
//           .snapshots(),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Center(child: CircularProgressIndicator());
//         }

//         if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//           return Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Icon(Icons.medical_services_outlined, size: 80, color: Colors.white70),
//                 const SizedBox(height: 16),
//                 const Text(
//                   'No doctors available',
//                   style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
//                 ),
//               ],
//             ),
//           );
//         }

//         // Convert to AppUser objects
//         final doctors = snapshot.data!.docs
//             .map((doc) => AppUser.fromMap(doc.data() as Map<String, dynamic>, doc.id))
//             .where((doctor) {
//               // Filter by specialization
//               if (_selectedSpecialist == 'All Specialists') return true;
//               return doctor.specialization == _selectedSpecialist;
//             })
//             .toList();

//         if (doctors.isEmpty) {
//           return Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Icon(Icons.search_off, size: 80, color: Colors.white70),
//                 const SizedBox(height: 16),
//                 Text(
//                   'No doctors found for $_selectedSpecialist',
//                   style: const TextStyle(fontSize: 16, color: Colors.white),
//                   textAlign: TextAlign.center,
//                 ),
//               ],
//             ),
//           );
//         }

//         return GridView.builder(
//           shrinkWrap: true,
//           physics: const NeverScrollableScrollPhysics(),
//           gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//             crossAxisCount: 2,
//             crossAxisSpacing: 16,
//             mainAxisSpacing: 16,
//             mainAxisExtent: 420,
//           ),
//           itemCount: doctors.length,
//           itemBuilder: (context, index) {
//             return _buildDoctorCard(doctors[index]);
//           },
//         );
//       },
//     );
//   }

//   Widget _buildDoctorCard(AppUser doctor) {
//     final availableDays = doctor.availableDays ?? [];
//     final availableSlots = doctor.availableSlots ?? [];
    
//     return GestureDetector(
//       onTap: () {
//         _showDoctorDetailsBottomSheet(doctor);
//       },
//       child: Container(
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(24),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.1),
//               blurRadius: 15,
//               offset: const Offset(0, 8),
//             ),
//           ],
//         ),
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             Container(
//               decoration: BoxDecoration(
//                 shape: BoxShape.circle,
//                 border: Border.all(color: accentTeal, width: 3),
//               ),
//               child: CircleAvatar(
//                 radius: 45,
//                 backgroundColor: primaryTeal.withOpacity(0.2),
//                 backgroundImage: doctor.imageUrl.isNotEmpty
//                     ? NetworkImage(doctor.imageUrl)
//                     : null,
//                 child: doctor.imageUrl.isEmpty
//                     ? Icon(Icons.person, color: darkTeal, size: 45)
//                     : null,
//               ),
//             ),
//             const SizedBox(height: 14),
//             Text(
//               doctor.name,
//               style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
//               textAlign: TextAlign.center,
//               maxLines: 1,
//               overflow: TextOverflow.ellipsis,
//             ),
//             const SizedBox(height: 4),
//             Text(
//               doctor.specialization ?? 'Veterinarian',
//               style: TextStyle(color: Colors.grey[700], fontSize: 13, fontWeight: FontWeight.w500),
//               textAlign: TextAlign.center,
//               maxLines: 1,
//               overflow: TextOverflow.ellipsis,
//             ),
//             const SizedBox(height: 8),
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//               decoration: BoxDecoration(
//                 color: accentTeal.withOpacity(0.2),
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Text(
//                 '${doctor.experience ?? 0} Years Exp.',
//                 style: TextStyle(color: darkTeal, fontSize: 12, fontWeight: FontWeight.w600),
//               ),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               doctor.clinicName ?? 'N/A',
//               style: const TextStyle(color: Colors.grey, fontSize: 12),
//               textAlign: TextAlign.center,
//               maxLines: 2,
//               overflow: TextOverflow.ellipsis,
//             ),
//             const SizedBox(height: 12),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
//                 const SizedBox(width: 4),
//                 Text(
//                   '${availableDays.length} days',
//                   style: TextStyle(color: Colors.grey[600], fontSize: 11),
//                 ),
//                 const SizedBox(width: 12),
//                 Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
//                 const SizedBox(width: 4),
//                 Text(
//                   '${availableSlots.length} slots',
//                   style: TextStyle(color: Colors.grey[600], fontSize: 11),
//                 ),
//               ],
//             ),
//             const Spacer(),
//             ElevatedButton(
//               onPressed: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (_) => BookAppointmentPage(
//                       doctor: doctor,
//                     ),
//                   ),
//                 );
//               },
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: accentTeal,
//                 foregroundColor: Colors.white,
//                 elevation: 2,
//                 minimumSize: const Size(double.infinity, 42),
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
//               ),
//               child: const Text('Book Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _showDoctorDetailsBottomSheet(AppUser doctor) {
//     final availableDays = doctor.availableDays ?? [];
//     final availableSlots = doctor.availableSlots ?? [];
    
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
//       ),
//       builder: (context) => DraggableScrollableSheet(
//         initialChildSize: 0.75,
//         minChildSize: 0.5,
//         maxChildSize: 0.95,
//         expand: false,
//         builder: (context, scrollController) => Container(
//           padding: const EdgeInsets.all(24),
//           child: SingleChildScrollView(
//             controller: scrollController,
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Center(
//                   child: Container(
//                     width: 50,
//                     height: 5,
//                     decoration: BoxDecoration(
//                       color: Colors.grey[300],
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//                 Row(
//                   children: [
//                     Container(
//                       decoration: BoxDecoration(
//                         shape: BoxShape.circle,
//                         border: Border.all(color: accentTeal, width: 3),
//                       ),
//                       child: CircleAvatar(
//                         radius: 45,
//                         backgroundColor: primaryTeal.withOpacity(0.2),
//                         backgroundImage: doctor.imageUrl.isNotEmpty
//                             ? NetworkImage(doctor.imageUrl)
//                             : null,
//                         child: doctor.imageUrl.isEmpty
//                             ? Icon(Icons.person, color: darkTeal, size: 45)
//                             : null,
//                       ),
//                     ),
//                     const SizedBox(width: 16),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             doctor.name,
//                             style: const TextStyle(
//                               fontSize: 22,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                           const SizedBox(height: 4),
//                           Text(
//                             doctor.specialization ?? 'Veterinarian',
//                             style: TextStyle(
//                               fontSize: 16,
//                               color: Colors.grey[700],
//                               fontWeight: FontWeight.w500,
//                             ),
//                           ),
//                           const SizedBox(height: 4),
//                           Text(
//                             '${doctor.experience ?? 0} Years Experience',
//                             style: TextStyle(
//                               fontSize: 14,
//                               color: Colors.grey[600],
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 24),
//                 const Divider(),
//                 const SizedBox(height: 16),
//                 _detailSection(
//                   icon: Icons.location_on,
//                   title: 'Clinic',
//                   content: doctor.clinicName ?? 'N/A',
//                 ),
//                 const SizedBox(height: 12),
//                 _detailSection(
//                   icon: Icons.map,
//                   title: 'Address',
//                   content: doctor.clinicAddress ?? 'N/A',
//                 ),
//                 const SizedBox(height: 12),
//                 _detailSection(
//                   icon: Icons.phone,
//                   title: 'Phone',
//                   content: doctor.phone.isNotEmpty ? doctor.phone : 'Not provided',
//                 ),
//                 const SizedBox(height: 12),
//                 _detailSection(
//                   icon: Icons.info_outline,
//                   title: 'About',
//                   content: doctor.about?.isNotEmpty == true ? doctor.about! : 'No description available',
//                 ),
//                 const SizedBox(height: 20),
//                 const Text(
//                   'Available Days',
//                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                 ),
//                 const SizedBox(height: 12),
//                 Wrap(
//                   spacing: 8,
//                   runSpacing: 8,
//                   children: availableDays.map((day) {
//                     return Container(
//                       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                       decoration: BoxDecoration(
//                         color: accentTeal.withOpacity(0.2),
//                         borderRadius: BorderRadius.circular(12),
//                         border: Border.all(color: accentTeal),
//                       ),
//                       child: Text(
//                         day,
//                         style: TextStyle(
//                           color: darkTeal,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     );
//                   }).toList(),
//                 ),
//                 const SizedBox(height: 20),
//                 const Text(
//                   'Available Slots',
//                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                 ),
//                 const SizedBox(height: 12),
//                 Wrap(
//                   spacing: 8,
//                   runSpacing: 8,
//                   children: availableSlots.map((slot) {
//                     return Container(
//                       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: BorderRadius.circular(12),
//                         border: Border.all(color: darkTeal),
//                       ),
//                       child: Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           Icon(Icons.access_time, size: 16, color: darkTeal),
//                           const SizedBox(width: 6),
//                           Text(
//                             slot,
//                             style: TextStyle(
//                               color: darkTeal,
//                               fontWeight: FontWeight.w600,
//                             ),
//                           ),
//                         ],
//                       ),
//                     );
//                   }).toList(),
//                 ),
//                 const SizedBox(height: 30),
//                 SizedBox(
//                   width: double.infinity,
//                   height: 55,
//                   child: ElevatedButton(
//                     onPressed: () {
//                       Navigator.pop(context);
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (_) => BookAppointmentPage(
//                             doctor: doctor,
//                           ),
//                         ),
//                       );
//                     },
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: darkTeal,
//                       foregroundColor: Colors.white,
//                       elevation: 3,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(15),
//                       ),
//                     ),
//                     child: const Text(
//                       'Book Appointment',
//                       style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _detailSection({required IconData icon, required String title, required String content}) {
//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Icon(icon, color: darkTeal, size: 22),
//         const SizedBox(width: 12),
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 title,
//                 style: TextStyle(
//                   fontSize: 14,
//                   fontWeight: FontWeight.w600,
//                   color: Colors.grey[600],
//                 ),
//               ),
//               const SizedBox(height: 4),
//               Text(
//                 content,
//                 style: const TextStyle(
//                   fontSize: 15,
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
// }


// ------------------improve ui code-------------
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../model/app_user.dart';
import '../User/AppoiintmentBooking.dart';
import '../../services/firebase_authentication/auth_api.dart';
import '../../provider/language_provider.dart';

class AppointmentDashboardPage extends StatefulWidget {
  const AppointmentDashboardPage({super.key});

  @override
  State<AppointmentDashboardPage> createState() => _AppointmentDashboardPageState();
}

class _AppointmentDashboardPageState extends State<AppointmentDashboardPage> {
  String _selectedSpecialist = 'All Specialists';

  // Your color scheme
  final Color primaryDark = const Color(0xFF00796B);
  final Color primaryMedium = const Color(0xFF4DB6AC);
  final Color primaryLight = const Color(0xFF80CBC4);
  final Color darkText = const Color(0xFF2C3E50);

  final List<String> _specialties = [
    'All Specialists',
    'General Medicine',
    'Surgery',
    'Dermatology',
    'Pathology',
    'Cardiology',
    'Orthopedics',
  ];

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final currentUserId = AuthService.currentUser?.uid;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              primaryDark,
              primaryMedium,
              primaryLight,
            ],
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
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        _buildWelcomeCard(languageProvider),
                        const SizedBox(height: 32),
                        Text(
                          languageProvider.t('Select Specialist', 'ماہر منتخب کریں'),
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: darkText,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _buildFilterList(languageProvider),
                        const SizedBox(height: 24),
                        _buildDoctorsGrid(currentUserId ?? '', languageProvider),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(LanguageProvider languageProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
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
              const SizedBox(width: 12),
              Text(
                languageProvider.translate('book_appointment'),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  letterSpacing: -0.5,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Row(
            children: [
              _buildAppBarIcon(Icons.search),
              const SizedBox(width: 8),
              _buildAppBarIcon(Icons.notifications_outlined),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppBarIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: 22,
      ),
    );
  }

  Widget _buildWelcomeCard(LanguageProvider languageProvider) {
    return Container(
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
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  languageProvider.t('Book an appointment with the best veterinarians.', 'بہترین ویٹرنریرین کے ساتھ اپائنٹمنٹ بک کریں۔'),
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[700],
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  languageProvider.t('Have a good Day!', 'آپ کا دن اچھا گزرے!'),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: darkText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: primaryDark.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  'https://img.freepik.com/free-vector/veterinarian-taking-care-dog_52683-50665.jpg?w=740',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterList(LanguageProvider languageProvider) {
    return SizedBox(
      height: 45,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _specialties.length,
        itemBuilder: (context, index) {
          final specialty = _specialties[index];
          final isSelected = _selectedSpecialist == specialty;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () => setState(() => _selectedSpecialist = specialty),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          colors: [primaryDark, primaryMedium],
                        )
                      : null,
                  color: isSelected ? null : Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: isSelected ? Colors.transparent : primaryDark.withOpacity(0.3),
                    width: 1.5,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: primaryDark.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                child: Center(
                  child: Text(
                    specialty,
                    style: TextStyle(
                      color: isSelected ? Colors.white : primaryDark,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDoctorsGrid(String currentUserId, LanguageProvider languageProvider) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'doctor')
          .where('profileCompleted', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(primaryDark),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.medical_services_outlined, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  languageProvider.t('No doctors available', 'کوئی ڈاکٹر دستیاب نہیں'),
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }

        final doctors = snapshot.data!.docs
            .map((doc) => AppUser.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .where((doctor) {
          if (_selectedSpecialist == 'All Specialists') return true;
          return doctor.specialization == _selectedSpecialist;
        }).toList();

        if (doctors.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  languageProvider.t('No doctors found for\n$_selectedSpecialist', '$_selectedSpecialist کے لیے کوئی ڈاکٹر نہیں ملا'),
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            mainAxisExtent: 400,
          ),
          itemCount: doctors.length,
          itemBuilder: (context, index) {
            return _buildDoctorCard(doctors[index]);
          },
        );
      },
    );
  }

  Widget _buildDoctorCard(AppUser doctor) {
    final availableDays = doctor.availableDays ?? [];
    final availableSlots = doctor.availableSlots ?? [];

    return GestureDetector(
      onTap: () => _showDoctorDetailsBottomSheet(doctor),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: primaryLight.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: primaryDark.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [primaryMedium.withOpacity(0.3), primaryLight.withOpacity(0.2)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryDark.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 45,
                backgroundColor: Colors.transparent,
                backgroundImage: doctor.imageUrl.isNotEmpty ? NetworkImage(doctor.imageUrl) : null,
                child: doctor.imageUrl.isEmpty
                    ? Icon(Icons.person, color: primaryDark, size: 45)
                    : null,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              doctor.name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
                color: darkText,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              doctor.specialization ?? 'Veterinarian',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryDark.withOpacity(0.1), primaryMedium.withOpacity(0.1)],
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: primaryDark.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Text(
                '${doctor.experience ?? 0} Years Exp.',
                style: TextStyle(
                  color: primaryDark,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              doctor.clinicName ?? 'N/A',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: primaryLight.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today, size: 14, color: primaryDark),
                  const SizedBox(width: 1),
                  Text(
                    '${availableDays.length} days',
                    style: TextStyle(
                      color: primaryDark,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.access_time, size: 14, color: primaryDark),
                  const SizedBox(width: 4),
                  Text(
                    '${availableSlots.length} slots',
                    style: TextStyle(
                      color: primaryDark,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                gradient: LinearGradient(
                  colors: [primaryDark, primaryMedium],
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryDark.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BookAppointmentPage(doctor: doctor),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  minimumSize: const Size(double.infinity, 42),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Text(
                  'Book Now',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDoctorDetailsBottomSheet(AppUser doctor) {
    final availableDays = doctor.availableDays ?? [];
    final availableSlots = doctor.availableSlots ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) => Container(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              controller: scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              primaryMedium.withOpacity(0.3),
                              primaryLight.withOpacity(0.2)
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: primaryDark.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 45,
                          backgroundColor: Colors.transparent,
                          backgroundImage: doctor.imageUrl.isNotEmpty
                              ? NetworkImage(doctor.imageUrl)
                              : null,
                          child: doctor.imageUrl.isEmpty
                              ? Icon(Icons.person, color: primaryDark, size: 45)
                              : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              doctor.name,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: darkText,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              doctor.specialization ?? 'Veterinarian',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    primaryDark.withOpacity(0.1),
                                    primaryMedium.withOpacity(0.1)
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${doctor.experience ?? 0} Years Experience',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: primaryDark,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Divider(color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  _detailSection(
                    icon: Icons.location_on,
                    title: 'Clinic',
                    content: doctor.clinicName ?? 'N/A',
                  ),
                  const SizedBox(height: 12),
                  _detailSection(
                    icon: Icons.map,
                    title: 'Address',
                    content: doctor.clinicAddress ?? 'N/A',
                  ),
                  const SizedBox(height: 12),
                  _detailSection(
                    icon: Icons.phone,
                    title: 'Phone',
                    content: doctor.phone.isNotEmpty ? doctor.phone : 'Not provided',
                  ),
                  const SizedBox(height: 12),
                  _detailSection(
                    icon: Icons.info_outline,
                    title: 'About',
                    content: doctor.about?.isNotEmpty == true
                        ? doctor.about!
                        : 'No description available',
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Available Days',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: darkText,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: availableDays.map((day) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              primaryDark.withOpacity(0.1),
                              primaryMedium.withOpacity(0.1)
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: primaryDark.withOpacity(0.3)),
                        ),
                        child: Text(
                          day,
                          style: TextStyle(
                            color: primaryDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Available Slots',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: darkText,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: availableSlots.map((slot) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: primaryDark, width: 1.5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.access_time, size: 16, color: primaryDark),
                            const SizedBox(width: 6),
                            Text(
                              slot,
                              style: TextStyle(
                                color: primaryDark,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 30),
                  Container(
                    width: double.infinity,
                    height: 55,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      gradient: LinearGradient(
                        colors: [primaryDark, primaryMedium],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: primaryDark.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BookAppointmentPage(doctor: doctor),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: const Text(
                        'Book Appointment',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailSection({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryDark.withOpacity(0.1), primaryMedium.withOpacity(0.1)],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: primaryDark, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                content,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: darkText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}