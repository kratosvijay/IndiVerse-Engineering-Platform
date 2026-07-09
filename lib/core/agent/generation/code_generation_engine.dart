import 'generation_models.dart';
import 'file_generator.dart';
import 'generation_validator.dart';
import 'review_engine.dart';
import '../planning/planning_models.dart';

class CodeGenerationEngine {
  final FileGenerator generator = const FileGenerator();
  final ValidationPipeline validationPipeline = ValidationPipeline();
  final ReviewEngine reviewEngine = const ReviewEngine();

  // Generates patches for a specific task node in the execution plan
  Future<List<GeneratedPatch>> generateTaskPatches({
    required TaskNode task,
    required ExecutionPlan plan,
    required Map<String, String> checkpoints,
  }) async {
    final patches = <GeneratedPatch>[];

    // Simulates multi-agent code generation based on target capability
    final generatedCode =
        '// Generated logic for: ${task.title}\n// Capability: ${task.agentCapability.name}\nvoid run() {}';

    final patch = await generator.generatePatch(
      filePath: 'lib/core/agent/planning/${task.id.replaceAll(".", "_")}.dart',
      originalText: '',
      generatedText: generatedCode,
      createsFile: true,
    );
    patches.add(patch);

    return patches;
  }
}

class GenerationEngineRegistry {
  static CodeGenerationEngine? _active;
  static CodeGenerationEngine? get active => _active;
  static set active(CodeGenerationEngine? engine) => _active = engine;

  static final Map<String, CodeGenerationEngine> _registry = {};
  static void register(String workspaceId, CodeGenerationEngine engine) {
    _registry[workspaceId] = engine;
    _active ??= engine;
  }

  static CodeGenerationEngine? get(String workspaceId) =>
      _registry[workspaceId];
  static void clear() {
    _registry.clear();
    _active = null;
  }
}
