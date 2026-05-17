import 'dart:async';
import 'api_service.dart';

class ChatService {
  // Start or get chat
  Future<String?> startOrGetChat(String otherUserId, String otherUserName) async {
    try {
      final response = await ApiService().dio.post('/chats', data: {
        'otherUserId': otherUserId,
        'otherUserName': otherUserName,
      });
      if (response.data['success'] == true) {
        return response.data['data']['chatId'];
      }
      return null;
    } catch (e) {
      print('Error starting chat: $e');
      return null;
    }
  }

  // Get My Chats
  Stream<List<Map<String, dynamic>>> getMyChats() async* {
    while (true) {
      try {
        final response = await ApiService().dio.get('/chats');
        if (response.data['success'] == true) {
          List<dynamic> data = response.data['data'];
          yield data.cast<Map<String, dynamic>>();
        } else {
          yield [];
        }
      } catch (e) {
        print('Error getting my chats: $e');
        yield [];
      }
      await Future.delayed(const Duration(seconds: 5)); // Polling
    }
  }

  // Get Chat By Id (Messages)
  Stream<List<Map<String, dynamic>>> getChatMessages(String chatId) async* {
    while (true) {
      try {
        final response = await ApiService().dio.get('/chats/$chatId');
        if (response.data['success'] == true) {
          List<dynamic> messages = response.data['data']['messages'];
          yield messages.cast<Map<String, dynamic>>().reversed.toList();
        } else {
          yield [];
        }
      } catch (e) {
        print('Error getting chat messages: $e');
        yield [];
      }
      await Future.delayed(const Duration(seconds: 3)); // Polling
    }
  }

  // Send Message
  Future<bool> sendMessage(String chatId, String text) async {
    try {
      final response = await ApiService().dio.post('/chats/$chatId/messages', data: {
        'type': 'text',
        'text': text,
      });
      return response.data['success'] == true;
    } catch (e) {
      print('Error sending message: $e');
      return false;
    }
  }
}
