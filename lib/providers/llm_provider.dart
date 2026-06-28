import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_message.dart';
import '../models/booking_intent.dart';
import '../services/llm_api_service.dart';

class LlmState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;
  final BookingIntent? bookingIntent;

  const LlmState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
    this.bookingIntent,
  });

  LlmState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? error,
    BookingIntent? bookingIntent,
  }) {
    return LlmState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      bookingIntent: bookingIntent,
    );
  }
}

class LlmNotifier extends StateNotifier<LlmState> {
  LlmNotifier() : super(const LlmState());

  static int _counter = 0;
  static String _nextId() => 'msg_${++_counter}';

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMsg = ChatMessage(
      id: _nextId(),
      role: ChatMessageRole.user,
      content: text.trim(),
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isLoading: true,
      error: null,
      bookingIntent: null,
    );

    try {
      final reply = await LlmApiService.sendMessage(message: text.trim());
      final intent = BookingIntent.tryParse(reply);

      final displayContent = intent != null
          ? BookingIntent.stripBookingTag(reply)
          : reply;

      final botMsg = ChatMessage(
        id: _nextId(),
        role: ChatMessageRole.assistant,
        content: displayContent,
        timestamp: DateTime.now(),
      );

      state = state.copyWith(
        messages: [...state.messages, botMsg],
        isLoading: false,
        bookingIntent: intent,
      );
    } catch (e) {
      final errorMsg = ChatMessage(
        id: _nextId(),
        role: ChatMessageRole.assistant,
        content: e.toString(),
        timestamp: DateTime.now(),
        isError: true,
      );

      state = state.copyWith(
        messages: [...state.messages, errorMsg],
        isLoading: false,
        error: e.toString(),
        bookingIntent: null,
      );
    }
  }

  void clear() {
    state = const LlmState();
    _counter = 0;
  }

  void dismissBookingIntent() {
    state = state.copyWith(bookingIntent: null);
  }
}

final llmProvider = StateNotifierProvider<LlmNotifier, LlmState>((ref) {
  return LlmNotifier();
});
