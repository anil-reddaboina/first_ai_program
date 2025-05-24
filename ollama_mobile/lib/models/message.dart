class Message {
  final String content;
  final DateTime timestamp;
  final String role; // 'user' or 'assistant'

  Message({
    required this.content,
    required this.timestamp,
    required this.role,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      content: json['content'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      role: json['role'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'role': role,
    };
  }

  bool get isUser => role == 'user';
} 