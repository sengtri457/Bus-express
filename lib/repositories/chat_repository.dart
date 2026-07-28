import '../core/error/result.dart';
import '../models/chat_conversation.dart';
import '../models/chat_message.dart';
import 'base_repository.dart';

class ChatRepository extends BaseRepository {
  ChatRepository() : super('chat_messages');

  Future<Result<String>> createConversation({
    required String userId,
    required String title,
  }) async {
    try {
      final data = await client
          .from('chat_conversations')
          .insert({
            'user_id': userId,
            'title': title,
          })
          .select('id')
          .single();
      return Success(data['id'] as String);
    } catch (e) {
      return Failure('Failed to create conversation', error: e);
    }
  }

  Future<Result<List<ChatConversation>>> getConversations(
    String userId,
  ) async {
    try {
      final data = await client
          .from('chat_conversations')
          .select('*')
          .eq('user_id', userId)
          .order('updated_at', ascending: false);
      return Success(
        data.map((e) => ChatConversation.fromJson(e)).toList(),
      );
    } catch (e) {
      return Failure('Failed to load conversations', error: e);
    }
  }

  Future<Result<ChatConversation?>> getConversation(String id) async {
    try {
      final data = await client
          .from('chat_conversations')
          .select('*')
          .eq('id', id)
          .single();
      return Success(ChatConversation.fromJson(data));
    } catch (e) {
      return Failure('Failed to load conversation', error: e);
    }
  }

  Future<Result<void>> updateConversationTitle({
    required String id,
    required String title,
  }) async {
    try {
      await client
          .from('chat_conversations')
          .update({'title': title, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', id);
      return const Success(null);
    } catch (e) {
      return Failure('Failed to update conversation title', error: e);
    }
  }

  Future<Result<void>> touchConversation(String id) async {
    try {
      await client
          .from('chat_conversations')
          .update({'updated_at': DateTime.now().toIso8601String()})
          .eq('id', id);
      return const Success(null);
    } catch (e) {
      return Failure('Failed to update conversation', error: e);
    }
  }

  Future<Result<void>> deleteConversation(String id) async {
    try {
      await client
          .from('chat_conversations')
          .delete()
          .eq('id', id);
      return const Success(null);
    } catch (e) {
      return Failure('Failed to delete conversation', error: e);
    }
  }

  Future<Result<String>> addMessage(ChatMessage message) async {
    try {
      final json = message.toJson();
      json.remove('id');
      final data = await client
          .from('chat_messages')
          .insert(json)
          .select('id')
          .single();
      await touchConversation(message.conversationId!);
      return Success(data['id'] as String);
    } catch (e) {
      return Failure('Failed to save message', error: e);
    }
  }

  Future<Result<List<ChatMessage>>> getMessages(String conversationId) async {
    try {
      final data = await client
          .from('chat_messages')
          .select('*')
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: true);
      return Success(
        data.map((e) => ChatMessage.fromJson(e)).toList(),
      );
    } catch (e) {
      return Failure('Failed to load messages', error: e);
    }
  }

  Future<Result<int>> getMessageCount(String conversationId) async {
    try {
      final data = await client
          .rpc('get_chat_message_count', params: {
            'p_conversation_id': conversationId,
          });
      return Success((data as int));
    } catch (e) {
      return Failure('Failed to get message count', error: e);
    }
  }
}
