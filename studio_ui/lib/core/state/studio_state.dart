import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../models/ids.dart';
import '../../models/selection.dart';
import '../services/keyboard_shortcut_manager.dart';
import '../services/workbench_providers.dart';
import '../../models/editor_document.dart';
import '../../models/tree_node.dart';
import '../services/navigation_service.dart';
import '../services/workspace_cache.dart';
import '../services/document_service.dart';
import '../services/workbench_event_bus.dart';
import '../services/workbench_api.dart';
import '../services/workbench_commands.dart';
import '../services/document_history_service.dart';
import '../../models/edit_operation.dart';
import '../../features/editor/controllers/editor_controller.dart';
import '../../features/explorer/controllers/explorer_controller.dart';
import '../services/navigation_history.dart';
import '../../models/workspace_events.dart';
import '../services/recovery_service.dart';
import '../services/language_provider_registry.dart';
import '../services/language_intelligence_service.dart';
import '../../models/language_intelligence_models.dart';
import '../services/default_hover_provider.dart';
import '../../models/diagnostic_collection.dart';
import '../services/default_diagnostics_provider.dart';
import '../../features/editor/controllers/completion_controller.dart';
import '../../features/editor/controllers/signature_help_controller.dart';
import '../../features/editor/controllers/code_action_controller.dart';
import '../../features/editor/controllers/inline_ai_controller.dart';
import '../services/default_completion_provider.dart';
import '../services/default_signature_help_provider.dart';
import '../services/default_code_action_provider.dart';
import '../services/ai_service.dart';
import '../services/overlay_manager.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:async';

enum SaveReason { manual, autoDelay, focusLost, windowClose, recovery }

enum SaveTaskState { queued, running, completed, failed }

class SaveTask {
  final String path;
  final SaveReason reason;
  final Completer<OperationResult<void>> completer = Completer();
  SaveTaskState state = SaveTaskState.queued;

  SaveTask({required this.path, required this.reason});

  int get priority {
    switch (reason) {
      case SaveReason.manual:
        return 3;
      case SaveReason.focusLost:
      case SaveReason.windowClose:
        return 2;
      case SaveReason.autoDelay:
        return 1;
      case SaveReason.recovery:
        return 0;
    }
  }
}

class StudioState extends ChangeNotifier {
  String _activeTab = 'Workspace';
  int _serverPort = 18080;
  bool _isConnected = false;

  Map<String, String> _health = {};
  Map<String, dynamic> _metrics = {};
  Map<String, bool> _features = {};
  final List<String> _eventLogs = [];

  String _agentWorkflowStatus = 'Idle';
  String _version = "v1.1.0";
  String _activeProject = "indiverse-engineering-platform";
  String _branchName = "main";

  Selection? _currentSelection;
  final List<TreeNode> _rootNodes = [];

  final WorkspaceCache workspaceCache = WorkspaceCache();
  late final NavigationService navigation;
  final EditorController editor = EditorController();
  final NavigationHistory navigationHistory = NavigationHistory();
  final ExplorerController explorer = ExplorerController();
  final DocumentService documentService = DocumentService();
  final WorkbenchEventBus eventBus = WorkbenchEventBus();
  late final WorkbenchApi workbench;
  late final DocumentHistoryService history;
  late final CommandRegistry commandRegistry;
  late final CommandDispatcher dispatcher;
  late final KeyboardShortcutManager shortcutManager;
  final LanguageProviderRegistry languageRegistry = LanguageProviderRegistry();
  late final LanguageIntelligenceService languageIntel =
      LanguageIntelligenceService(languageRegistry);
  LanguageIntelligenceService get intelligence => languageIntel;
  late AIService aiService;
  final OverlayManager overlayManager = OverlayManager();
  late final CompletionController completionController;
  late final SignatureHelpController signatureHelpController;
  late final CodeActionController codeActionController;
  late final InlineAIController inlineAIController;
  final DiagnosticCollection diagnostics = DiagnosticCollection();
  final Map<String, Timer> _diagTimers = {};
  WebSocketChannel? _wsChannel;
  AutoSavePolicy autoSavePolicy = AutoSavePolicy.never;
  WorkspaceWatcherState watcherState = WorkspaceWatcherState.disconnected;
  late final RecoveryService _recoveryService = RecoveryService(
    workspaceRoot: Directory.current.path,
  );
  final List<SaveTask> _saveQueue = [];
  bool _isSavingQueue = false;
  Timer? _autoSaveDebounceTimer;
  DateTime? _lastSaveTime;

  List<SaveTask> get saveQueue => List.unmodifiable(_saveQueue);
  DateTime? get lastSaveTime => _lastSaveTime;

  bool _showProblemsPanel = false;
  bool get showProblemsPanel => _showProblemsPanel;

  void toggleProblemsPanel() {
    _showProblemsPanel = !_showProblemsPanel;
    notifyListeners();
  }

  List<dynamic> _searchResults = [];

  // Getters
  String get activeTab => _activeTab;
  int get serverPort => _serverPort;
  bool get isConnected => _isConnected;
  Map<String, String> get health => _health;
  Map<String, dynamic> get metrics => _metrics;
  Map<String, bool> get features => _features;
  List<String> get eventLogs => _eventLogs;
  String get agentWorkflowStatus => _agentWorkflowStatus;
  String get version => _version;
  String get activeProject => _activeProject;
  String get branchName => _branchName;
  Selection? get currentSelection => _currentSelection;
  List<TreeNode> get rootNodes => _rootNodes;
  List<dynamic> get searchResults => _searchResults;

  set agentWorkflowStatus(String val) {
    _agentWorkflowStatus = val;
    notifyListeners();
  }

  Future<void> executeSearch(String query) async {
    if (query.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }
    try {
      final res = await http.get(
        Uri.parse('http://localhost:$_serverPort/api/search?q=$query'),
      );
      final data = jsonDecode(res.body);
      _searchResults = data['results'] ?? [];
      notifyListeners();
    } catch (_) {}
  }

  StudioState() {
    aiService = AIService(serverUrl: 'http://localhost:$_serverPort');
    completionController = CompletionController(state: this);
    signatureHelpController = SignatureHelpController(state: this);
    codeActionController = CodeActionController(state: this);
    inlineAIController = InlineAIController(state: this);
    inlineAIController.addListener(refreshUI);
    navigation = NavigationService(this);
    workbench = WorkbenchApi(this);
    history = DocumentHistoryService();
    commandRegistry = CommandRegistry();
    dispatcher = CommandDispatcher(commandRegistry);
    shortcutManager = KeyboardShortcutManager(
      dispatcher: dispatcher,
      registry: commandRegistry,
    );

    // Register execution logger middleware
    dispatcher.use((cmdId, context, next) async {
      debugPrint("[Command Dispatcher] Executing: $cmdId");
      final stopwatch = Stopwatch()..start();
      final res = await next();
      stopwatch.stop();
      if (res.success) {
        debugPrint(
          "[Command Dispatcher] Completed: $cmdId in ${stopwatch.elapsedMilliseconds}ms",
        );
      } else {
        debugPrint(
          "[Command Dispatcher] Failed: $cmdId (${res.error?.message})",
        );
      }
      return res;
    });

    _registerDefaultCommands();
  }

  void _registerDefaultCommands() {
    commandRegistry.register(
      Command(
        id: WorkbenchCommands.fileOpen,
        title: "Open File",
        category: "File",
        description: "Open file from workspace path",
        execute: (ctx) async {
          final path = ctx.arguments["path"];
          if (path is String) {
            await openFile(path);
          }
          return const OperationResult.ok(null);
        },
      ),
    );
    commandRegistry.register(
      Command(
        id: WorkbenchCommands.fileQuickOpen,
        title: "Go to File...",
        category: "Navigation",
        description: "Fuzzy search files in workspace",
        shortcut: const SingleActivator(LogicalKeyboardKey.keyP, meta: true),
        execute: (ctx) async {
          eventBus.publish("Command", "quickOpen");
          return const OperationResult.ok(null);
        },
      ),
    );
    commandRegistry.register(
      Command(
        id: EditorCommands.find,
        title: "Find in Editor",
        category: "Editor",
        description: "Find text occurrences in active document",
        shortcut: const SingleActivator(LogicalKeyboardKey.keyF, meta: true),
        execute: (ctx) async {
          eventBus.publish("Command", "find");
          return const OperationResult.ok(null);
        },
      ),
    );
    commandRegistry.register(
      Command(
        id: EditorCommands.codeAction,
        title: "Code Actions / Quick Fixes",
        category: "Editor",
        description: "Show available quick fixes and code actions",
        shortcut: const SingleActivator(
          LogicalKeyboardKey.period,
          control: true,
        ),
        execute: (ctx) async {
          codeActionController.triggerCodeActions(isManual: true);
          return const OperationResult.ok(null);
        },
      ),
    );
    commandRegistry.register(
      Command(
        id: EditorCommands.quickFix,
        title: "Quick Fix",
        category: "Editor",
        description: "Apply quick fix at cursor",
        execute: (ctx) async {
          codeActionController.triggerCodeActions(isManual: true);
          return const OperationResult.ok(null);
        },
      ),
    );
    commandRegistry.register(
      Command(
        id: EditorCommands.inlineAI,
        title: "Inline AI Edit",
        category: "Editor",
        description: "Trigger inline AI prompt panel at selection or cursor",
        shortcut: const SingleActivator(LogicalKeyboardKey.keyI, meta: true),
        execute: (ctx) async {
          inlineAIController.triggerInlineAI();
          return const OperationResult.ok(null);
        },
      ),
    );
    commandRegistry.register(
      Command(
        id: EditorCommands.organizeImports,
        title: "Organize Imports",
        category: "Editor",
        description: "Organize import directives alphabetically",
        execute: (ctx) async {
          final activeTab = editor.activeTab;
          if (activeTab == null) return const OperationResult.ok(null);
          final doc = activeTab.document;
          final pos = doc.cursor;

          final token = CancellationToken();
          final languageCtx = LanguageContext(
            document: doc,
            position: pos,
            workspace: activeProject,
            workspaceRevision: 0,
            token: token,
          );

          final res = await languageIntel.getCodeActions(languageCtx, []);
          if (res.success && res.data != null) {
            for (final action in res.data!) {
              if (action.kind == CodeActionKind.sourceOrganizeImports) {
                await codeActionController.executeAction(action);
                break;
              }
            }
          }
          return const OperationResult.ok(null);
        },
      ),
    );
    commandRegistry.register(
      Command(
        id: EditorCommands.fixAll,
        title: "Fix All",
        category: "Editor",
        description: "Apply all recommended fixes in document",
        execute: (ctx) async {
          final activeTab = editor.activeTab;
          if (activeTab == null) return const OperationResult.ok(null);
          final doc = activeTab.document;
          final pos = doc.cursor;

          final token = CancellationToken();
          final languageCtx = LanguageContext(
            document: doc,
            position: pos,
            workspace: activeProject,
            workspaceRevision: 0,
            token: token,
          );

          final diags = diagnostics.getForFile(doc.path);
          final diagIds = diags.map((d) => d.id).toList();

          final res = await languageIntel.getCodeActions(languageCtx, diagIds);
          if (res.success && res.data != null) {
            for (final action in res.data!) {
              if (action.kind == CodeActionKind.sourceFixAll) {
                await codeActionController.executeAction(action);
                break;
              }
            }
          }
          return const OperationResult.ok(null);
        },
      ),
    );
    commandRegistry.register(
      Command(
        id: EditorCommands.gotoLine,
        title: "Go to Line...",
        category: "Editor",
        description: "Jump to specific line number in document",
        shortcut: const SingleActivator(LogicalKeyboardKey.keyG, meta: true),
        execute: (ctx) async {
          eventBus.publish("Command", "gotoLine");
          return const OperationResult.ok(null);
        },
      ),
    );
    commandRegistry.register(
      Command(
        id: EditorCommands.undo,
        title: "Undo",
        category: "Editor",
        description: "Undo last text edit operation",
        shortcut: const SingleActivator(LogicalKeyboardKey.keyZ, meta: true),
        execute: (ctx) async {
          final active = editor.activeTab;
          if (active == null) {
            return const OperationResult.fail(
              WorkbenchError(
                code: "NO_ACTIVE_FILE",
                message: "No active file open.",
              ),
            );
          }
          final res = await history.undo(
            active.document,
            OperationContext(timestamp: DateTime.now(), source: "keyboard"),
          );
          notifyListeners();
          return res;
        },
      ),
    );
    commandRegistry.register(
      Command(
        id: EditorCommands.redo,
        title: "Redo",
        category: "Editor",
        description: "Redo last undone text edit operation",
        shortcut: const SingleActivator(
          LogicalKeyboardKey.keyZ,
          meta: true,
          shift: true,
        ),
        execute: (ctx) async {
          final active = editor.activeTab;
          if (active == null) {
            return const OperationResult.fail(
              WorkbenchError(
                code: "NO_ACTIVE_FILE",
                message: "No active file open.",
              ),
            );
          }
          final res = await history.redo(
            active.document,
            OperationContext(timestamp: DateTime.now(), source: "keyboard"),
          );
          notifyListeners();
          return res;
        },
      ),
    );
    commandRegistry.register(
      Command(
        id: EditorCommands.commentLine,
        title: "Toggle Line Comment",
        category: "Editor",
        description: "Comment or uncomment active line(s)",
        shortcut: const SingleActivator(LogicalKeyboardKey.slash, meta: true),
        execute: (ctx) async {
          final active = editor.activeTab;
          if (active == null) {
            return const OperationResult.fail(
              WorkbenchError(
                code: "NO_ACTIVE_FILE",
                message: "No active file open.",
              ),
            );
          }
          final res = await editor.commentLine(active.document, history);
          notifyListeners();
          return res;
        },
      ),
    );
    commandRegistry.register(
      Command(
        id: EditorCommands.duplicateLine,
        title: "Duplicate Line",
        category: "Editor",
        description: "Duplicate selected line(s) downwards",
        execute: (ctx) async {
          final active = editor.activeTab;
          if (active == null) {
            return const OperationResult.fail(
              WorkbenchError(
                code: "NO_ACTIVE_FILE",
                message: "No active file open.",
              ),
            );
          }
          final res = await editor.duplicateLine(active.document, history);
          notifyListeners();
          return res;
        },
      ),
    );
    commandRegistry.register(
      Command(
        id: EditorCommands.deleteLine,
        title: "Delete Line",
        category: "Editor",
        description: "Delete active or selected line(s)",
        execute: (ctx) async {
          final active = editor.activeTab;
          if (active == null) {
            return const OperationResult.fail(
              WorkbenchError(
                code: "NO_ACTIVE_FILE",
                message: "No active file open.",
              ),
            );
          }
          final res = await editor.deleteLine(active.document, history);
          notifyListeners();
          return res;
        },
      ),
    );
    commandRegistry.register(
      Command(
        id: EditorCommands.moveLineUp,
        title: "Move Line Up",
        category: "Editor",
        description: "Swap active line(s) with the line above",
        execute: (ctx) async {
          final active = editor.activeTab;
          if (active == null) {
            return const OperationResult.fail(
              WorkbenchError(
                code: "NO_ACTIVE_FILE",
                message: "No active file open.",
              ),
            );
          }
          final res = await editor.moveLineUp(active.document, history);
          notifyListeners();
          return res;
        },
      ),
    );
    commandRegistry.register(
      Command(
        id: EditorCommands.moveLineDown,
        title: "Move Line Down",
        category: "Editor",
        description: "Swap active line(s) with the line below",
        execute: (ctx) async {
          final active = editor.activeTab;
          if (active == null) {
            return const OperationResult.fail(
              WorkbenchError(
                code: "NO_ACTIVE_FILE",
                message: "No active file open.",
              ),
            );
          }
          final res = await editor.moveLineDown(active.document, history);
          notifyListeners();
          return res;
        },
      ),
    );
    commandRegistry.register(
      Command(
        id: EditorCommands.selectAll,
        title: "Select All",
        category: "Editor",
        description: "Select entire document contents",
        shortcut: const SingleActivator(LogicalKeyboardKey.keyA, meta: true),
        execute: (ctx) async {
          final active = editor.activeTab;
          if (active == null) {
            return const OperationResult.fail(
              WorkbenchError(
                code: "NO_ACTIVE_FILE",
                message: "No active file open.",
              ),
            );
          }
          editor.selectAll(active.document);
          notifyListeners();
          return const OperationResult.ok(null);
        },
      ),
    );
    commandRegistry.register(
      Command(
        id: EditorCommands.replace,
        title: "Replace in Editor",
        category: "Editor",
        description: "Open find and replace overlay",
        shortcut: const SingleActivator(LogicalKeyboardKey.keyH, meta: true),
        execute: (ctx) async {
          eventBus.publish("Command", "replace");
          return const OperationResult.ok(null);
        },
      ),
    );
    commandRegistry.register(
      Command(
        id: EditorCommands.commentBlock,
        title: "Toggle Block Comment",
        category: "Editor",
        description: "Toggle block comment markers",
        shortcut: const SingleActivator(
          LogicalKeyboardKey.keyA,
          meta: true,
          shift: true,
          alt: true,
        ),
        execute: (ctx) async {
          return const OperationResult.ok(null);
        },
      ),
    );
    commandRegistry.register(
      Command(
        id: EditorCommands.indent,
        title: "Indent Line",
        category: "Editor",
        description: "Indent line or selection by two spaces",
        shortcut: const SingleActivator(LogicalKeyboardKey.tab),
        execute: (ctx) async {
          final active = editor.activeTab;
          if (active == null) {
            return const OperationResult.fail(
              WorkbenchError(
                code: "NO_ACTIVE_FILE",
                message: "No active file open.",
              ),
            );
          }
          final offset = active.document.positionToOffset(
            active.document.cursor,
          );
          final op = InsertTextOperation(index: offset, text: "  ");
          final res = await op.apply(
            active.document,
            OperationContext(timestamp: DateTime.now(), source: "keyboard"),
          );
          if (res.success) {
            history.recordOperation(active.document.id, op);
          }
          notifyListeners();
          return res;
        },
      ),
    );
    commandRegistry.register(
      Command(
        id: EditorCommands.outdent,
        title: "Outdent Line",
        category: "Editor",
        description: "Outdent line or selection",
        shortcut: const SingleActivator(LogicalKeyboardKey.tab, shift: true),
        execute: (ctx) async {
          final active = editor.activeTab;
          if (active == null) {
            return const OperationResult.fail(
              WorkbenchError(
                code: "NO_ACTIVE_FILE",
                message: "No active file open.",
              ),
            );
          }
          final lineText =
              active.document.lines[active.document.cursorLine - 1];
          if (lineText.startsWith("  ")) {
            final startOffset = active.document.positionToOffset(
              Position(line: active.document.cursorLine, column: 1),
            );
            final op = DeleteTextOperation(index: startOffset, text: "  ");
            final res = await op.apply(
              active.document,
              OperationContext(timestamp: DateTime.now(), source: "keyboard"),
            );
            if (res.success) {
              history.recordOperation(active.document.id, op);
            }
            notifyListeners();
            return res;
          }
          return const OperationResult.ok(null);
        },
      ),
    );
    commandRegistry.register(
      Command(
        id: EditorCommands.autoFormat,
        title: "Format Document",
        category: "Editor",
        description: "Auto-format document using standard rules",
        shortcut: const SingleActivator(
          LogicalKeyboardKey.keyF,
          shift: true,
          alt: true,
        ),
        execute: (ctx) async {
          return const OperationResult.ok(null);
        },
      ),
    );
    commandRegistry.register(
      Command(
        id: WorkbenchCommands.showCommands,
        title: "Command Palette",
        category: "Command",
        description: "Show Command Palette",
        shortcut: const SingleActivator(
          LogicalKeyboardKey.keyP,
          meta: true,
          shift: true,
        ),
        execute: (ctx) async {
          eventBus.publish("Command", "showCommands");
          return const OperationResult.ok(null);
        },
      ),
    );
    commandRegistry.register(
      Command(
        id: EditorCommands.gotoDefinition,
        title: "Go to Definition",
        category: "Editor",
        description: "Resolve definition for symbol under cursor",
        shortcut: const SingleActivator(LogicalKeyboardKey.f12),
        execute: (ctx) async {
          eventBus.publish("Command", "gotoDefinition");
          return const OperationResult.ok(null);
        },
      ),
    );
    commandRegistry.register(
      Command(
        id: WorkbenchCommands.fileSave,
        title: "Save File",
        category: "File",
        description: "Save active file content to disk",
        shortcut: const SingleActivator(LogicalKeyboardKey.keyS, meta: true),
        execute: (ctx) async {
          final active = editor.activeTab;
          if (active == null) {
            return const OperationResult.fail(
              WorkbenchError(
                code: "NO_ACTIVE_FILE",
                message: "No active file open to save.",
              ),
            );
          }
          final doc = active.document;
          doc.state = DocumentState.saving;
          notifyListeners();
          final res = await saveFileContent(doc.path, doc.content);
          if (!res.success) {
            doc.state = DocumentState.dirty;
            notifyListeners();
          }
          return res;
        },
      ),
    );
    commandRegistry.register(
      Command(
        id: WorkbenchCommands.fileNew,
        title: "New File",
        category: "File",
        description: "Create a new file in the workspace",
        execute: (ctx) async {
          final path = ctx.arguments["path"];
          if (path is String) {
            final content = ctx.arguments["content"] as String? ?? "";
            final res = await createFile(path, content);
            if (res.success) {
              await openFile(path);
            }
            return res;
          }
          eventBus.publish("Command", "newFilePrompt");
          return const OperationResult.ok(null);
        },
      ),
    );
    commandRegistry.register(
      Command(
        id: WorkbenchCommands.fileRename,
        title: "Rename File",
        category: "File",
        description: "Rename a file in the workspace",
        execute: (ctx) async {
          final path = ctx.arguments["path"];
          final newPath = ctx.arguments["newPath"];
          if (path is String && newPath is String) {
            return await renameFile(path, newPath);
          }
          final active = editor.activeTab;
          if (active != null) {
            eventBus.publish("Command", "renameFilePrompt");
            return const OperationResult.ok(null);
          }
          return const OperationResult.fail(
            WorkbenchError(
              code: "INVALID_ARGUMENTS",
              message: "Missing source or destination paths.",
            ),
          );
        },
      ),
    );
    commandRegistry.register(
      Command(
        id: WorkbenchCommands.fileDelete,
        title: "Delete File",
        category: "File",
        description: "Delete a file from the workspace",
        execute: (ctx) async {
          final path = ctx.arguments["path"];
          if (path is String) {
            return await deleteFile(path);
          }
          final active = editor.activeTab;
          if (active != null) {
            return await deleteFile(active.document.path);
          }
          return const OperationResult.fail(
            WorkbenchError(
              code: "INVALID_ARGUMENTS",
              message: "No file specified to delete.",
            ),
          );
        },
      ),
    );
    commandRegistry.register(
      Command(
        id: EditorCommands.fold,
        title: "Fold",
        category: "Editor",
        description: "Fold region at cursor",
        execute: (ctx) async {
          final active = editor.activeTab;
          if (active == null) return const OperationResult.fail(null);
          active.document.collapse(active.document.cursorLine);
          notifyListeners();
          return const OperationResult.ok(null);
        },
      ),
    );
    commandRegistry.register(
      Command(
        id: EditorCommands.unfold,
        title: "Unfold",
        category: "Editor",
        description: "Unfold region at cursor",
        execute: (ctx) async {
          final active = editor.activeTab;
          if (active == null) return const OperationResult.fail(null);
          active.document.expand(active.document.cursorLine);
          notifyListeners();
          return const OperationResult.ok(null);
        },
      ),
    );
    commandRegistry.register(
      Command(
        id: EditorCommands.foldAll,
        title: "Fold All",
        category: "Editor",
        description: "Fold all regions in the active file",
        execute: (ctx) async {
          final active = editor.activeTab;
          if (active == null) return const OperationResult.fail(null);
          active.document.collapseAll();
          notifyListeners();
          return const OperationResult.ok(null);
        },
      ),
    );
    commandRegistry.register(
      Command(
        id: EditorCommands.unfoldAll,
        title: "Unfold All",
        category: "Editor",
        description: "Unfold all regions in the active file",
        execute: (ctx) async {
          final active = editor.activeTab;
          if (active == null) return const OperationResult.fail(null);
          active.document.expandAll();
          notifyListeners();
          return const OperationResult.ok(null);
        },
      ),
    );
    commandRegistry.register(
      Command(
        id: EditorCommands.toggleFold,
        title: "Toggle Fold",
        category: "Editor",
        description: "Toggle folding region at cursor",
        execute: (ctx) async {
          final active = editor.activeTab;
          if (active == null) return const OperationResult.fail(null);
          active.document.toggleFold(active.document.cursorLine);
          notifyListeners();
          return const OperationResult.ok(null);
        },
      ),
    );
    commandRegistry.register(
      Command(
        id: EditorCommands.gotoPreviousLocation,
        title: "Go Back",
        category: "Navigation",
        description: "Go back to previous file location",
        shortcut: const SingleActivator(
          LogicalKeyboardKey.arrowLeft,
          alt: true,
        ),
        execute: (ctx) async {
          final loc = navigationHistory.goBack();
          if (loc != null) {
            await openFile(loc.path, line: loc.line);
          }
          return const OperationResult.ok(null);
        },
      ),
    );
    commandRegistry.register(
      Command(
        id: EditorCommands.gotoNextLocation,
        title: "Go Forward",
        category: "Navigation",
        description: "Go forward to next file location",
        shortcut: const SingleActivator(
          LogicalKeyboardKey.arrowRight,
          alt: true,
        ),
        execute: (ctx) async {
          final loc = navigationHistory.goForward();
          if (loc != null) {
            await openFile(loc.path, line: loc.line);
          }
          return const OperationResult.ok(null);
        },
      ),
    );
    commandRegistry.register(
      Command(
        id: EditorCommands.toggleMinimap,
        title: "Toggle Minimap",
        category: "Editor",
        description: "Show or hide the editor minimap",
        execute: (ctx) async {
          eventBus.publish("Command", "toggleMinimap");
          return const OperationResult.ok(null);
        },
      ),
    );
    commandRegistry.register(
      Command(
        id: ProblemsCommands.togglePanel,
        title: "Toggle Problems Panel",
        category: "Problems",
        description: "Show or hide the problems panel",
        execute: (ctx) async {
          toggleProblemsPanel();
          return const OperationResult.ok(null);
        },
      ),
    );
    commandRegistry.register(
      Command(
        id: ProblemsCommands.nextError,
        title: "Next Error",
        category: "Problems",
        description: "Go to next error in the document",
        shortcut: const SingleActivator(LogicalKeyboardKey.f8),
        execute: (ctx) async {
          final active = editor.activeTab;
          if (active == null) return const OperationResult.fail(null);
          final doc = active.document;
          final diags = diagnostics.getForFile(doc.path);
          final errors = diags
              .where((d) => d.severity == DiagnosticSeverity.error)
              .toList();
          if (errors.isEmpty) return const OperationResult.ok(null);

          errors.sort(
            (a, b) => a.range.start.line != b.range.start.line
                ? a.range.start.line.compareTo(b.range.start.line)
                : a.range.start.column.compareTo(b.range.start.column),
          );

          final current = doc.cursor;
          final next = errors.firstWhere(
            (e) =>
                e.range.start.line > current.line ||
                (e.range.start.line == current.line &&
                    e.range.start.column > current.column),
            orElse: () => errors.first,
          );

          doc.updateCursor(
            Position(
              line: next.range.start.line,
              column: next.range.start.column,
            ),
          );
          doc.updateSelection(next.range);
          notifyListeners();
          return const OperationResult.ok(null);
        },
      ),
    );
    commandRegistry.register(
      Command(
        id: ProblemsCommands.nextWarning,
        title: "Next Warning",
        category: "Problems",
        description: "Go to next warning in the document",
        shortcut: const SingleActivator(LogicalKeyboardKey.f8, shift: true),
        execute: (ctx) async {
          final active = editor.activeTab;
          if (active == null) return const OperationResult.fail(null);
          final doc = active.document;
          final diags = diagnostics.getForFile(doc.path);
          final warnings = diags
              .where((d) => d.severity == DiagnosticSeverity.warning)
              .toList();
          if (warnings.isEmpty) return const OperationResult.ok(null);

          warnings.sort(
            (a, b) => a.range.start.line != b.range.start.line
                ? a.range.start.line.compareTo(b.range.start.line)
                : a.range.start.column.compareTo(b.range.start.column),
          );

          final current = doc.cursor;
          final next = warnings.firstWhere(
            (e) =>
                e.range.start.line > current.line ||
                (e.range.start.line == current.line &&
                    e.range.start.column > current.column),
            orElse: () => warnings.first,
          );

          doc.updateCursor(
            Position(
              line: next.range.start.line,
              column: next.range.start.column,
            ),
          );
          doc.updateSelection(next.range);
          notifyListeners();
          return const OperationResult.ok(null);
        },
      ),
    );
    commandRegistry.register(
      Command(
        id: ProblemsCommands.previous,
        title: "Previous Problem",
        category: "Problems",
        description: "Go to previous warning/error in the document",
        execute: (ctx) async {
          final active = editor.activeTab;
          if (active == null) return const OperationResult.fail(null);
          final doc = active.document;
          final diags = diagnostics.getForFile(doc.path).toList();
          if (diags.isEmpty) return const OperationResult.ok(null);

          diags.sort(
            (a, b) => a.range.start.line != b.range.start.line
                ? a.range.start.line.compareTo(b.range.start.line)
                : a.range.start.column.compareTo(b.range.start.column),
          );

          final current = doc.cursor;
          final prev = diags.lastWhere(
            (e) =>
                e.range.start.line < current.line ||
                (e.range.start.line == current.line &&
                    e.range.start.column < current.column),
            orElse: () => diags.last,
          );

          doc.updateCursor(
            Position(
              line: prev.range.start.line,
              column: prev.range.start.column,
            ),
          );
          doc.updateSelection(prev.range);
          notifyListeners();
          return const OperationResult.ok(null);
        },
      ),
    );
    commandRegistry.register(
      Command(
        id: "editor.insertText",
        title: "Insert Text",
        category: "Editor",
        description: "Insert text at the current cursor position",
        execute: (ctx) async {
          final active = editor.activeTab;
          if (active == null) {
            return const OperationResult.fail(
              WorkbenchError(
                code: "NO_ACTIVE_FILE",
                message: "No active file open.",
              ),
            );
          }
          final text = ctx.arguments['text'] as String?;
          if (text == null || text.isEmpty) {
            return const OperationResult.ok(null);
          }
          final offset = active.document.positionToOffset(
            active.document.cursor,
          );
          final op = InsertTextOperation(index: offset, text: text);
          final res = await op.apply(
            active.document,
            OperationContext(timestamp: DateTime.now(), source: "chat"),
          );
          if (res.success) {
            history.recordOperation(active.document.id, op);
          }
          notifyListeners();
          return res;
        },
      ),
    );
  }

  /// Public wrapper for notifyListeners, callable from WorkbenchApi facade.
  void refreshUI() {
    notifyListeners();
  }

  void triggerDiagnosticsDebounced(String path) {
    _diagTimers[path]?.cancel();
    _diagTimers[path] = Timer(const Duration(milliseconds: 300), () {
      refreshDiagnosticsForFile(path);
    });
  }

  Future<void> refreshDiagnosticsForFile(String path) async {
    final doc = documentService.getDocument(DocumentId(path));
    if (doc == null) return;

    final fileColl = diagnostics.files[path];
    if (fileColl != null) {
      final providerDiags = fileColl.providers['default-diagnostics'];
      if (providerDiags != null &&
          providerDiags.revision == doc.version.localRevision) {
        return;
      }
    }

    final languageContext = LanguageContext(
      document: doc,
      position: const Position(line: 1, column: 1),
      workspace: "",
      workspaceRevision: 0,
      token: CancellationToken(),
    );

    final res = await languageIntel.getDiagnostics(languageContext);
    if (res.success && res.data != null) {
      diagnostics.updateForFile(
        path: path,
        providerId: 'default-diagnostics',
        revision: doc.version.localRevision,
        diagnostics: res.data!,
      );
      notifyListeners();
    }
  }

  void setTab(String tab) {
    _activeTab = tab;
    notifyListeners();
  }

  void connect(int port) {
    _serverPort = port;
    _isConnected = true;
    _fetchInitialData();
    _subscribeToEvents(port);
    restoreRecoverySession();

    languageRegistry.registerHoverProvider(
      'dart',
      DefaultHoverProvider(port: port),
    );
    languageRegistry.registerHoverProvider(
      'json',
      DefaultHoverProvider(port: port),
    );
    languageRegistry.registerHoverProvider(
      'yaml',
      DefaultHoverProvider(port: port),
    );

    languageRegistry.registerDiagnosticsProvider(
      'dart',
      DefaultDiagnosticsProvider(port: port),
    );
    languageRegistry.registerDiagnosticsProvider(
      'json',
      DefaultDiagnosticsProvider(port: port),
    );
    languageRegistry.registerDiagnosticsProvider(
      'yaml',
      DefaultDiagnosticsProvider(port: port),
    );
    languageRegistry.registerDiagnosticsProvider(
      'markdown',
      DefaultDiagnosticsProvider(port: port),
    );

    languageRegistry.registerCompletionProvider(
      'dart',
      DefaultCompletionProvider(port: port),
    );
    languageRegistry.registerCompletionProvider(
      'json',
      DefaultCompletionProvider(port: port),
    );
    languageRegistry.registerCompletionProvider(
      'yaml',
      DefaultCompletionProvider(port: port),
    );
    languageRegistry.registerCompletionProvider(
      'markdown',
      DefaultCompletionProvider(port: port),
    );

    languageRegistry.registerSignatureHelpProvider(
      'dart',
      DefaultSignatureHelpProvider(port: port),
    );

    languageRegistry.registerCodeActionProvider(
      'dart',
      DefaultCodeActionProvider(port: port),
    );

    notifyListeners();
  }

  void disconnect() {
    _isConnected = false;
    _wsChannel?.sink.close();
    notifyListeners();
  }

  Future<void> _fetchInitialData() async {
    try {
      final hRes = await http.get(
        Uri.parse('http://localhost:$_serverPort/api/health'),
      );
      final fRes = await http.get(
        Uri.parse('http://localhost:$_serverPort/api/features'),
      );
      final mRes = await http.get(
        Uri.parse('http://localhost:$_serverPort/api/metrics'),
      );
      final vRes = await http.get(
        Uri.parse('http://localhost:$_serverPort/api/v1/version'),
      );

      _health = Map<String, String>.from(jsonDecode(hRes.body));
      _features = Map<String, bool>.from(jsonDecode(fRes.body));
      _metrics = Map<String, dynamic>.from(jsonDecode(mRes.body));
      final vJson = jsonDecode(vRes.body);
      _version = vJson['data']['platform'] ?? 'v1.1.0';
      final wRes = await http.get(
        Uri.parse('http://localhost:$_serverPort/api/v1/workspace'),
      );
      final wJson = jsonDecode(wRes.body);
      _activeProject =
          wJson['data']['activeProject'] ?? 'indiverse-engineering-platform';
      _branchName = wJson['data']['branch'] ?? 'main';

      await reloadWorkspace();
    } catch (_) {}
  }

  int _getPriority(SaveReason reason) {
    switch (reason) {
      case SaveReason.manual:
        return 3;
      case SaveReason.focusLost:
      case SaveReason.windowClose:
        return 2;
      case SaveReason.autoDelay:
        return 1;
      case SaveReason.recovery:
        return 0;
    }
  }

  void handleAutoSaveOnEdit(String path) {
    if (autoSavePolicy == AutoSavePolicy.afterDelay) {
      _autoSaveDebounceTimer?.cancel();
      _autoSaveDebounceTimer = Timer(const Duration(seconds: 2), () {
        final doc = documentService.getDocument(DocumentId(path));
        if (doc != null && doc.state == DocumentState.dirty) {
          saveFileContent(path, doc.content, reason: SaveReason.autoDelay);
        }
      });
    }
    triggerRecoverySave();
  }

  Future<void> saveAllDirtyDocuments({
    SaveReason reason = SaveReason.focusLost,
  }) async {
    final futures = <Future>[];
    for (final tab in editor.tabs) {
      final doc = tab.document;
      if (doc.state == DocumentState.dirty) {
        futures.add(saveFileContent(doc.path, doc.content, reason: reason));
      }
    }
    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }
  }

  void triggerRecoverySave() {
    if (editor.tabs.isEmpty) {
      _recoveryService.clear();
      return;
    }

    final collapsedFolds = <String, List<RecoveredFold>>{};
    for (final tab in editor.tabs) {
      final doc = tab.document;
      collapsedFolds[doc.path] = doc.foldingRegions
          .expand((r) => r.toFlatList())
          .where((n) => n.collapsed)
          .map(
            (n) => RecoveredFold(
              startLine: n.startLine,
              endLine: n.endLine,
              collapsed: true,
            ),
          )
          .toList();
    }

    _recoveryService.save(
      RecoverySession(
        workspace: Directory.current.path,
        savedAt: DateTime.now(),
        documents: editor.tabs.map((tab) {
          final doc = tab.document;
          return RecoveredDocument(
            path: doc.path,
            cursor: doc.cursor,
            selection: doc.selection,
            scrollOffset: doc.scrollOffset,
            folds: collapsedFolds[doc.path] ?? [],
            revision: doc.version.localRevision,
            isDirty: doc.state == DocumentState.dirty,
            buffer: doc.content,
          );
        }).toList(),
        activeTabIndex: editor.activeTabIndex,
      ),
    );
  }

  Future<void> restoreRecoverySession() async {
    final session = await _recoveryService.restore();
    if (session == null) return;

    for (final docData in session.documents) {
      final doc = EditorDocument(
        id: docData.path,
        path: docData.path,
        name: docData.path.split('/').last,
        content: docData.buffer,
        language: docData.path.split('.').last,
        encoding: 'utf8',
        lastModified: '',
        readOnly: false,
      );

      doc.addListener(() {
        handleAutoSaveOnEdit(doc.path);
        triggerDiagnosticsDebounced(doc.path);
      });

      doc.updateCursor(docData.cursor);
      if (docData.selection != null) {
        doc.updateSelection(docData.selection);
      }
      doc.scrollOffset = docData.scrollOffset;
      doc.state = docData.isDirty ? DocumentState.dirty : DocumentState.clean;

      doc.reparseFolding();
      for (final fold in docData.folds) {
        doc.collapse(fold.startLine);
      }

      editor.open(doc);
      documentService.cacheDocument(DocumentId(doc.path), doc);
    }

    if (session.activeTabIndex >= 0 &&
        session.activeTabIndex < editor.tabs.length) {
      editor.activate(session.activeTabIndex);
    }
    notifyListeners();
  }

  Future<void> reloadFileFromDisk(String path) async {
    final doc = documentService.getDocument(DocumentId(path));
    if (doc == null) return;
    try {
      final fileRes = await http.get(
        Uri.parse(
          'http://localhost:$_serverPort/api/v1/workspace/file?path=$path',
        ),
      );
      final fileEnvelope = jsonDecode(fileRes.body);
      if (fileEnvelope["success"] == true) {
        final content = fileEnvelope["data"]["content"] ?? '';
        doc.lockReason = null;
        doc.state = DocumentState.clean;

        final originalCursor = doc.cursor;
        doc.replaceBuffer(content);
        doc.updateCursor(
          originalCursor.line <= doc.lineCount
              ? originalCursor
              : Position(line: doc.lineCount, column: 1),
        );

        eventBus.publish("Document", DocumentReloadedEvent(path));
        notifyListeners();
        triggerRecoverySave();
      }
    } catch (_) {}
  }

  Future<void> _processSaveQueue() async {
    if (_isSavingQueue) return;
    _isSavingQueue = true;

    while (true) {
      _saveQueue.sort((a, b) => b.priority.compareTo(a.priority));

      SaveTask? nextTask;
      for (final task in _saveQueue) {
        if (task.state == SaveTaskState.queued) {
          nextTask = task;
          break;
        }
      }

      if (nextTask == null) break;

      nextTask.state = SaveTaskState.running;
      notifyListeners();

      OperationResult<void> res = const OperationResult.fail(null);
      int retries = 3;
      while (retries > 0) {
        res = await _executeSaveFile(nextTask.path);
        if (res.success) {
          break;
        }
        retries--;
        if (retries > 0) {
          await Future.delayed(const Duration(milliseconds: 200));
        }
      }

      if (res.success) {
        nextTask.state = SaveTaskState.completed;
        _lastSaveTime = DateTime.now();
        refreshDiagnosticsForFile(nextTask.path);
      } else {
        nextTask.state = SaveTaskState.failed;
      }

      _saveQueue.remove(nextTask);
      nextTask.completer.complete(res);
      notifyListeners();
    }

    _isSavingQueue = false;
    notifyListeners();
  }

  Future<OperationResult<void>> _executeSaveFile(String path) async {
    final doc = documentService.getDocument(DocumentId(path));
    if (doc == null) return const OperationResult.fail(null);
    final previousState = doc.state;
    doc.state = DocumentState.saving;
    notifyListeners();

    try {
      final res = await http.put(
        Uri.parse(
          'http://localhost:$_serverPort/api/v1/workspace/file?path=$path',
        ),
        body: jsonEncode({"content": doc.content}),
      );
      final envelope = jsonDecode(res.body);
      if (envelope["success"] == true) {
        doc.markSaved(DateTime.now());
        doc.state = DocumentState.clean;
        notifyListeners();
        return const OperationResult.ok(null);
      } else {
        doc.state = previousState;
        notifyListeners();
        return const OperationResult.fail(null);
      }
    } catch (_) {
      doc.state = previousState;
      notifyListeners();
      return const OperationResult.fail(null);
    }
  }

  Future<void> reloadWorkspace() async {
    workspaceCache.clear();
    _rootNodes.clear();
    final treeData = await fetchDirectoryContents('/');
    _rootNodes.addAll(treeData);
    notifyListeners();
  }

  Future<List<TreeNode>> fetchDirectoryContents(String path) async {
    final cached = workspaceCache.get(path);
    if (cached != null) return cached;

    try {
      final res = await http.get(
        Uri.parse(
          'http://localhost:$_serverPort/api/v1/workspace?path=$path&recursive=false',
        ),
      );
      final envelope = jsonDecode(res.body);
      if (envelope["success"] == true) {
        final filesList = envelope["data"]["files"] as List? ?? [];
        final nodes = filesList.map((item) {
          return TreeNode(
            name: item["name"] ?? '',
            path: item["path"] ?? '',
            isDirectory: item["type"] == "directory",
            size: item["size"] ?? 0,
            modified: item["modified"] ?? '',
          );
        }).toList();

        // Sort: directories first, then alphabetically
        nodes.sort((a, b) {
          if (a.isDirectory && !b.isDirectory) return -1;
          if (!a.isDirectory && b.isDirectory) return 1;
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });

        workspaceCache.put(path, nodes);
        return nodes;
      }
    } catch (_) {}
    return [];
  }

  Future<void> openFile(String path, {int? line}) async {
    try {
      final statRes = await http.get(
        Uri.parse(
          'http://localhost:$_serverPort/api/v1/workspace/stat?path=$path',
        ),
      );
      final fileRes = await http.get(
        Uri.parse(
          'http://localhost:$_serverPort/api/v1/workspace/file?path=$path',
        ),
      );

      final statEnvelope = jsonDecode(statRes.body);
      final fileEnvelope = jsonDecode(fileRes.body);

      if (statEnvelope["success"] == true && fileEnvelope["success"] == true) {
        final statData = statEnvelope["data"];
        final fileData = fileEnvelope["data"];

        final doc = EditorDocument(
          id: path,
          path: path,
          name: path.split('/').last,
          content: fileData["content"] ?? '',
          language: fileData["language"] ?? 'txt',
          encoding: fileData["encoding"] ?? 'utf8',
          lastModified: fileData["lastModified"] ?? '',
          readOnly: fileData["readOnly"] ?? true,
        );

        doc.addListener(() {
          handleAutoSaveOnEdit(doc.path);
          triggerDiagnosticsDebounced(doc.path);
        });

        editor.open(doc);
        documentService.cacheDocument(DocumentId(path), doc);
        refreshDiagnosticsForFile(path);
        if (line != null) {
          doc.updateCursor(Position(line: line, column: 1));
        }
        navigationHistory.record(path, line ?? 1, 1);
        triggerRecoverySave();

        // Set central selection
        _currentSelection = Selection(
          type: SelectionType.file,
          id: path,
          metadata: statData,
        );
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<OperationResult<void>> saveFileContent(
    String path,
    String content, {
    SaveReason reason = SaveReason.manual,
  }) async {
    SaveTask? existing;
    for (final task in _saveQueue) {
      if (task.path == path && task.state == SaveTaskState.queued) {
        existing = task;
        break;
      }
    }

    if (existing != null) {
      final newPri = _getPriority(reason);
      final oldPri = _getPriority(existing.reason);
      if (newPri > oldPri) {
        _saveQueue.remove(existing);
        final promoted = SaveTask(path: path, reason: reason);
        _saveQueue.add(promoted);
        _processSaveQueue();
        return promoted.completer.future;
      }
      return existing.completer.future;
    }

    final task = SaveTask(path: path, reason: reason);
    _saveQueue.add(task);
    _processSaveQueue();
    return task.completer.future;
  }

  Future<OperationResult<void>> createFile(String path, String content) async {
    try {
      final res = await http.post(
        Uri.parse(
          'http://localhost:$_serverPort/api/v1/workspace/file?path=$path',
        ),
        body: jsonEncode({"content": content}),
      );
      final envelope = jsonDecode(res.body);
      if (envelope["success"] == true) {
        await reloadWorkspace();
        return const OperationResult.ok(null);
      } else {
        final err =
            envelope["errors"] is List &&
                (envelope["errors"] as List).isNotEmpty
            ? envelope["errors"][0]
            : "Unknown error";
        return OperationResult.fail(
          WorkbenchError(code: "CREATE_FAILED", message: err),
        );
      }
    } catch (e) {
      return OperationResult.fail(
        WorkbenchError(code: "CREATE_FAILED", message: e.toString()),
      );
    }
  }

  Future<OperationResult<void>> renameFile(String path, String newPath) async {
    final doc = documentService.getDocument(DocumentId(path));
    if (doc != null) {
      doc.lockReason = DocumentLockReason.renaming;
    }
    try {
      final res = await http.post(
        Uri.parse('http://localhost:$_serverPort/api/v1/workspace/rename'),
        body: jsonEncode({"path": path, "newPath": newPath}),
      );
      final envelope = jsonDecode(res.body);
      if (envelope["success"] == true) {
        if (doc != null) {
          documentService.removeDocument(DocumentId(path));
          final newDoc = EditorDocument(
            id: newPath,
            path: newPath,
            name: newPath.split('/').last,
            content: doc.content,
            language: doc.language,
            encoding: doc.encoding,
            lastModified: DateTime.now().toIso8601String(),
            readOnly: doc.readOnly,
          );
          newDoc.state = doc.state;
          newDoc.version = doc.version;
          newDoc.cursor = doc.cursor;
          newDoc.selection = doc.selection;
          documentService.cacheDocument(DocumentId(newPath), newDoc);

          final existingTabIdx = editor.tabs.indexWhere(
            (t) => t.document.path == path,
          );
          if (existingTabIdx != -1) {
            editor.tabs[existingTabIdx] = EditorTab(document: newDoc);
          }
        }
        await reloadWorkspace();
        notifyListeners();
        return const OperationResult.ok(null);
      } else {
        final err =
            envelope["errors"] is List &&
                (envelope["errors"] as List).isNotEmpty
            ? envelope["errors"][0]
            : "Unknown error";
        return OperationResult.fail(
          WorkbenchError(code: "RENAME_FAILED", message: err),
        );
      }
    } catch (e) {
      return OperationResult.fail(
        WorkbenchError(code: "RENAME_FAILED", message: e.toString()),
      );
    } finally {
      if (doc != null) {
        doc.lockReason = null;
      }
    }
  }

  Future<OperationResult<void>> deleteFile(String path) async {
    final doc = documentService.getDocument(DocumentId(path));
    if (doc != null) {
      doc.lockReason = DocumentLockReason.deleting;
    }
    try {
      final res = await http.delete(
        Uri.parse(
          'http://localhost:$_serverPort/api/v1/workspace/file?path=$path',
        ),
      );
      final envelope = jsonDecode(res.body);
      if (envelope["success"] == true) {
        documentService.removeDocument(DocumentId(path));
        final existingTabIdx = editor.tabs.indexWhere(
          (t) => t.document.path == path,
        );
        if (existingTabIdx != -1) {
          editor.close(existingTabIdx);
        }
        await reloadWorkspace();
        notifyListeners();
        return const OperationResult.ok(null);
      } else {
        final err =
            envelope["errors"] is List &&
                (envelope["errors"] as List).isNotEmpty
            ? envelope["errors"][0]
            : "Unknown error";
        return OperationResult.fail(
          WorkbenchError(code: "DELETE_FAILED", message: err),
        );
      }
    } catch (e) {
      return OperationResult.fail(
        WorkbenchError(code: "DELETE_FAILED", message: e.toString()),
      );
    } finally {
      if (doc != null) {
        doc.lockReason = null;
      }
    }
  }

  void selectInspector(String id, String type) async {
    try {
      final res = await http.get(
        Uri.parse(
          'http://localhost:$_serverPort/api/v1/inspector?id=$id&type=$type',
        ),
      );
      final envelope = jsonDecode(res.body);
      if (envelope["success"] == true) {
        final data = envelope["data"];
        SelectionType sType;
        switch (type) {
          case 'workspace':
            sType = SelectionType.file;
            break;
          case 'search':
            sType = SelectionType.searchResult;
            break;
          case 'workflow':
            sType = SelectionType.workflow;
            break;
          case 'architecture':
            sType = SelectionType.architectureNode;
            break;
          default:
            sType = SelectionType.file;
        }

        _currentSelection = Selection(
          type: sType,
          id: id,
          metadata: Map<String, dynamic>.from(data),
        );
        notifyListeners();
      }
    } catch (_) {}
  }

  void selectArchitectureNode(String id) {
    selectInspector(id, "architecture");
  }

  void revealInExplorer(String path) {
    explorer.select(path);
    explorer.focus(path);
    notifyListeners();
  }

  void triggerAgentWorkflow() async {
    _agentWorkflowStatus = 'Running (Planning)...';
    notifyListeners();
    try {
      final res = await http.get(
        Uri.parse('http://localhost:$_serverPort/api/run'),
      );
      final data = jsonDecode(res.body);
      if (data['status'] == 'scheduled') {
        Future.delayed(const Duration(seconds: 2), () {
          _agentWorkflowStatus = 'Running (Coding)...';
          notifyListeners();
        });
        Future.delayed(const Duration(seconds: 4), () {
          _agentWorkflowStatus = 'Running (Reviewing)...';
          notifyListeners();
        });
        Future.delayed(const Duration(seconds: 6), () {
          _agentWorkflowStatus = 'Completed';
          _metrics['agentActiveSessionsCount'] =
              (_metrics['agentActiveSessionsCount'] ?? 0) + 1;
          notifyListeners();
        });
      }
    } catch (_) {
      _agentWorkflowStatus = 'Failed';
      notifyListeners();
    }
  }

  int _wsRetryCount = 0;
  Timer? _wsReconnectTimer;

  void _subscribeToEvents(int port) {
    _wsReconnectTimer?.cancel();
    try {
      watcherState = WorkspaceWatcherState.reconnecting;
      notifyListeners();

      _wsChannel = WebSocketChannel.connect(
        Uri.parse('ws://localhost:$port/ws/events'),
      );
      _wsChannel!.stream.listen(
        (message) {
          _wsRetryCount = 0;
          watcherState = WorkspaceWatcherState.connected;
          notifyListeners();

          final data = jsonDecode(message);
          final category = data['category'] ?? 'Event';
          final event = data['event'] ?? 'unknown';
          final payload = data['payload'] ?? '';
          final path = data['path'] ?? '';

          if (category == 'workspace') {
            if (path.isNotEmpty) {
              workspaceCache.invalidate(path);
              reloadWorkspace();

              final doc = documentService.getDocument(DocumentId(path));
              if (doc != null) {
                final timestamp = DateTime.now();
                if (event == 'modified') {
                  eventBus.publish(
                    "Workspace",
                    WorkspaceModifiedEvent(path, timestamp),
                  );
                  if (doc.state == DocumentState.dirty) {
                    doc.state = DocumentState.conflict;
                    eventBus.publish(
                      "Document",
                      DocumentConflictEvent(
                        path,
                        timestamp.toIso8601String(),
                        doc.version.localRevision,
                      ),
                    );
                  } else {
                    reloadFileFromDisk(path);
                  }
                } else if (event == 'deleted') {
                  eventBus.publish(
                    "Workspace",
                    WorkspaceDeletedEvent(path, timestamp),
                  );
                  doc.state = DocumentState.conflict;
                  eventBus.publish(
                    "Document",
                    DocumentConflictEvent(
                      path,
                      timestamp.toIso8601String(),
                      doc.version.localRevision,
                    ),
                  );
                } else if (event == 'created') {
                  eventBus.publish(
                    "Workspace",
                    WorkspaceCreatedEvent(path, timestamp),
                  );
                }
              }
            }
          }

          _eventLogs.insert(0, "[$category/$event] $payload");
          notifyListeners();
        },
        onError: (_) {
          _handleWsDisconnect(port);
        },
        onDone: () {
          _handleWsDisconnect(port);
        },
      );
    } catch (_) {
      _handleWsDisconnect(port);
    }
  }

  void _handleWsDisconnect(int port) {
    watcherState = WorkspaceWatcherState.disconnected;
    _wsChannel?.sink.close();
    notifyListeners();

    _wsRetryCount++;
    final delay = _wsRetryCount == 1 ? 1 : (_wsRetryCount == 2 ? 2 : 5);

    _wsReconnectTimer?.cancel();
    _wsReconnectTimer = Timer(Duration(seconds: delay), () {
      _subscribeToEvents(port);
    });
  }

  Future<List<Map<String, dynamic>>> fetchOutline(DocumentId id) async {
    try {
      final res = await http.get(
        Uri.parse(
          'http://localhost:$_serverPort/api/v1/code/outline?path=${id.value}',
        ),
      );
      final envelope = jsonDecode(res.body);
      if (envelope["success"] == true) {
        final outline = List<Map<String, dynamic>>.from(
          envelope["data"]["outline"] ?? [],
        );
        documentService.cacheOutline(id, outline);
        return outline;
      }
    } catch (_) {}
    return [];
  }

  Future<Map<String, dynamic>?> fetchDefinition(SymbolId id) async {
    try {
      final res = await http.get(
        Uri.parse(
          'http://localhost:$_serverPort/api/v1/code/definition?name=${id.value}',
        ),
      );
      final envelope = jsonDecode(res.body);
      if (envelope["success"] == true) {
        return Map<String, dynamic>.from(envelope["data"] ?? {});
      }
    } catch (_) {}
    return null;
  }

  Future<List<Map<String, dynamic>>> fetchReferences(SymbolId id) async {
    try {
      final res = await http.get(
        Uri.parse(
          'http://localhost:$_serverPort/api/v1/code/references?name=${id.value}',
        ),
      );
      final envelope = jsonDecode(res.body);
      if (envelope["success"] == true) {
        return List<Map<String, dynamic>>.from(
          envelope["data"]["references"] ?? [],
        );
      }
    } catch (_) {}
    return [];
  }

  Future<Map<String, dynamic>> fetchIndexStatus() async {
    try {
      final res = await http.get(
        Uri.parse('http://localhost:$_serverPort/api/v1/code/diagnostics'),
      );
      final envelope = jsonDecode(res.body);
      if (envelope["success"] == true) {
        return Map<String, dynamic>.from(envelope["data"] ?? {});
      }
    } catch (_) {}
    return {};
  }

  int get signatureRequests => languageIntel.signatureRequests;
  int get signatureCacheHits => languageIntel.signatureCacheHits;
  int get signatureTimeouts => languageIntel.signatureTimeouts;
  String get activeSignatureProvider => languageIntel.activeSignatureProvider;
  Duration get totalSignatureLatency => languageIntel.totalSignatureLatency;

  int get codeActionRequests => languageIntel.codeActionRequests;
  int get codeActionCacheHits => languageIntel.codeActionCacheHits;
  int get codeActionTimeouts => languageIntel.codeActionTimeouts;
  int get codeActionsApplied => languageIntel.codeActionsApplied;
  int get codeActionsFailed => languageIntel.codeActionsFailed;
  String get activeCodeActionProvider => languageIntel.activeCodeActionProvider;
  Duration get totalCodeActionLatency => languageIntel.totalCodeActionLatency;
  Duration get totalCodeActionApplyTime =>
      languageIntel.totalCodeActionApplyTime;
}
