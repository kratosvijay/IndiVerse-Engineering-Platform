import 'package:test/test.dart';
import 'package:indiverse_developer_platform/core/providers/ai_provider.dart';
import 'package:indiverse_developer_platform/core/providers/ai_provider_registry.dart';
import 'package:indiverse_developer_platform/core/providers/ai_stream_events.dart';
import 'package:indiverse_developer_platform/core/providers/mock_ai_provider.dart';
import 'package:indiverse_developer_platform/core/conversation/conversation_manager.dart';
import 'package:indiverse_developer_platform/core/context/context_engine.dart';
import 'package:indiverse_developer_platform/core/prompt/prompt_pipeline.dart';

void main() {
  group('AI Infrastructure Subsystem Tests', () {
    late AIProviderRegistry registry;
    late ConversationManager conversationManager;
    late ContextEngine contextEngine;

    setUp(() {
      registry = AIProviderRegistry();
      conversationManager = ConversationManager(MemoryConversationStore());
      contextEngine = ContextEngine();
    });

    test('AIProviderRegistry registers and selects best provider by priority',
        () async {
      final mock1 = MockAIProvider(); // priority 10
      registry.registerProvider(mock1);

      expect(registry.listProviders().length, 1);

      // Verify initialization
      await mock1.initialize(const AIProviderConfiguration(
        endpoint: 'http://local',
        apiKey: 'key',
        timeout: Duration(seconds: 5),
        enabled: true,
        defaultModel: AIModel(
          id: 'mock-pro',
          name: 'Mock Pro',
          provider: 'mock-ai',
          contextWindow: 1000,
          supportsVision: true,
          supportsTools: true,
          supportsReasoning: true,
          supportsJsonMode: true,
          supportsStreaming: true,
        ),
      ));

      expect(mock1.state, AIProviderState.ready);

      final best = registry.selectBestProvider((caps) => caps.chat);
      expect(best, isNotNull);
      expect(best!.id, 'mock-ai');
    });

    test('ConversationManager session immutability and message appending',
        () async {
      var session = await conversationManager.createSession(
        id: 'session-123',
        title: 'New Chat',
        workspace: 'test-workspace',
        providerId: 'mock-ai',
        modelId: 'mock-pro',
      );

      expect(session.id, 'session-123');
      expect(session.messages.length, 0);

      // Append message
      final updated = await conversationManager.appendMessage(
        'session-123',
        ChatMessage(
          role: ChatRole.user,
          content: 'Hello World',
          timestamp: DateTime.now(),
        ),
      );

      expect(updated.messages.length, 1);
      expect(updated.messages.first.content, 'Hello World');
      expect(updated.estimatedTokens, greaterThan(0));

      // Retrieve from store to verify update
      final retrieved = await conversationManager.getSession('session-123');
      expect(retrieved, isNotNull);
      expect(retrieved!.messages.length, 1);
    });

    test('ContextEngine aggregates fragment priorities and estimated tokens',
        () async {
      final snapshot = await contextEngine.gatherContext(const ContextRequest(
        workspace: 'test-workspace',
        maxTokens: 1000,
      ));

      expect(snapshot.fragments.length, greaterThan(0));
      expect(snapshot.totalTokens, greaterThan(0));

      // Verify that editor context fragment has priority 4
      final editorFrag =
          snapshot.fragments.firstWhere((f) => f.source == 'editor');
      expect(editorFrag.priority, 4);
    });

    test('PromptBuilder merges variables and filters context fragments',
        () async {
      final template = const PromptTemplate(
        systemTemplate: 'System: {{workspace}}',
        userTemplate: 'User: {{message}}',
      );

      final snapshot = await contextEngine.gatherContext(const ContextRequest(
        workspace: 'test-workspace',
        maxTokens: 1000,
      ));

      final builder = PromptBuilder();
      final package = builder.build(
        template: template,
        variables: {
          'workspace': 'my-workspace',
          'message': 'How are you?',
        },
        context: snapshot,
        maxContextTokens: 200, // tight budget to force optimization
      );

      expect(package.systemPrompt, 'System: my-workspace');
      expect(package.userPrompt, contains('User: How are you?'));
      expect(package.userPrompt, contains('--- Context ---'));
      expect(package.estimatedTokens, greaterThan(0));
    });

    test('MockAIProvider streaming chunks and usage metrics', () async {
      final mock = MockAIProvider();
      await mock.initialize(const AIProviderConfiguration(
        endpoint: 'http://local',
        apiKey: 'key',
        timeout: Duration(seconds: 5),
        enabled: true,
        defaultModel: AIModel(
          id: 'mock-pro',
          name: 'Mock Pro',
          provider: 'mock-ai',
          contextWindow: 1000,
          supportsVision: true,
          supportsTools: true,
          supportsReasoning: true,
          supportsJsonMode: true,
          supportsStreaming: true,
        ),
      ));

      final session = await conversationManager.createSession(
        id: 'sess',
        title: 'Title',
        workspace: 'workspace',
        providerId: 'mock-ai',
        modelId: 'mock-pro',
      );

      final promptPackage = const PromptPackage(
        systemPrompt: 'System',
        userPrompt: 'User text',
        fragments: [],
        estimatedTokens: 10,
      );

      final request = AIRequest(
        session: session,
        context:
            ContextSnapshot(fragments: const [], timestamp: DateTime.now()),
        promptPackage: promptPackage,
        token: CancellationToken(),
      );

      final stream = await mock.chat(request);
      final events = await stream.toList();

      expect(events.any((e) => e is TokenChunkEvent), isTrue);
      expect(events.any((e) => e is ReasoningChunkEvent), isTrue);
      expect(events.any((e) => e is UsageEvent), isTrue);
      expect(events.any((e) => e is CompletedEvent), isTrue);

      final completed =
          events.firstWhere((e) => e is CompletedEvent) as CompletedEvent;
      expect(
          completed.fullText, contains('Hello! I am your Mock AI assistant.'));
    });

    test('MockAIProvider stream handles cancellation gracefully', () async {
      final mock = MockAIProvider();
      await mock.initialize(const AIProviderConfiguration(
        endpoint: 'http://local',
        apiKey: 'key',
        timeout: Duration(seconds: 5),
        enabled: true,
        defaultModel: AIModel(
          id: 'mock-pro',
          name: 'Mock Pro',
          provider: 'mock-ai',
          contextWindow: 1000,
          supportsVision: true,
          supportsTools: true,
          supportsReasoning: true,
          supportsJsonMode: true,
          supportsStreaming: true,
        ),
      ));

      final session = await conversationManager.createSession(
        id: 'sess2',
        title: 'Title',
        workspace: 'workspace',
        providerId: 'mock-ai',
        modelId: 'mock-pro',
      );

      final cancelToken = CancellationToken();
      final request = AIRequest(
        session: session,
        context:
            ContextSnapshot(fragments: const [], timestamp: DateTime.now()),
        promptPackage: const PromptPackage(
          systemPrompt: 'Sys',
          userPrompt: 'User',
          fragments: [],
          estimatedTokens: 10,
        ),
        token: cancelToken,
      );

      final stream = await mock.chat(request);

      // Cancel immediately
      cancelToken.cancel();

      final events = await stream.toList();
      // Verify cancellation led to shorter stream (potentially no CompletedEvent)
      expect(events.any((e) => e is CompletedEvent), isFalse);
    });
  });
}
