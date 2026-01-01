import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/model/app_user.dart';
import 'package:flutter_application_1/services/chat_services/chat_services.dart';
import 'package:flutter_application_1/services/firebase_authentication/auth_api.dart';
import 'package:flutter_application_1/view/User/ChatScreen.dart';// Your existing chat screen

class DoctorChatListScreen extends StatelessWidget {
  const DoctorChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final doctorId = AuthService.currentUser?.uid; 

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        backgroundColor: Colors.teal,
      ),
 body:   StreamBuilder<List<String>>(
  stream: ChatService().getChatUsers(doctorId??""),
  builder: (context, snapshot) {
    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
    final userIds = snapshot.data!;
    if (userIds.isEmpty) return const Center(child: Text('No chats yet'));

    return ListView.builder(
      itemCount: userIds.length,
      itemBuilder: (context, index) {
        final userId = userIds[index];

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
          builder: (context, userSnapshot) {
            if (!userSnapshot.hasData) return const SizedBox();
            final user = AppUser.fromMap(
                userSnapshot.data!.data() as Map<String, dynamic>, userSnapshot.data!.id);

            return ListTile(
              leading: CircleAvatar(backgroundImage: NetworkImage(user.imageUrl)),
              title: Text(user.name),
              subtitle: Text(user.online ? 'Online' : 'Offline'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      receiverId: userId,
                      receiverName: user.name,
                      receiverImage: user.imageUrl,
                      isOnline: user.online,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  },
)



    );
  }
}