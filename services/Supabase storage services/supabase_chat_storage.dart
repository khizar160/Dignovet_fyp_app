import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseChatStorage {
  final SupabaseClient _client = Supabase.instance.client;

  Future<String> uploadImage(File file, String userId) async {
    final fileName =
        'chat_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';

    await _client.storage.from('Chat').upload(
          fileName,
          file,
          fileOptions: const FileOptions(upsert: true),
        );

    return _client.storage.from('Chat').getPublicUrl(fileName);
  }

  Future<String> uploadVideo(File file, String userId) async {
  final fileName =
      'chat_video_${userId}_${DateTime.now().millisecondsSinceEpoch}.mp4';

  await _client.storage.from('Chat').upload(
        fileName,
        file,
        fileOptions: const FileOptions(upsert: true),
      );

  return _client.storage.from('Chat').getPublicUrl(fileName);
}

}
