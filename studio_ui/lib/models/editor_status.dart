import 'workspace_events.dart';
import 'editor_document.dart';

enum EditorMode { insert, overwrite }

class EditorStatus {
  final Position cursor;
  final String encoding;
  final String newline;
  final String language;
  final int revision;
  final int foldedRegions;
  final bool readOnly;
  final EditorMode mode;
  final WorkspaceWatcherState watcherState;
  final bool recoveryActive;
  final int queuedSaves;
  final String lastSaveTime;
  final AutoSavePolicy autoSavePolicy;

  const EditorStatus({
    required this.cursor,
    required this.encoding,
    required this.newline,
    required this.language,
    required this.revision,
    required this.foldedRegions,
    required this.readOnly,
    required this.mode,
    required this.watcherState,
    required this.recoveryActive,
    required this.queuedSaves,
    required this.lastSaveTime,
    required this.autoSavePolicy,
  });
}
