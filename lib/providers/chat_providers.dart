import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/error/result.dart';
import '../models/chat_conversation.dart';
import '../repositories/chat_repository.dart';
import 'auth_provider.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) => ChatRepository());

final chatHistoryProvider = FutureProvider<List<ChatConversation>>((ref) async {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) return [];
  final repo = ref.watch(chatRepositoryProvider);
  final result = await repo.getConversations(user.id);
  return result is Success<List<ChatConversation>> ? result.data : [];
});
