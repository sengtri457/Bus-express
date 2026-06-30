import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/booking_intent.dart';
import '../models/chat_message.dart';
import '../services/llm_api_service.dart';

class LlmState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final BookingIntent? bookingIntent;
  final String? pendingIntent; // user text for incomplete booking
  final String? error;

  const LlmState({
    this.messages = const [],
    this.isLoading = false,
    this.bookingIntent,
    this.pendingIntent,
    this.error,
  });

  LlmState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    BookingIntent? bookingIntent,
    bool clearBookingIntent = false,
    String? pendingIntent,
    bool clearPending = false,
    String? error,
    bool clearError = false,
  }) {
    return LlmState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      bookingIntent: clearBookingIntent ? null : (bookingIntent ?? this.bookingIntent),
      pendingIntent: clearPending ? null : (pendingIntent ?? this.pendingIntent),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class LlmNotifier extends StateNotifier<LlmState> {
  LlmNotifier() : super(const LlmState());

  static bool _containsBookingKeyword(String text) {
    final lower = text.toLowerCase();
    return lower.contains('book') ||
        lower.contains('need') ||
        lower.contains('want') ||
        lower.contains('reserve') ||
        lower.contains('get') ||
        lower.contains('ticket');
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: ChatMessageRole.user,
      content: text,
      timestamp: DateTime.now(),
    );
    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isLoading: true,
      clearError: true,
    );

    // 1. Try regex extraction
    final intent = BookingIntent.extractFromUserMessage(text);

    if (intent != null && intent.isComplete) {
      state = state.copyWith(
        isLoading: false,
        bookingIntent: intent,
        pendingIntent: null,
        clearPending: true,
      );
      return;
    }

    // 2. Detect date-only follow-up
    if (state.pendingIntent != null && BookingIntent.detectDateOnly(text)) {
      final prev = BookingIntent.extractFromUserMessage(state.pendingIntent!);
      if (prev != null) {
        final updated = prev.copyWith(dateStr: BookingIntent.extractDate(text));
        state = state.copyWith(
          isLoading: false,
          bookingIntent: updated,
          pendingIntent: null,
          clearPending: true,
        );
        return;
      }
    }

    // 3. Partial booking keyword => stash pending
    if (intent != null && !intent.isComplete && _containsBookingKeyword(text)) {
      state = state.copyWith(
        isLoading: false,
        pendingIntent: text,
        clearPending: false,
      );
      return;
    }

    // 4. Fallback: call LLM API
    try {
      final botReply = await LlmApiService.sendMessage(message: text);

      // Check for booking tag in reply
      final bookingFromTag = BookingIntent.tryParse(botReply);
      if (bookingFromTag != null && bookingFromTag.isComplete) {
        state = state.copyWith(
          messages: [
            ...state.messages,
            ChatMessage(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                role: ChatMessageRole.assistant,
                content: BookingIntent.stripBookingTag(botReply),
                timestamp: DateTime.now(),
              ),
          ],
          isLoading: false,
          bookingIntent: bookingFromTag,
          pendingIntent: null,
          clearPending: true,
        );
        return;
      }

      state = state.copyWith(
        messages: [
          ...state.messages,
          ChatMessage(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              role: ChatMessageRole.assistant,
              content: botReply,
              timestamp: DateTime.now(),
            ),
        ],
        isLoading: false,
      );
    } catch (e) {
      final errMsg = 'Failed to get response: ${e is LlmApiException ? e.message : 'Connection error. Check API URL in settings.'}';
      state = state.copyWith(
        messages: [
          ...state.messages,
          ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            role: ChatMessageRole.assistant,
            content: errMsg,
            timestamp: DateTime.now(),
            isError: true,
          ),
        ],
        isLoading: false,
        error: errMsg,
      );
    }
  }

  void clear() {
    state = const LlmState();
  }

  void clearBookingIntent() {
    state = state.copyWith(
      clearBookingIntent: true,
      clearPending: true,
    );
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final llmProvider = StateNotifierProvider<LlmNotifier, LlmState>((ref) {
  return LlmNotifier();
});
