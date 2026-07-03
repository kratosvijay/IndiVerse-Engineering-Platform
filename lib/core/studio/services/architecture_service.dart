import '../../../../platform_sdk/platform_sdk.dart';

class ArchitectureService {
  final PlatformSDK sdk;

  ArchitectureService(this.sdk);

  Map<String, dynamic> getTopology() {
    return {
      "nodes": const [
        {"id": "runtime", "label": "AI Runtime", "layer": "Core"},
        {"id": "workspace", "label": "Workspace Engine", "layer": "Core"},
        {"id": "knowledge", "label": "Knowledge Engine", "layer": "Core"},
        {"id": "agent", "label": "Agent Engine", "layer": "Core"},
        {"id": "plugin", "label": "Plugin Platform", "layer": "Platform"},
        {"id": "studio", "label": "Studio Server", "layer": "Presentation"},
      ],
      "edges": const [
        {"from": "studio", "to": "runtime"},
        {"from": "studio", "to": "workspace"},
        {"from": "studio", "to": "knowledge"},
        {"from": "studio", "to": "agent"},
        {"from": "agent", "to": "knowledge"},
        {"from": "knowledge", "to": "workspace"},
        {"from": "plugin", "to": "runtime"},
      ]
    };
  }

  Map<String, dynamic> getNodeDetails(String nodeId) {
    switch (nodeId) {
      case "runtime":
        return {
          "id": "runtime",
          "name": "AI Runtime",
          "version": "1.0.0",
          "health": "Healthy",
          "status": "active",
          "latency": "2ms",
          "contracts": ["IRuntime", "IProviderAdapter"],
          "dependencies": ["Plugin Platform"],
          "consumers": ["Studio Server"],
          "events": ["RuntimeStarted", "RuntimeCompleted"],
        };
      case "workspace":
        return {
          "id": "workspace",
          "name": "Workspace Engine",
          "version": "1.0.0",
          "health": "Healthy",
          "status": "ready",
          "latency": "4ms",
          "contracts": ["IWorkspaceScanner", "IDetectorRegistry"],
          "dependencies": <String>[],
          "consumers": ["Knowledge Engine", "Studio Server"],
          "events": ["WorkspaceOpened", "WorkspaceReady", "WorkspaceClosed"],
        };
      case "knowledge":
        return {
          "id": "knowledge",
          "name": "Knowledge Engine",
          "version": "1.0.0",
          "health": "Healthy",
          "status": "ready",
          "latency": "3ms",
          "contracts": ["ISearchEngine", "IVectorStore", "IEmbeddingProvider"],
          "dependencies": ["Workspace Engine"],
          "consumers": ["Agent Engine", "Studio Server"],
          "events": ["ReindexTriggered", "ReindexCompleted"],
        };
      case "agent":
        return {
          "id": "agent",
          "name": "Agent Engine",
          "version": "1.0.0",
          "health": "Healthy",
          "status": "idle",
          "latency": "8ms",
          "contracts": ["IAgentExecutor", "IAgentRegistry", "ITaskScheduler"],
          "dependencies": ["Knowledge Engine"],
          "consumers": ["Studio Server"],
          "events": ["TaskStarted", "TaskCompleted"],
        };
    }
    return {
      "id": nodeId,
      "name": "Platform Component",
      "version": "1.0.0",
      "health": "Healthy",
      "status": "ready",
      "latency": "1ms",
      "contracts": <String>[],
      "dependencies": <String>[],
      "consumers": <String>[],
      "events": <String>[],
    };
  }
}
