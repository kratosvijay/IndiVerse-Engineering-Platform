import 'pipeline_models.dart';

abstract interface class PipelineProvider {
  Future<PipelineRun> trigger(String commitHash);
  Future<PipelineRun> getRun(String runId);
  Future<void> cancel(String runId);
  Future<List<PipelineArtifact>> artifacts(String runId);
  Future<List<PipelineLog>> logs(String runId);
}

class LocalPipelineProvider implements PipelineProvider {
  final Map<String, PipelineRun> runs = {};

  @override
  Future<PipelineRun> trigger(String commitHash) async {
    final runId = 'run-${DateTime.now().millisecondsSinceEpoch}';
    final run = PipelineRun(
      id: runId,
      pipelineId: 'pipe-main',
      commitHash: commitHash,
      stages: const [
        PipelineStage(id: 'stage-1', name: 'Lint', status: PipelineStageStatus.passed, duration: Duration(seconds: 2)),
        PipelineStage(id: 'stage-2', name: 'Analyze', status: PipelineStageStatus.passed, duration: Duration(seconds: 3)),
        PipelineStage(id: 'stage-3', name: 'Test', status: PipelineStageStatus.passed, duration: Duration(seconds: 5)),
      ],
      createdAt: DateTime.now(),
      status: PipelineStageStatus.passed,
    );
    runs[runId] = run;
    return run;
  }

  @override
  Future<PipelineRun> getRun(String runId) async {
    final run = runs[runId];
    if (run != null) return run;

    return PipelineRun(
      id: runId,
      pipelineId: 'pipe-main',
      commitHash: 'sha-latest',
      stages: const [],
      createdAt: DateTime.now(),
      status: PipelineStageStatus.passed,
    );
  }

  @override
  Future<void> cancel(String runId) async {
    final run = runs[runId];
    if (run != null) {
      runs[runId] = PipelineRun(
        id: run.id,
        pipelineId: run.pipelineId,
        commitHash: run.commitHash,
        stages: run.stages.map((s) => PipelineStage(id: s.id, name: s.name, status: PipelineStageStatus.cancelled, duration: s.duration)).toList(),
        createdAt: run.createdAt,
        status: PipelineStageStatus.cancelled,
      );
    }
  }

  @override
  Future<List<PipelineArtifact>> artifacts(String runId) async {
    return const [
      PipelineArtifact(
        id: 'art-1',
        name: 'platform_report.json',
        sizeInBytes: 1024,
        downloadUrl: 'https://storage.googleapis.com/indiverse/artifacts/report.json',
      )
    ];
  }

  @override
  Future<List<PipelineLog>> logs(String runId) async {
    return [
      PipelineLog(line: 'Resolving dependencies...', timestamp: DateTime.now()),
      PipelineLog(line: 'Got dependencies!', timestamp: DateTime.now()),
      PipelineLog(line: 'Running tests...', timestamp: DateTime.now()),
      PipelineLog(line: 'All tests passed.', timestamp: DateTime.now()),
    ];
  }
}
