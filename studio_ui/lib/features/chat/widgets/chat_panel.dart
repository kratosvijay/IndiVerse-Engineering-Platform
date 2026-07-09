import 'package:flutter/material.dart';
import '../controllers/chat_controller.dart';
import '../controllers/chat_input_controller.dart';
import '../controllers/chat_session_state.dart';
import '../../../models/ai_models.dart';
import 'chat_renderer.dart';
import 'conversation_history_sidebar.dart';
import 'message_metadata_bar.dart';
import 'reasoning_block_widget.dart';
import 'token_counter_widget.dart';
import 'tool_call_widget.dart';
import 'task_execution_widget.dart';
import 'generation_progress_widget.dart';
import 'verification_progress_widget.dart';
import 'project_dashboard_widget.dart';
import 'git_dashboard_widget.dart';
import 'pipeline_dashboard_widget.dart';
import 'cluster_dashboard_widget.dart';

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
  ConversationSession? _currentSession;

  @override
  void initState() {
    super.initState();
    _currentSession = widget.controller.state.session;
    if (_currentSession != null) {
      _inputController.text = widget.controller.getDraft(_currentSession!.id);
    }
    _inputController.textController.addListener(_onTextChanged);
    widget.controller.addListener(_onControllerChanged);
    widget.controller.activeStreamedMessage.addListener(
      _onActiveMessageChanged,
    );
  }

  @override
  void dispose() {
    _inputController.textController.removeListener(_onTextChanged);
    widget.controller.removeListener(_onControllerChanged);
    widget.controller.activeStreamedMessage.removeListener(
      _onActiveMessageChanged,
    );
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    widget.controller.updateDraft(_inputController.text);
  }

  void _onControllerChanged() {
    if (mounted) {
      final newSession = widget.controller.state.session;
      if (newSession != _currentSession) {
        _inputController.textController.removeListener(_onTextChanged);
        _currentSession = newSession;
        if (newSession != null) {
          _inputController.text = widget.controller.getDraft(newSession.id);
        } else {
          _inputController.text = '';
        }
        _inputController.textController.addListener(_onTextChanged);
      }
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
          if (_showHistory)
            ConversationHistorySidebar(controller: widget.controller),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeaderBar(state),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child:
                            state.messages.isEmpty &&
                                widget.controller.activeStreamedMessage.value ==
                                    null
                            ? _buildEmptyState()
                            : _buildMessagesList(state, renderer),
                      ),
                      ListenableBuilder(
                        listenable: widget.controller,
                        builder: (context, _) {
                          final state = widget.controller.state;
                          final hasActiveSession = state.session != null;

                          return Container(
                            constraints: const BoxConstraints(maxHeight: 180),
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TaskExecutionWidget(
                                    controller: widget.controller,
                                  ),
                                  if (hasActiveSession) ...[
                                    const Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: GenerationProgressWidget(
                                        activeFile: 'lib/main.dart',
                                        currentTask: 'Generating task files...',
                                        tokens: 2400,
                                        retries: 0,
                                        warningCount: 0,
                                        progress: 0.8,
                                      ),
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8.0,
                                        vertical: 4.0,
                                      ),
                                      child: VerificationProgressWidget(
                                        activeStage: 'Self-Healing Run',
                                        statusText:
                                            'Running test pipeline self-healing...',
                                        retryAttempt: 2,
                                        maxRetries: 5,
                                        historyLog: [
                                          '✔ Step 1: Analyze Passed (140ms)',
                                          '✔ Step 2: Compile Passed (210ms)',
                                          '✖ Step 3: Test Failed: Uncaught error in tests (350ms)',
                                          '⟳ Step 4: Self-Healing Repair Triggered (Scope: lines)',
                                        ],
                                      ),
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8.0,
                                        vertical: 4.0,
                                      ),
                                      child: ProjectDashboardWidget(
                                        activeProject:
                                            'IndiVerse Engine Platform',
                                        activeEpic:
                                            'Epic 1: Workspace Intelligence',
                                        activeMilestone:
                                            'Milestone 2: Graph Resolving',
                                        currentTask:
                                            'Task 3: Resolving symbols dependency graph',
                                        projectState: 'executing',
                                        completionPercentage: 0.6,
                                        completedTasks: 3,
                                        remainingTasks: 2,
                                        velocity: 1.5,
                                        timelineEvents: [
                                          'ProjectCreated: Initialized roadmap',
                                          'MilestoneStarted: milestone-1: Resolving dependencies',
                                          'TaskStarted: task-1: Building symbol indices',
                                          'TaskCompleted: task-1 finished successfully',
                                        ],
                                      ),
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8.0,
                                        vertical: 4.0,
                                      ),
                                      child: GitDashboardWidget(
                                        activeBranch: 'feature/agent-auth',
                                        baseBranch: 'main',
                                        purpose: 'feature',
                                        latestCommitHash: 'sha-1',
                                        latestCommitMsg:
                                            'feat(auth): implement OAuth login',
                                        filesChangedCount: 3,
                                        passesGates: true,
                                        hasPRDraft: true,
                                      ),
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8.0,
                                        vertical: 4.0,
                                      ),
                                      child: PipelineDashboardWidget(
                                        activePipeline: 'pipe-main',
                                        stages: ['Lint', 'Analyze', 'Test'],
                                        deploymentTarget: 'staging',
                                        availability: 0.999,
                                        crashRate: 0.02,
                                        healthScore: 9.8,
                                        approvalStatus: 'Approved',
                                        rollbackAvailable: true,
                                      ),
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8.0,
                                        vertical: 4.0,
                                      ),
                                      child: ClusterDashboardWidget(
                                        clusterId: 'cluster-alpha',
                                        status: 'healthy',
                                        workersCount: 3,
                                        runningJobs: 2,
                                        averageCpu: 35.0,
                                        averageMemory: 45.0,
                                        activeLeases: 0,
                                        knowledgeSyncStatus: 'synced',
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                _buildProgressIndicator(state),
                _buildInputArea(state),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(ChatSessionState state) {
    if (state.requestStage == null ||
        state.streamState == ChatStreamState.idle) {
      return const SizedBox.shrink();
    }

    String statusText = '';
    switch (state.requestStage!) {
      case RequestStage.preparing:
        statusText = 'Preparing request...';
        break;
      case RequestStage.gatheringContext:
        statusText = 'Gathering context...';
        break;
      case RequestStage.optimizingPrompt:
        statusText = 'Optimizing prompt...';
        break;
      case RequestStage.waitingProvider:
        statusText = 'Waiting for response...';
        break;
      case RequestStage.streaming:
        statusText = 'Generating response...';
        break;
      case RequestStage.completed:
        statusText = 'Completed';
        break;
      case RequestStage.cancelled:
        statusText = 'Cancelled';
        break;
      case RequestStage.failed:
        statusText = 'Failed';
        break;
    }

    if (state.requestStage == RequestStage.completed ||
        state.requestStage == RequestStage.cancelled ||
        state.requestStage == RequestStage.failed) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      child: Row(
        children: [
          const SizedBox(
            width: 12.0,
            height: 12.0,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF007ACC)),
            ),
          ),
          const SizedBox(width: 8.0),
          Text(
            statusText,
            style: const TextStyle(color: Color(0xFFCCCCCC), fontSize: 11.0),
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
          Row(
            children: [
              _buildSelectorDropdown(
                value: state.activeProviderId,
                items: ['mock-ai'],
                onChanged: (val) {
                  if (val != null) widget.controller.selectProvider(val);
                },
              ),
              const SizedBox(width: 8.0),
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
          return ValueListenableBuilder<ChatMessage?>(
            valueListenable: widget.controller.activeStreamedMessage,
            builder: (context, streamedMsg, _) {
              final toolCalls = state.toolCalls;

              if ((streamedMsg == null ||
                      (streamedMsg.content.isEmpty &&
                          (streamedMsg.reasoning == null ||
                              streamedMsg.reasoning!.isEmpty))) &&
                  toolCalls.isEmpty) {
                return const SizedBox.shrink();
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (streamedMsg != null &&
                      (streamedMsg.content.isNotEmpty ||
                          (streamedMsg.reasoning != null &&
                              streamedMsg.reasoning!.isNotEmpty)))
                    _buildMessageBubble(streamedMsg, renderer),
                  if (toolCalls.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 32.0,
                        right: 12.0,
                        bottom: 8.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: toolCalls
                            .map(
                              (t) => ToolCallWidget(
                                toolCall: t,
                                controller: widget.controller,
                              ),
                            )
                            .toList(),
                      ),
                    ),
                ],
              );
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
            child: Column(
              crossAxisAlignment: isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!isUser &&
                    message.reasoning != null &&
                    message.reasoning!.isNotEmpty)
                  ReasoningBlockWidget(reasoning: message.reasoning!),
                if (message.content.isNotEmpty)
                  Container(
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
                if (!isUser && message.metadata != null)
                  MessageMetadataBar(metadata: message.metadata!),
              ],
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D2D2D),
                        border: Border.all(color: const Color(0xFF3C3C3C)),
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: TextField(
                        controller: _inputController.textController,
                        focusNode: _inputController.focusNode,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12.0,
                        ),
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
                    TokenCounterWidget(
                      controller: _inputController.textController,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8.0),
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: isStreaming
                      ? const Color(0xFF333333)
                      : Colors.blueGrey[700],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                ),
                icon: const Icon(
                  Icons.playlist_add_check,
                  size: 16.0,
                  color: Colors.white,
                ),
                tooltip: 'Create plan from prompt',
                onPressed: isStreaming
                    ? null
                    : () {
                        final text = _inputController.textController.text;
                        if (text.trim().isNotEmpty) {
                          widget.controller.requestPlan(text);
                          _inputController.textController.clear();
                        }
                      },
              ),
              const SizedBox(width: 8.0),
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
