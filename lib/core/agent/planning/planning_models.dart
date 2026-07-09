import '../workflow/task_graph.dart';
import '../workflow/task_step.dart';
import '../../workspace/graph/workspace_snapshot.dart';
import '../runtime/multi_agent/agent_role.dart';

enum GoalType {
  feature,
  bugfix,
  refactor,
  migration,
  optimization,
  documentation,
  testing,
  research
}

class GoalAnalysis {
  final String goal;
  final GoalType type;
  final List<String> constraints;
  final List<String> acceptanceCriteria;
  final String priority;

  const GoalAnalysis({
    required this.goal,
    required this.type,
    required this.constraints,
    required this.acceptanceCriteria,
    required this.priority,
  });

  Map<String, dynamic> toJson() => {
        'goal': goal,
        'type': type.name,
        'constraints': constraints,
        'acceptanceCriteria': acceptanceCriteria,
        'priority': priority,
      };
}

class Requirement {
  final List<String> functional;
  final List<String> nonFunctional;
  final List<String> constraints;
  final List<String> assumptions;

  const Requirement({
    required this.functional,
    required this.nonFunctional,
    required this.constraints,
    required this.assumptions,
  });

  Map<String, dynamic> toJson() => {
        'functional': functional,
        'nonFunctional': nonFunctional,
        'constraints': constraints,
        'assumptions': assumptions,
      };
}

class ArchitectureImpact {
  final List<String> files;
  final List<String> services;
  final List<String> routes;
  final List<String> providers;
  final List<String> tests;
  final List<String> apis;
  final List<String> database;

  const ArchitectureImpact({
    required this.files,
    required this.services,
    required this.routes,
    required this.providers,
    required this.tests,
    required this.apis,
    required this.database,
  });

  Map<String, dynamic> toJson() => {
        'files': files,
        'services': services,
        'routes': routes,
        'providers': providers,
        'tests': tests,
        'apis': apis,
        'database': database,
      };
}

class TaskNode {
  final String id;
  final String title;
  final String description;
  final String priority;
  final int estimatedTokens;
  final int estimatedLOC;
  final List<String> dependencies;
  final bool parallelizable;
  final AgentCapability agentCapability;

  const TaskNode({
    required this.id,
    required this.title,
    required this.description,
    required this.priority,
    required this.estimatedTokens,
    required this.estimatedLOC,
    required this.dependencies,
    required this.parallelizable,
    required this.agentCapability,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'priority': priority,
        'estimatedTokens': estimatedTokens,
        'estimatedLOC': estimatedLOC,
        'dependencies': dependencies,
        'parallelizable': parallelizable,
        'agentCapability': agentCapability.name,
      };

  TaskStep toTaskStep() => TaskStep(
        id: id,
        title: title,
        dependencies: dependencies,
      );
}

class RiskReport {
  final double complexityScore;
  final double securityRisk;
  final double architectureRisk;
  final double performanceRisk;
  final double migrationRisk;
  final double regressionRisk;

  const RiskReport({
    required this.complexityScore,
    required this.securityRisk,
    required this.architectureRisk,
    required this.performanceRisk,
    required this.migrationRisk,
    required this.regressionRisk,
  });

  Map<String, dynamic> toJson() => {
        'complexityScore': complexityScore,
        'securityRisk': securityRisk,
        'architectureRisk': architectureRisk,
        'performanceRisk': performanceRisk,
        'migrationRisk': migrationRisk,
        'regressionRisk': regressionRisk,
      };
}

class ExecutionEstimate {
  final int estimatedLOC;
  final Duration estimatedTime;
  final List<String> rollbackScope;

  const ExecutionEstimate({
    required this.estimatedLOC,
    required this.estimatedTime,
    required this.rollbackScope,
  });

  Map<String, dynamic> toJson() => {
        'estimatedLOC': estimatedLOC,
        'estimatedTimeMs': estimatedTime.inMilliseconds,
        'rollbackScope': rollbackScope,
      };
}

class PlanValidation {
  final bool valid;
  final List<String> warnings;
  final List<String> recommendations;

  const PlanValidation({
    required this.valid,
    required this.warnings,
    required this.recommendations,
  });

  Map<String, dynamic> toJson() => {
        'valid': valid,
        'warnings': warnings,
        'recommendations': recommendations,
      };
}

class ExecutionPlan {
  final String planId;
  final GoalAnalysis goalAnalysis;
  final Requirement requirement;
  final ArchitectureImpact impact;
  final TaskGraph graph;
  final RiskReport risk;
  final ExecutionEstimate estimate;
  final PlanValidation validation;

  const ExecutionPlan({
    required this.planId,
    required this.goalAnalysis,
    required this.requirement,
    required this.impact,
    required this.graph,
    required this.risk,
    required this.estimate,
    required this.validation,
  });

  Map<String, dynamic> toJson() => {
        'planId': planId,
        'goalAnalysis': goalAnalysis.toJson(),
        'requirement': requirement.toJson(),
        'impact': impact.toJson(),
        'graph': graph.toJson(),
        'risk': risk.toJson(),
        'estimate': estimate.toJson(),
        'validation': validation.toJson(),
      };
}
