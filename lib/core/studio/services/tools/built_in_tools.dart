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
import 'workspace_intelligence_tools.dart';
import 'knowledge_tools.dart';
import 'planner_tools.dart';
import 'generation_tools.dart';

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

  // Workspace Intelligence Tools
  registry.register(FindSymbolTool());
  registry.register(FindReferencesTool());
  registry.register(FindImplementationsTool());
  registry.register(FindCallersTool());
  registry.register(FindCalleesTool());
  registry.register(FindDefinitionTool());
  registry.register(FindFileTool());

  // Knowledge Tools
  registry.register(KnowledgeSearchTool());
  registry.register(KnowledgeInsertTool());
  registry.register(KnowledgeUpdateTool());
  registry.register(KnowledgeDeleteTool());
  registry.register(KnowledgeHistoryTool());
  registry.register(KnowledgeSimilarTool());
  registry.register(KnowledgeLearnTool());
  registry.register(KnowledgeRelatedTool());
  registry.register(KnowledgeSummarizeTool());
  registry.register(KnowledgeReindexTool());

  // Planner Tools
  registry.register(PlannerGeneratePlanTool());
  registry.register(PlannerValidatePlanTool());
  registry.register(PlannerEstimateTool());
  registry.register(PlannerRiskTool());
  registry.register(PlannerPreviewTool());
  registry.register(PlannerDependenciesTool());
  registry.register(PlannerImpactTool());
  registry.register(PlannerAcceptanceTool());
  registry.register(PlannerReviewTool());

  // Generator Tools
  registry.register(GeneratorGenerateTool());
  registry.register(GeneratorPatchTool());
  registry.register(GeneratorValidateTool());
  registry.register(GeneratorReviewTool());
  registry.register(GeneratorRollbackTool());
  registry.register(GeneratorResumeTool());
  registry.register(GeneratorPreviewTool());
  registry.register(GeneratorDiffTool());
  registry.register(GeneratorFilesTool());
  registry.register(GeneratorCheckpointTool());
}
