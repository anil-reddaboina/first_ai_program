import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ollama_mobile/models/message.dart';
import 'package:ollama_mobile/services/location_service.dart';
import 'package:provider/provider.dart';
import 'dart:async'; // Import for StreamSubscription

class ChatProvider with ChangeNotifier {
  final List<Message> _messages = [];
  bool _isLoading = false;
  String _error = '';
  final String _baseUrl = 'http://localhost:11434/api'; // Direct Ollama endpoint
  LocationService? _locationService;
  
  StreamSubscription? _currentResponseSubscription; // To manage the streaming response

  List<Message> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  String get error => _error;

  ChatProvider() {
    _loadMessages();
  }

  void setLocationService(LocationService locationService) {
    _locationService = locationService;
  }

  Future<void> _loadMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messagesJson = prefs.getStringList('messages') ?? [];
      _messages.clear();
      _messages.addAll(
        messagesJson.map((json) => Message.fromJson(jsonDecode(json))),
      );
      notifyListeners();
    } catch (e) {
      _error = 'Error loading messages: $e';
      notifyListeners();
    }
  }

  Future<void> _saveMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messagesJson = _messages
          .map((message) => jsonEncode(message.toJson()))
          .toList();
      await prefs.setStringList('messages', messagesJson);
    } catch (e) {
      _error = 'Error saving messages: $e';
      notifyListeners();
    }
  }

  Future<void> sendMessage(String content) async {
    if (_isLoading) return; // Prevent sending multiple messages at once
    if (content.trim().isEmpty) return;

    final userMessage = Message(
      content: content,
      timestamp: DateTime.now(),
      role: 'user',
    );

    _messages.add(userMessage);
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final systemPrompt = "You are a helpful assistant. Always reply in the user's language.";
      final messages = [
        {"role": "system", "content": systemPrompt},
        {"role": "user", "content": content}
      ];
      final request = http.Request('POST', Uri.parse('$_baseUrl/chat'))
        ..headers['Content-Type'] = 'application/json'
        ..body = jsonEncode({
          'model': 'gemma3:1b',
          'messages': messages,
          'stream': true,
        });

      final response = await request.send();
      if (response.statusCode == 200) {
        String buffer = '';
        
        _currentResponseSubscription = response.stream
            .transform(utf8.decoder)
            .listen(
              (chunk) {
                buffer += chunk;
                final lines = buffer.split('\n');
                buffer = lines.removeLast();
                for (final line in lines) {
                  if (line.trim().isEmpty) continue;
                  try {
                    final data = jsonDecode(line);
                    final aiResponse = data['message']?['content'] ?? data['response'] ?? '';
                    if (aiResponse.isEmpty) continue;

                    if (_messages.isEmpty || _messages.last.role == 'user') {
                       final newMessage = Message(
                        content: aiResponse,
                        timestamp: DateTime.now(),
                        role: 'assistant',
                      );
                      _messages.add(newMessage);
                    } else {
                      final existingMessage = _messages.last;
                      final updatedContent = existingMessage.content + aiResponse;
                      _messages[_messages.length - 1] = Message(
                        content: updatedContent,
                        timestamp: existingMessage.timestamp,
                        role: 'assistant',
                      );
                    }
                    notifyListeners();
                  } catch (e) {
                    print('Error processing streamed chunk: $e line: $line');
                  }
                }
              },
              onDone: () {
                _isLoading = false;
                _currentResponseSubscription = null;
                _saveMessages();
                notifyListeners();
              },
              onError: (error) {
                _error = 'Streaming error: $error';
                _isLoading = false;
                _currentResponseSubscription = null;
                notifyListeners();
              },
            );
      } else {
        _error = 'Error: ${response.statusCode} - ${await response.stream.bytesToString()}';
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Error sending message: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  void cancelResponse() {
    _currentResponseSubscription?.cancel();
    _currentResponseSubscription = null;
    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _error = '';
    notifyListeners();
  }

  void clearMessages() {
    _messages.clear();
    _error = '';
    _saveMessages();
    notifyListeners();
  }
} 