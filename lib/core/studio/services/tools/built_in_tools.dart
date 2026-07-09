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
import 'verification_tools.dart';
import 'project_tools.dart';
import 'git_tools.dart';
import 'pipeline_tools.dart';
import 'cluster_tools.dart';
import 'review_tools.dart';

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

  // Verifier Tools
  registry.register(VerifyAnalyzeTool());
  registry.register(VerifyCompileTool());
  registry.register(VerifyTestTool());
  registry.register(VerifyFormatTool());
  registry.register(VerifyFixTool());
  registry.register(VerifyReportTool());
  registry.register(VerifySummaryTool());

  // Project Tools
  registry.register(ProjectCreateTool());
  registry.register(ProjectOpenTool());
  registry.register(ProjectPlanTool());
  registry.register(ProjectExecuteTool());
  registry.register(ProjectPauseTool());
  registry.register(ProjectResumeTool());
  registry.register(ProjectStatusTool());
  registry.register(ProjectSummaryTool());
  registry.register(ProjectHistoryTool());
  registry.register(ProjectRollbackTool());
  registry.register(ProjectCheckpointTool());

  // Git Tools
  registry.register(GitCreateBranchTool());
  registry.register(GitCommitTool());
  registry.register(GitPlatformDiffTool());
  registry.register(GitLogTool());
  registry.register(GitCheckoutTool());
  registry.register(GitMergeTool());
  registry.register(GitRebaseTool());
  registry.register(GitRollbackTool());
  registry.register(GitPullRequestTool());
  registry.register(GitPlatformStatusTool());

  // Pipeline Tools
  registry.register(PipelineTriggerTool());
  registry.register(PipelineStatusTool());
  registry.register(PipelineLogsTool());
  registry.register(PipelineArtifactsTool());
  registry.register(PipelineCancelTool());
  registry.register(PipelineDeployTool());
  registry.register(PipelineRollbackTool());
  registry.register(PipelineSummaryTool());

  // Cluster Tools
  registry.register(ClusterStatusTool());
  registry.register(ClusterWorkersTool());
  registry.register(ClusterSubmitTool());
  registry.register(ClusterCancelTool());
  registry.register(ClusterLogsTool());
  registry.register(ClusterHealthTool());
  registry.register(ClusterMetricsTool());
  registry.register(ClusterRegisterTool());
  registry.register(ClusterUnregisterTool());
  registry.register(ClusterLeasesTool());
  registry.register(ClusterScaleTool());

  // Review Tools
  registry.register(ReviewArchitectureTool());
  registry.register(ReviewSecurityTool());
  registry.register(ReviewPerformanceTool());
  registry.register(ReviewMaintainabilityTool());
  registry.register(ReviewTestabilityTool());
  registry.register(ReviewStyleTool());
  registry.register(ReviewDocumentationTool());
  registry.register(ReviewSummaryTool());
  registry.register(ReviewExplainTool());
  registry.register(ReviewCompareTool());
  registry.register(DecisionExplainTool());
  registry.register(DecisionHistoryTool());
  registry.register(DecisionReplayTool());
  registry.register(DecisionCompareTool());
  registry.register(ApprovalPendingTool());
  registry.register(ApprovalRespondTool());
  registry.register(ApprovalHistoryTool());
  registry.register(ApprovalCancelTool());
  registry.register(ConventionsScanTool());
  registry.register(ConventionsLearnTool());
  registry.register(ConventionsExportTool());
  registry.register(ConventionsImportTool());
  registry.register(ArchitectureDiffTool());
  registry.register(ConfidenceReportTool());
  registry.register(ConfidenceTimelineTool());
}
