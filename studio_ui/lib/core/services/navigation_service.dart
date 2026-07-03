import '../state/studio_state.dart';

class NavigationService {
  final StudioState studioState;

  NavigationService(this.studioState);

  Future<void> openFile(String path, {int? line}) async {
    await studioState.openFile(path, line: line);
  }

  void revealInExplorer(String path) {
    studioState.revealInExplorer(path);
  }

  void openArchitectureNode(String id) {
    studioState.selectArchitectureNode(id);
  }

  void showInspector(String id, String type) {
    studioState.selectInspector(id, type);
  }

  void focusSearch() {
    studioState.setTab("Search");
  }

  void focusExplorer() {
    studioState.setTab("Workspace");
  }
}
