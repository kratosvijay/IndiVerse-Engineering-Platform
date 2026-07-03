import '../../../models/editor_document.dart';

class EditorController {
  final List<EditorTab> tabs = [];
  int activeTabIndex = -1;
  final List<EditorTab> _closedTabsHistory = [];

  EditorTab? get activeTab =>
      activeTabIndex >= 0 && activeTabIndex < tabs.length
          ? tabs[activeTabIndex]
          : null;

  void open(EditorDocument doc) {
    final existingIndex = tabs.indexWhere((t) => t.document.path == doc.path);
    if (existingIndex != -1) {
      activeTabIndex = existingIndex;
    } else {
      tabs.add(EditorTab(document: doc));
      activeTabIndex = tabs.length - 1;
    }
  }

  void close(int index) {
    if (index >= 0 && index < tabs.length) {
      final closed = tabs.removeAt(index);
      _closedTabsHistory.add(closed);
      if (activeTabIndex >= tabs.length) {
        activeTabIndex = tabs.length - 1;
      }
    }
  }

  void activate(int index) {
    if (index >= 0 && index < tabs.length) {
      activeTabIndex = index;
    }
  }

  void reopenLastClosed() {
    if (_closedTabsHistory.isNotEmpty) {
      final tab = _closedTabsHistory.removeLast();
      open(tab.document);
    }
  }

  void closeOthers(int index) {
    if (index >= 0 && index < tabs.length) {
      final keeper = tabs[index];
      tabs.clear();
      tabs.add(keeper);
      activeTabIndex = 0;
    }
  }

  void closeAll() {
    tabs.clear();
    activeTabIndex = -1;
  }
}
