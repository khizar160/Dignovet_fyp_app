// import 'dart:developer';

// import 'package:flutter/material.dart';

// import 'package:flutter_application_1/view/User/BookAppointment.dart';
// import 'package:flutter_application_1/view/User/DiseasePrediction.dart';
// import 'package:flutter_application_1/view/User/Notifications.dart';
// import 'package:flutter_application_1/view/User/Profile.dart';
// import 'package:flutter_application_1/view/User/RegisterAnimal.dart';
// import 'package:flutter_application_1/view/User/AnimalHistory.dart';
// import 'package:flutter_application_1/view/User/MyAppointments.dart';
// import 'package:flutter_application_1/view/chat_screen/chat_screen.dart'; // for navigation

// class UserDashboardPage extends StatelessWidget {
//    UserDashboardPage({super.key});

//   // List of dashboard items (without Logout)
//   final List<Map<String, dynamic>> _dashboardItems =  [
//     {
//       'title': 'Register Animal',
//       'icon': Icons.pets,
//       'onTap': null

//     },
//     {
//       'title': 'Predict Disease',
//       'icon': Icons.search,
//       'onTap': null,
//     },
//     {
//       'title': 'Book Appointment',
//       'icon': Icons.calendar_today,
//       'onTap': null,
//     },
//     {
//       'title': 'My Appointments',
//       'icon': Icons.schedule,
//       'onTap': null,
//     },
//     {
//       'title': 'View History',
//       'icon': Icons.history,
//       'onTap': null,
//     },
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
//           onPressed: () {
//             Navigator.pop(context);
//           },
//         ),
//         title: const Text(
//           'DignoVet',
//           style: TextStyle(
//             color: Colors.black,
//             fontWeight: FontWeight.bold,
//             fontSize: 20,
//           ),
//         ),
//         actions: [
//           // Search icon removed as per your request
//           IconButton(
//             icon: const Icon(Icons.notifications_outlined, color: Colors.black),
//              onPressed: ()
//             {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (context) =>  NotificationsPage()),
//               );
//             },
//           ),
//           IconButton(
//             icon: const Icon(Icons.person_outline, color: Colors.black),
//             // onPressed: ()async {
//             //   log(  'User Logged Out');
//             //  await AuthService().signOut();
//             //   // Profile or settings
//             // },
//             onPressed: ()
//             {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (context) =>  EditProfilePage()),
//               );
//             },
//           ),
//           const SizedBox(width: 8),
//         ],
//       ),
//       floatingActionButton: FloatingActionButton(
//         backgroundColor: Colors.teal,

//          child:  Icon(Icons.chat)
//         ,onPressed: () async {
//         log('User Logged Out');
//         Navigator.push(context,MaterialPageRoute(builder: (context) =>  DignoVetChatScreen()));
//       },),
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 24.0),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               const SizedBox(height: 30),
//               const Text(
//                 'Dashboard',
//                 style: TextStyle(
//                   fontSize: 32,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.black,
//                 ),
//               ),
//               const SizedBox(height: 40),

//               // Main card with rounded corners and light gray background
//               Container(
//                 decoration: BoxDecoration(
//                   color: const Color(0xFFF0F4F3), // Very light gray-green background
//                   borderRadius: BorderRadius.circular(30),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.grey.withOpacity(0.2),
//                       spreadRadius: 5,
//                       blurRadius: 15,
//                       offset: const Offset(0, 5),
//                     ),
//                   ],
//                 ),
//                 padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
//                 child: ListView.separated(
//                   shrinkWrap: true,
//                   physics: const NeverScrollableScrollPhysics(),
//                   itemCount: _dashboardItems.length,
//                   separatorBuilder: (context, index) => const SizedBox(height: 20),
//                   itemBuilder: (context, index) {
//                     final item = _dashboardItems[index];
//                     return GestureDetector(
//                       onTap: item['onTap'] ?? () {
//                         // Default tap action - you can add navigation here
//                         if (index == 0) {
//                           Navigator.push(context, MaterialPageRoute(builder: (context) => RegisterAnimalPage()));
//                         }
//                         else if(index == 1){
//                           // Navigate to Predict Disease Page
//                                 Navigator.push(
//                                 context,
//                                MaterialPageRoute(builder: (context) =>  DiseasePredictionPage()),
//                               );
//                         }
//                         else if(index == 2){
//                           // Navigate to Book Appointment Page
//                            Navigator.push(
//                                 context,
//                                MaterialPageRoute(builder: (context) => AppointmentDashboardPage()),
//                               );
//                         }
//                         else if(index == 3){
//                           // Navigate to My Appointments Page
//                             Navigator.push(
//                                 context,
//                                MaterialPageRoute(builder: (context) => MyAppointmentsPage()),
//                               );
//                         }
//                         else if(index == 4){
//                           // Navigate to View History Page
//                             Navigator.push(
//                                 context,
//                                MaterialPageRoute(builder: (context) => AnimalHistoryPage()),
//                               );
//                         }

//                       },
//                       child: Container(
//                         height: 70,
//                         decoration: BoxDecoration(
//                           color: const Color(0xFF80CBC4), // Teal button color matching your theme
//                           borderRadius: BorderRadius.circular(35),
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.black.withOpacity(0.1),
//                               blurRadius: 8,
//                               offset: const Offset(0, 4),
//                             ),
//                           ],
//                         ),
//                         child: Center(
//                           child: Row(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               Icon(
//                                 item['icon'],
//                                 color: Colors.black87,
//                                 size: 28,
//                               ),
//                               const SizedBox(width: 16),
//                               Text(
//                                 item['title'],
//                                 style: const TextStyle(
//                                   fontSize: 20,
//                                   fontWeight: FontWeight.bold,
//                                   color: Colors.black87,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//               ),
//               const SizedBox(height: 30),
//             ],
//           ),
//         ),
//       ),

//       // Optional: Bottom navigation bar (your screenshot has dots)

//     );
//   }
// }

// ----------------Better interface below------------------

import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/provider/language_provider.dart';
import 'package:flutter_application_1/view/User/BookAppointment.dart';
import 'package:flutter_application_1/view/User/DiseasePrediction.dart';
import 'package:flutter_application_1/view/User/Notifications.dart';
import 'package:flutter_application_1/view/User/Profile.dart';
import 'package:flutter_application_1/view/User/RegisterAnimal.dart';
import 'package:flutter_application_1/view/User/AnimalHistory.dart';
import 'package:flutter_application_1/view/User/MyAppointments.dart';
import 'package:flutter_application_1/view/User/UserSettingsPage.dart';
import 'package:flutter_application_1/view/chat_screen/chat_screen.dart';

class UserDashboardPage extends StatefulWidget {
  const UserDashboardPage({super.key});

  @override
  State<UserDashboardPage> createState() => _UserDashboardPageState();
}

class _UserDashboardPageState extends State<UserDashboardPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<Map<String, dynamic>> _dashboardItems = [
    {
      'title': 'Register Animal',
      'subtitle': 'Add your pet to the system',
      'icon': Icons.pets,
      'gradient': [Color(0xFF00796B), Color(0xFF4DB6AC)],
    },
    {
      'title': 'Predict Disease',
      'subtitle': 'AI-powered diagnosis',
      'icon': Icons.search,
      'gradient': [Color(0xFF00796B), Color(0xFF4DB6AC)],
    },
    {
      'title': 'Book Appointment',
      'subtitle': 'Schedule with a doctor',
      'icon': Icons.calendar_today,
      'gradient': [Color(0xFF00796B), Color(0xFF4DB6AC)],
    },
    {
      'title': 'My Appointments',
      'subtitle': 'View upcoming visits',
      'icon': Icons.schedule,
      'gradient': [Color(0xFF00796B), Color(0xFF4DB6AC)],
    },
    {
      'title': 'View History',
      'subtitle': 'Pet medical records',
      'icon': Icons.history,
      'gradient': [Color(0xFF00796B), Color(0xFF4DB6AC)],
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _navigateToPage(int index) {
    final routes = [
      () => RegisterAnimalPage(),
      () => DiseasePredictionPage(),
      () => AppointmentDashboardPage(),
      () => MyAppointmentsPage(),
      () => AnimalHistoryPage(),
    ];

    if (index < routes.length) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => routes[index]()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        // Update dashboard items with translations
        final dashboardItems = [
          {
            'title': languageProvider.translate('register_animal'),
            'subtitle': languageProvider.translate('register_animal_subtitle'),
            'icon': Icons.pets,
            'gradient': [Color(0xFF00796B), Color(0xFF4DB6AC)],
          },
          {
            'title': languageProvider.translate('predict_disease'),
            'subtitle': languageProvider.translate('predict_disease_subtitle'),
            'icon': Icons.search,
            'gradient': [Color(0xFF00796B), Color(0xFF4DB6AC)],
          },
          {
            'title': languageProvider.translate('book_appointment'),
            'subtitle': languageProvider.translate('book_appointment_subtitle'),
            'icon': Icons.calendar_today,
            'gradient': [Color(0xFF00796B), Color(0xFF4DB6AC)],
          },
          {
            'title': languageProvider.translate('my_appointments'),
            'subtitle': languageProvider.translate('my_appointments_subtitle'),
            'icon': Icons.schedule,
            'gradient': [Color(0xFF00796B), Color(0xFF4DB6AC)],
          },
          {
            'title': languageProvider.translate('view_history'),
            'subtitle': languageProvider.translate('view_history_subtitle'),
            'icon': Icons.history,
            'gradient': [Color(0xFF00796B), Color(0xFF4DB6AC)],
          },
        ];

        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF00796B),
                  const Color(0xFF4DB6AC),
                  const Color(0xFF80CBC4),
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _buildAppBar(languageProvider),
                  Expanded(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Container(
                          margin: const EdgeInsets.only(top: 20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(30),
                              topRight: Radius.circular(30),
                            ),
                          ),
                          child: _buildDashboardContent(
                            languageProvider,
                            dashboardItems,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          floatingActionButton: _buildFloatingActionButton(languageProvider),
        );
      },
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
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.pets,
                  color: Color(0xFF00796B),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                languageProvider.translate('app_name'),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
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
              _buildAppBarIcon(Icons.settings_outlined, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UserSettingsPage(),
                  ),
                );
              }),
              const SizedBox(width: 8),
              _buildAppBarIcon(Icons.notifications_outlined, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => NotificationsPage()),
                );
              }),
              const SizedBox(width: 8),
              _buildAppBarIcon(Icons.person_outline, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => EditProfilePage()),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppBarIcon(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }

  Widget _buildDashboardContent(
    LanguageProvider languageProvider,
    List<Map<String, dynamic>> dashboardItems,
  ) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            _buildWelcomeSection(languageProvider),
            const SizedBox(height: 32),
            Text(
              languageProvider.translate('dashboard'),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 16),
            _buildDashboardGrid(dashboardItems),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(LanguageProvider languageProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF00796B).withOpacity(0.1),
            const Color(0xFF4DB6AC).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF00796B).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF00796B),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00796B).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.waving_hand, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  languageProvider.translate('welcome_back'),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  languageProvider.translate('explore_services'),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardGrid(List<Map<String, dynamic>> dashboardItems) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: dashboardItems.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final item = dashboardItems[index];
        return TweenAnimationBuilder(
          tween: Tween<double>(begin: 0, end: 1),
          duration: Duration(milliseconds: 400 + (index * 100)),
          curve: Curves.easeOutCubic,
          builder: (context, double value, child) {
            return Transform.scale(
              scale: value,
              child: Opacity(
                opacity: value,
                child: _buildDashboardCard(item, index),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDashboardCard(Map<String, dynamic> item, int index) {
    return GestureDetector(
      onTap: () => _navigateToPage(index),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: item['gradient'],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00796B).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Icon(item['icon'], color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['title'],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['subtitle'],
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white.withOpacity(0.8),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton(LanguageProvider languageProvider) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF00796B), Color(0xFF4DB6AC)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00796B).withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        backgroundColor: Colors.transparent,
        elevation: 0,
        onPressed: () {
          log('Opening Chat');
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => DignoVetChatScreen()),
          );
        },
        icon: const Icon(Icons.chat_bubble_outline, size: 22),
        label: Text(
          languageProvider.translate('chat'),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}
