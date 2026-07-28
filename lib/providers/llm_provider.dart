import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/error/result.dart';
import '../models/booking_intent.dart';
import '../models/chat_message.dart';
import '../repositories/chat_repository.dart';
import '../services/llm_api_service.dart';
import '../supabase_config.dart';
import 'chat_providers.dart';

class LlmState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final BookingIntent? bookingIntent;
  final String? pendingIntent;
  final String? error;
  final String? currentConversationId;
  final bool isLoadingHistory;

  const LlmState({
    this.messages = const [],
    this.isLoading = false,
    this.bookingIntent,
    this.pendingIntent,
    this.error,
    this.currentConversationId,
    this.isLoadingHistory = false,
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
    String? currentConversationId,
    bool? isLoadingHistory,
  }) {
    return LlmState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      bookingIntent: clearBookingIntent
          ? null
          : (bookingIntent ?? this.bookingIntent),
      pendingIntent:
          clearPending ? null : (pendingIntent ?? this.pendingIntent),
      error: clearError ? null : (error ?? this.error),
      currentConversationId:
          currentConversationId ?? this.currentConversationId,
      isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
    );
  }
}

class LlmNotifier extends StateNotifier<LlmState> {
  final ChatRepository _chatRepo;
  final Ref _ref;

  LlmNotifier(this._chatRepo, this._ref) : super(const LlmState());

  String? get _userId => SupabaseConfig.client.auth.currentUser?.id;
  bool get _canPersist => _userId != null;

  static bool _containsBookingKeyword(String text) {
    final lower = text.toLowerCase();
    return lower.contains('book') ||
        lower.contains('need') ||
        lower.contains('want') ||
        lower.contains('reserve') ||
        lower.contains('get') ||
        lower.contains('ticket');
  }

  Future<String?> _ensureConversation({required String firstMessage}) async {
    if (!_canPersist) return null;
    if (state.currentConversationId != null) return state.currentConversationId;

    final title = firstMessage.length > 50
        ? '${firstMessage.substring(0, 50)}...'
        : firstMessage;

    final result = await _chatRepo.createConversation(
      userId: _userId!,
      title: title,
    );

    if (result is Success<String>) {
      _ref.invalidate(chatHistoryProvider);
      return result.data;
    }
    return null;
  }

  Future<void> _persistMessage(ChatMessage message) async {
    if (!_canPersist || message.conversationId == null) return;
    final result = await _chatRepo.addMessage(message);
    if (result is Failure<String>) {
      debugPrint('[LlmNotifier] Failed to persist message: ${result.message} (${result.error})');
    }
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final convId = await _ensureConversation(firstMessage: text);

    final userMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      conversationId: convId ?? state.currentConversationId,
      role: ChatMessageRole.user,
      content: text,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isLoading: true,
      clearError: true,
      currentConversationId: convId ?? state.currentConversationId,
    );

    await _persistMessage(userMsg);

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

    if (state.pendingIntent != null && BookingIntent.detectDateOnly(text)) {
      final prev = BookingIntent.extractFromUserMessage(state.pendingIntent!);
      if (prev != null) {
        final updated =
            prev.copyWith(dateStr: BookingIntent.extractDate(text));
        state = state.copyWith(
          isLoading: false,
          bookingIntent: updated,
          pendingIntent: null,
          clearPending: true,
        );
        return;
      }
    }

    if (intent != null && !intent.isComplete && _containsBookingKeyword(text)) {
      state = state.copyWith(
        isLoading: false,
        pendingIntent: text,
        clearPending: false,
      );
      return;
    }

    try {
      final botReply = await LlmApiService.sendMessage(message: text);

      final bookingFromTag = BookingIntent.tryParse(botReply);
      if (bookingFromTag != null && bookingFromTag.isComplete) {
        final assistantMsg = ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          conversationId: convId ?? state.currentConversationId,
          role: ChatMessageRole.assistant,
          content: BookingIntent.stripBookingTag(botReply),
          timestamp: DateTime.now(),
        );
        state = state.copyWith(
          messages: [...state.messages, assistantMsg],
          isLoading: false,
          bookingIntent: bookingFromTag,
          pendingIntent: null,
          clearPending: true,
        );
        await _persistMessage(assistantMsg);
        return;
      }

      final assistantMsg = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        conversationId: convId ?? state.currentConversationId,
        role: ChatMessageRole.assistant,
        content: botReply,
        timestamp: DateTime.now(),
      );
      state = state.copyWith(
        messages: [...state.messages, assistantMsg],
        isLoading: false,
      );
      await _persistMessage(assistantMsg);
    } catch (e) {
      final errMsg =
          'Failed to get response: ${e is LlmApiException ? e.message : 'Connection error. Check API URL in settings.'}';
      final errorMsg = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        conversationId: convId ?? state.currentConversationId,
        role: ChatMessageRole.assistant,
        content: errMsg,
        timestamp: DateTime.now(),
        isError: true,
      );
      state = state.copyWith(
        messages: [...state.messages, errorMsg],
        isLoading: false,
        error: errMsg,
      );
      await _persistMessage(errorMsg);
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

  Future<void> startNewConversation() async {
    state = const LlmState();
  }

  Future<void> loadConversation(String conversationId) async {
    state = state.copyWith(isLoadingHistory: true);
    final result = await _chatRepo.getMessages(conversationId);
    if (result is Success<List<ChatMessage>>) {
      state = LlmState(
        messages: result.data,
        currentConversationId: conversationId,
        isLoadingHistory: false,
      );
    } else {
      state = state.copyWith(
        isLoadingHistory: false,
        error: (result as Failure).message,
      );
    }
  }

  Future<void> deleteConversation(String conversationId) async {
    final result = await _chatRepo.deleteConversation(conversationId);
    if (result is Success) {
      if (state.currentConversationId == conversationId) {
        state = const LlmState();
      }
      _ref.invalidate(chatHistoryProvider);
    }
  }
}

final llmProvider = StateNotifierProvider<LlmNotifier, LlmState>((ref) {
  final chatRepo = ref.watch(chatRepositoryProvider);
  return LlmNotifier(chatRepo, ref);
});
