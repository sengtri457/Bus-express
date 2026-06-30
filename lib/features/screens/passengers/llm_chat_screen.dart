import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/booking_intent.dart';
import '../../../models/chat_message.dart';
import '../../../providers/llm_provider.dart';
import '../../../services/llm_api_service.dart';
import '../route_list_screen.dart';

class LlmChatScreen extends ConsumerStatefulWidget {
  const LlmChatScreen({super.key});

  @override
  ConsumerState<LlmChatScreen> createState() => _LlmChatScreenState();
}

class _LlmChatScreenState extends ConsumerState<LlmChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  static const _suggestions = [
    'What routes are available?',
    'How do I book a ticket?',
    'What is the cancel policy?',
    'Any promotions right now?',
  ];

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() => setState(() {});

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _send(String text) {
    if (text.trim().isEmpty) return;
    _focusNode.unfocus();
    ref.read(llmProvider.notifier).sendMessage(text.trim());
    _textController.clear();
    _scrollToBottom();
  }

  Future<void> _showSettings() async {
    final currentUrl = await LlmApiService.getApiUrl();
    final urlController = TextEditingController(text: currentUrl);

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgR),
        title: const Text('API Settings'),
        content: TextField(
          controller: urlController,
          decoration: const InputDecoration(
            labelText: 'API URL',
            hintText: 'https://cadmic-beverlee-merocrine.ngrok-free.dev/api/chat',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.url,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, urlController.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      await LlmApiService.setApiUrl(result);
      ref.read(llmProvider.notifier).clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('API URL updated'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.smR),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(llmProvider);
    final isEmpty = state.messages.isEmpty && !state.isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: AppRadius.smR,
              ),
              child: ClipRRect(
                borderRadius: AppRadius.smR,
                child: Image.asset('assets/images/aiLogo.png', width: 22, height: 22, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 12),
            const Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('BusExpress Assistant', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                  Text('Online', style: TextStyle(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: 'Clear chat',
            onPressed: state.messages.isEmpty ? null : () => ref.read(llmProvider.notifier).clear(),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'API Settings',
            onPressed: _showSettings,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: isEmpty ? _buildWelcome() : _buildMessageList(state),
          ),
          if (isEmpty) _buildSuggestions(state),
          if (state.bookingIntent != null) _buildBookingCard(state.bookingIntent!),
          _buildInputBar(state),
        ],
      ),
    );
  }

  Widget _buildWelcome() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                gradient: AppGradients.primaryBlue,
                borderRadius: AppRadius.xlR,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.chat_rounded, color: Colors.white, size: 42),
            ),
            const SizedBox(height: 24),
            const Text(
              'Need help with your trip?',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Ask me about routes, prices, booking,\ncancellations, and more.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textSoft,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestions(LlmState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: _suggestions.map((s) => _SuggestionChip(
          label: s,
          onTap: () => _send(s),
        )).toList(),
      ),
    );
  }

  Widget _buildMessageList(LlmState state) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: state.messages.length + (state.isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == state.messages.length) {
          return const _TypingIndicator();
        }
        return _MessageBubble(message: state.messages[index]);
      },
    );
  }

  Widget _buildBookingCard(BookingIntent intent) {
    final date = intent.resolveDate();
    final dateLabel = date != null
        ? '${date.day}/${date.month}/${date.year}'
        : (intent.dateStr ?? 'Not specified');

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEEF2FF), Color(0xFFE0E7FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryBlueBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.edit_calendar_rounded, size: 18, color: AppColors.primary),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Booking Summary',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => ref.read(llmProvider.notifier).clearBookingIntent(),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.04),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, size: 16, color: AppColors.textHint),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _intentRow(Icons.tour_rounded, 'From', intent.origin ?? '—'),
            const SizedBox(height: 6),
            _intentRow(Icons.location_on_rounded, 'To', intent.destination ?? '—'),
            const SizedBox(height: 6),
            _intentRow(Icons.calendar_today_rounded, 'Date', dateLabel),
            if (intent.passengers != null) ...[
              const SizedBox(height: 6),
              _intentRow(Icons.people_rounded, 'Passengers', '${intent.passengers}'),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _navigateToBooking(intent, date),
                icon: const Icon(Icons.search_rounded, size: 18),
                label: const Text('Review Available Buses'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _intentRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(
          fontSize: 13,
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        )),
        Expanded(
          child: Text(value, style: const TextStyle(
            fontSize: 13,
            color: AppColors.textDark,
            fontWeight: FontWeight.w600,
          )),
        ),
      ],
    );
  }

  void _navigateToBooking(BookingIntent intent, DateTime? date) {
    ref.read(llmProvider.notifier).clearBookingIntent();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RouteListScreen(
          origin: intent.origin ?? '',
          destination: intent.destination ?? '',
          date: date ?? DateTime.now(),
          operatorId: intent.operatorId,
          operatorName: intent.operatorName,
        ),
      ),
    );
  }

  Widget _buildInputBar(LlmState state) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: AppRadius.lgR,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TextField(
                    controller: _textController,
                    focusNode: _focusNode,
                    textInputAction: TextInputAction.send,
                    minLines: 1,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Type your question...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onSubmitted: state.isLoading ? null : (v) => _send(v),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: Material(
                  color: _textController.text.trim().isEmpty
                      ? AppColors.border
                      : AppColors.primary,
                  borderRadius: AppRadius.lgR,
                  child: InkWell(
                    borderRadius: AppRadius.lgR,
                    onTap: state.isLoading || _textController.text.trim().isEmpty
                        ? null
                        : () => _send(_textController.text),
                    child: Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      child: state.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_rounded, color: Colors.white, size: 22),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SuggestionChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 13)),
      onPressed: onTap,
      backgroundColor: AppColors.surface,
      side: const BorderSide(color: AppColors.border),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.smR),
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == ChatMessageRole.user;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) _buildAvatar(),
          if (!isUser) const SizedBox(width: 10),
          Flexible(
            child: Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: isUser ? AppGradients.primaryBlue : null,
                color: isUser ? null : AppColors.surface,
                borderRadius: isUser
                    ? const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.zero,
                      )
                    : const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                        bottomLeft: Radius.zero,
                        bottomRight: Radius.circular(16),
                      ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isUser ? 0.15 : 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: isUser ? null : Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.45,
                      color: isUser ? Colors.white : AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                    Text(
                      _formatTime(message.timestamp),
                      style: TextStyle(
                        fontSize: 11,
                        color: isUser
                            ? Colors.white.withValues(alpha: 0.7)
                            : AppColors.textHint,
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 10),
          if (isUser) _buildAvatar(isUser: true),
        ],
      ),
    );
  }

  Widget _buildAvatar({bool isUser = false}) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        gradient: isUser ? AppGradients.primaryBlue : null,
        color: isUser ? null : AppColors.surfaceGrey,
        shape: BoxShape.circle,
        border: isUser ? null : Border.all(color: AppColors.border),
      ),
      child: isUser
          ? const Icon(Icons.person_rounded, size: 18, color: Colors.white)
          : ClipOval(
              child: Image.asset('assets/images/aiLogo.png', width: 34, height: 34, fit: BoxFit.cover),
            ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.surfaceGrey,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: ClipOval(
              child: Image.asset('assets/images/aiLogo.png', width: 34, height: 34, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              border: Border.all(color: AppColors.border),
            ),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (i) {
                  return Container(
                    width: 8,
                    height: 8,
                    margin: EdgeInsets.only(right: i < 2 ? 5 : 0),
                    decoration: BoxDecoration(
                      color: AppColors.textHint.withValues(
                        alpha: 0.3 + (_controller.value * 0.7),
                      ),
                      shape: BoxShape.circle,
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
