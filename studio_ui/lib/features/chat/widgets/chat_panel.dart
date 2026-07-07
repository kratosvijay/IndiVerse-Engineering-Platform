import 'package:flutter/material.dart';
import '../controllers/chat_controller.dart';
import '../controllers/chat_input_controller.dart';
import '../controllers/chat_session_state.dart';
import '../../../models/ai_models.dart';
import 'chat_renderer.dart';
import 'conversation_history_sidebar.dart';

class ChatPanel extends StatefulWidget {
  final ChatController controller;
  final void Function(String code)? onInsertCode;

  const ChatPanel({super.key, required this.controller, this.onInsertCode});

  @override
  State<ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends State<ChatPanel> {
  final ChatInputController _inputController = ChatInputController();
  final ScrollController _scrollController = ScrollController();
  bool _showHistory = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
    widget.controller.activeStreamedMessage.addListener(
      _onActiveMessageChanged,
    );
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    widget.controller.activeStreamedMessage.removeListener(
      _onActiveMessageChanged,
    );
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
      _scrollToBottomIfNeeded();
    }
  }

  void _onActiveMessageChanged() {
    if (mounted) {
      _scrollToBottomIfNeeded();
    }
  }

  void _scrollToBottomIfNeeded() {
    if (!_scrollController.hasClients) return;
    // Auto scroll to bottom only if user is close to the bottom
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final delta = maxScroll - currentScroll;

    if (delta < 150.0) {
      Future.delayed(const Duration(milliseconds: 50), () {
        if (_scrollController.hasClients && mounted) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.controller.state;
    final renderer = MarkdownChatRenderer(onInsertCode: widget.onInsertCode);

    return Container(
      color: const Color(0xFF1E1E1E),
      child: Row(
        children: [
          // Optional conversation history sidebar
          if (_showHistory)
            ConversationHistorySidebar(controller: widget.controller),
          // Main Chat body
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top control bar
                _buildHeaderBar(state),
                // Messages List Viewport
                Expanded(
                  child:
                      state.messages.isEmpty &&
                          widget.controller.activeStreamedMessage.value == null
                      ? _buildEmptyState()
                      : _buildMessagesList(state, renderer),
                ),
                // Streaming progress indicator if preparing/waiting
                if (state.streamState == ChatStreamState.preparing ||
                    state.streamState == ChatStreamState.waitingFirstToken)
                  const LinearProgressIndicator(
                    minHeight: 2.0,
                    backgroundColor: Color(0xFF1E1E1E),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF007ACC),
                    ),
                  ),
                // Bottom Input Prompt & controls
                _buildInputArea(state),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBar(ChatSessionState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      decoration: const BoxDecoration(
        color: Color(0xFF252526),
        border: Border(bottom: BorderSide(color: Color(0xFF333333))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(
                  _showHistory ? Icons.chevron_left : Icons.history,
                  color: const Color(0xFFCCCCCC),
                  size: 18.0,
                ),
                onPressed: () {
                  setState(() {
                    _showHistory = !_showHistory;
                  });
                },
              ),
              const Text(
                'AI COPILOT',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12.0,
                ),
              ),
            ],
          ),
          // Selectors
          Row(
            children: [
              // Provider Selector
              _buildSelectorDropdown(
                value: state.activeProviderId,
                items: ['mock-ai'],
                onChanged: (val) {
                  if (val != null) widget.controller.selectProvider(val);
                },
              ),
              const SizedBox(width: 8.0),
              // Model Selector
              _buildSelectorDropdown(
                value: state.activeModelId,
                items: ['mock-pro', 'mock-flash'],
                onChanged: (val) {
                  if (val != null) widget.controller.selectModel(val);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelectorDropdown({
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6.0),
      decoration: BoxDecoration(
        color: const Color(0xFF3C3C3C),
        borderRadius: BorderRadius.circular(3.0),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: const Color(0xFF2D2D2D),
          style: const TextStyle(color: Colors.white, fontSize: 11.0),
          isDense: true,
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item.toUpperCase()),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assistant, size: 48.0, color: Color(0xFF555555)),
          SizedBox(height: 12.0),
          Text(
            'Ask copilot any coding question',
            style: TextStyle(color: Color(0xFF858585), fontSize: 13.0),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList(
    ChatSessionState state,
    MarkdownChatRenderer renderer,
  ) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(12.0),
      itemCount: state.messages.length + 1,
      itemBuilder: (context, index) {
        if (index < state.messages.length) {
          final message = state.messages[index];
          return _buildMessageBubble(message, renderer);
        } else {
          // Last bubble: ValueListenableBuilder updating ONLY when streaming
          return ValueListenableBuilder<ChatMessage?>(
            valueListenable: widget.controller.activeStreamedMessage,
            builder: (context, streamedMsg, _) {
              if (streamedMsg == null || streamedMsg.content.isEmpty) {
                return const SizedBox.shrink();
              }
              return _buildMessageBubble(streamedMsg, renderer);
            },
          );
        }
      },
    );
  }

  Widget _buildMessageBubble(
    ChatMessage message,
    MarkdownChatRenderer renderer,
  ) {
    final isUser = message.role == ChatRole.user;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            const CircleAvatar(
              radius: 12.0,
              backgroundColor: Color(0xFF007ACC),
              child: Icon(Icons.smart_toy, size: 14.0, color: Colors.white),
            ),
            const SizedBox(width: 8.0),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 8.0,
              ),
              decoration: BoxDecoration(
                color: isUser
                    ? const Color(0xFF005A9E)
                    : const Color(0xFF2D2D2D),
                borderRadius: BorderRadius.circular(6.0),
              ),
              child: renderer.render(message),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8.0),
            const CircleAvatar(
              radius: 12.0,
              backgroundColor: Color(0xFF555555),
              child: Icon(Icons.person, size: 14.0, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputArea(ChatSessionState state) {
    final isStreaming =
        state.streamState == ChatStreamState.streaming ||
        state.streamState == ChatStreamState.waitingFirstToken;

    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        border: Border(top: BorderSide(color: Color(0xFF333333))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Stream error banner
          if (state.error != null)
            Container(
              padding: const EdgeInsets.all(8.0),
              margin: const EdgeInsets.only(bottom: 8.0),
              decoration: BoxDecoration(
                color: const Color(0x33F44336),
                border: Border.all(color: const Color(0xFFF44336)),
                borderRadius: BorderRadius.circular(4.0),
              ),
              child: Text(
                state.error!,
                style: const TextStyle(
                  color: Color(0xFFFF8A80),
                  fontSize: 11.0,
                ),
              ),
            ),
          // Action Buttons: Stop, Retry
          if (isStreaming)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3C3C3C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 8.0,
                    ),
                  ),
                  icon: const Icon(Icons.stop, size: 14.0),
                  label: const Text(
                    'Stop Generation',
                    style: TextStyle(fontSize: 11.0),
                  ),
                  onPressed: widget.controller.stopGeneration,
                ),
              ],
            )
          else if (state.messages.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  icon: const Icon(
                    Icons.refresh,
                    size: 14.0,
                    color: Color(0xFFCCCCCC),
                  ),
                  label: const Text(
                    'Retry Last Prompt',
                    style: TextStyle(color: Color(0xFFCCCCCC), fontSize: 11.0),
                  ),
                  onPressed: widget.controller.retryLastPrompt,
                ),
              ],
            ),
          const SizedBox(height: 6.0),
          // Prompt entry text field
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D2D2D),
                    border: Border.all(color: const Color(0xFF3C3C3C)),
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: TextField(
                    controller: _inputController.textController,
                    focusNode: _inputController.focusNode,
                    style: const TextStyle(color: Colors.white, fontSize: 12.0),
                    maxLines: 4,
                    minLines: 1,
                    decoration: const InputDecoration(
                      hintText: 'Type prompt here...',
                      hintStyle: TextStyle(color: Color(0xFF6E6E6E)),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    onSubmitted: (_) {
                      if (!isStreaming) {
                        _inputController.submitPrompt(
                          widget.controller.sendPrompt,
                        );
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8.0),
              // Send prompt button
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: isStreaming
                      ? const Color(0xFF333333)
                      : const Color(0xFF007ACC),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                ),
                icon: Icon(
                  isStreaming ? Icons.hourglass_empty : Icons.send,
                  size: 16.0,
                  color: Colors.white,
                ),
                onPressed: isStreaming
                    ? null
                    : () {
                        _inputController.submitPrompt(
                          widget.controller.sendPrompt,
                        );
                      },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
