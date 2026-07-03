abstract final class EditorCommands {
  static const find = "editor.find";
  static const gotoLine = "editor.gotoLine";
  static const gotoDefinition = "editor.gotoDefinition";
  static const nextTab = "editor.nextTab";
  static const previousTab = "editor.previousTab";
  static const closeTab = "editor.close";
}

abstract final class WorkbenchCommands {
  static const fileOpen = "workbench.file.open";
  static const fileQuickOpen = "workbench.file.quickOpen";
  static const showCommands = "workbench.action.showCommands";
  static const navigateBack = "workbench.action.navigateBack";
  static const navigateForward = "workbench.action.navigateForward";
}

abstract final class GitCommands {
  static const commit = "git.commit";
  static const stage = "git.stage";
}
