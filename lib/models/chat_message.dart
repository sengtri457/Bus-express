enum ChatMessageRole { user, assistant }

class ChatMessage {
  final String id;
  final String? conversationId;
  final ChatMessageRole role;
  final String content;
  final DateTime timestamp;
  final bool isError;

  const ChatMessage({
    required this.id,
    this.conversationId,
    required this.role,
    required this.content,
    required this.timestamp,
    this.isError = false,
  });

  ChatMessage copyWith({
    String? id,
    String? conversationId,
    ChatMessageRole? role,
    String? content,
    DateTime? timestamp,
    bool? isError,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      role: role ?? this.role,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isError: isError ?? this.isError,
    );
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String?,
      role: ChatMessageRole.values.firstWhere(
        (r) => r.name == json['role'],
      ),
      content: json['content'] as String,
      timestamp: DateTime.parse(json['created_at'] as String),
      isError: json['is_error'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    if (conversationId != null) 'conversation_id': conversationId,
    'role': role.name,
    'content': content,
    'created_at': timestamp.toIso8601String(),
    'is_error': isError,
  };
}
