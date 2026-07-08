abstract final class EditorCommands {
  static const find = "editor.find";
  static const replace = "editor.replace";
  static const gotoLine = "editor.gotoLine";
  static const gotoDefinition = "editor.gotoDefinition";
  static const undo = "editor.undo";
  static const redo = "editor.redo";
  static const nextTab = "editor.nextTab";
  static const previousTab = "editor.previousTab";
  static const closeTab = "editor.close";
  static const commentLine = "editor.commentLine";
  static const commentBlock = "editor.commentBlock";
  static const duplicateLine = "editor.duplicateLine";
  static const deleteLine = "editor.deleteLine";
  static const moveLineUp = "editor.moveLineUp";
  static const moveLineDown = "editor.moveLineDown";
  static const selectAll = "editor.selectAll";
  static const indent = "editor.indent";
  static const outdent = "editor.outdent";
  static const autoFormat = "editor.autoFormat";
  static const fold = "editor.fold";
  static const unfold = "editor.unfold";
  static const foldAll = "editor.foldAll";
  static const unfoldAll = "editor.unfoldAll";
  static const foldRecursively = "editor.foldRecursively";
  static const unfoldRecursively = "editor.unfoldRecursively";
  static const foldLevel = "editor.foldLevel";
  static const toggleFold = "editor.toggleFold";
  static const gotoPreviousLocation = "editor.gotoPreviousLocation";
  static const gotoNextLocation = "editor.gotoNextLocation";
  static const toggleMinimap = "editor.toggleMinimap";
  static const codeAction = "editor.codeAction";
  static const quickFix = "editor.quickFix";
  static const organizeImports = "editor.organizeImports";
  static const fixAll = "editor.fixAll";
  static const inlineAI = "editor.inlineAI";
}

abstract final class WorkbenchCommands {
  static const fileOpen = "workbench.file.open";
  static const fileQuickOpen = "workbench.file.quickOpen";
  static const fileSave = "workbench.file.save";
  static const fileNew = "workbench.file.new";
  static const fileRename = "workbench.file.rename";
  static const fileDelete = "workbench.file.delete";
  static const showCommands = "workbench.action.showCommands";
  static const navigateBack = "workbench.action.navigateBack";
  static const navigateForward = "workbench.action.navigateForward";
}

abstract final class GitCommands {
  static const commit = "git.commit";
  static const stage = "git.stage";
}

abstract final class ProblemsCommands {
  static const nextError = "problems.nextError";
  static const nextWarning = "problems.nextWarning";
  static const previous = "problems.previous";
  static const togglePanel = "problems.togglePanel";
}
