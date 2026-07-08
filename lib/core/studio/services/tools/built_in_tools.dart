import '../tool_registry.dart';
import 'workspace_search_tool.dart';
import 'workspace_read_tool.dart';
import 'workspace_open_file_tool.dart';
import 'workspace_write_tool.dart';
import 'git_status_tool.dart';
import 'git_diff_tool.dart';
import 'editor_replace_tool.dart';
import 'diagnostics_list_tool.dart';
import 'editor_query_tools.dart';

void registerBuiltInTools(ToolRegistry registry) {
  registry.register(WorkspaceSearchTool());
  registry.register(WorkspaceReadTool());
  registry.register(WorkspaceOpenFileTool());
  registry.register(WorkspaceWriteTool());
  registry.register(GitStatusTool());
  registry.register(GitDiffTool());
  registry.register(EditorReplaceTool());
  registry.register(DiagnosticsListTool());
  registry.register(EditorCurrentFileTool());
  registry.register(EditorSelectionTool());
}
