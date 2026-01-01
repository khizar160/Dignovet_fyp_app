// import 'dart:convert';
// import 'dart:developer';
// import 'package:http/http.dart' as http;
// class GeminiService {
//   // 1. GENERATE A NEW KEY AND PASTE IT HERE
//   static const String _apiKey = 'AIzaSyA6FF6oPR9PSvo4ENgu6Q97TZUXGdPz7yo'; 
  
//   // 2. USE A VALID 2025 MODEL
//   static const String _model = 'gemini-2.0-flash'; 
//   static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent';

//   Future<String> sendMessage(String message) async {
//     try {
//       final response = await http.post(
//         Uri.parse('$_baseUrl?key=$_apiKey'),
//         headers: {'Content-Type': 'application/json'},
//         body: jsonEncode({
//           "contents": [
//             {"parts": [{"text": message}]}
//           ]
//         }),
//       );

//       final data = jsonDecode(response.body);

//       if (response.statusCode == 200) {
//         return data['candidates'][0]['content']['parts'][0]['text'];
//       } else if (response.statusCode == 429) {
//         // This is the Quota error you saw
//         return "Error: I'm talking too fast! Please wait a minute before trying again.";
//       } else if (response.statusCode == 404) {
//         return "Error: Model not found. Please check the model name (Gemini 1.5 is retired).";
//       } else {
//         log('Error Body: ${response.body}');
//         throw Exception(data['error']['message'] ?? 'Unknown Error');
//       }
//     } catch (e) {
//       log('GeminiService Exception: $e');
//       rethrow;
//     }
//   }
// }

import 'dart:convert';
import 'package:http/http.dart' as http;

class GroqService {
  static const String _apiKey = "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";
  static const String _url = "https://api.groq.com/openai/v1/chat/completions";

  Future<String> sendMessage(String message) async {
    try {
      final response = await http.post(
        Uri.parse(_url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
      body: jsonEncode({
  "model": "llama-3.1-8b-instant",
  "messages": [
    {
      "role": "system",
      "content": """You are a professional veterinary medical assistant specialized in animal diseases and health conditions. 

STRICT GUIDELINES:
1. You MUST ONLY discuss topics related to:
   - Animal diseases (livestock, poultry, pets)
   - Foot and Mouth Disease (FMD)
   - Other veterinary medical conditions
   - Animal symptoms and diagnoses
   - Treatment recommendations for animals
   - Animal health management
   - Veterinary medical procedures

2. If the user asks about ANYTHING else (general chat, non-animal topics, human health, weather, news, etc.), you MUST politely decline and redirect them back to animal health topics.

3. Your response format when declining off-topic questions:
   "I apologize, but I am a specialized veterinary medical assistant. I can only help with animal diseases and health-related questions. Please ask me about animal health concerns, symptoms, or diseases like Foot and Mouth Disease, and I'll be happy to assist you."

4. Always maintain a professional, medical tone.
5. Provide accurate, evidence-based veterinary information.
6. Never discuss topics outside veterinary medicine."""
    },
    {"role": "user", "content": message}
  ],
  "temperature": 0.7
}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["choices"][0]["message"]["content"];
      } else {
        return "Error: ${response.statusCode} ${response.body}";
      }
    } catch (e) {
      return "Exception: $e";
    }
  }
}

