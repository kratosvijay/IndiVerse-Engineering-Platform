import 'workspace.dart';

class WorkspaceRegistry {
  Workspace? _active;
  final List<Workspace> _recents = [];

  Workspace? get active => _active;

  void setActive(Workspace workspace) {
    _active = workspace;
    if (!_recents.any((w) => w.rootPath == workspace.rootPath)) {
      _recents.add(workspace);
    }
  }

  void clearActive() {
    _active = null;
  }

  List<Workspace> get recents => List.unmodifiable(_recents);
}
