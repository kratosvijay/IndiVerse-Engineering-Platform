import 'review_models.dart';

class ProjectConventionEngine {
  final List<ProjectConvention> learnedConventions = [];

  void learn(ProjectConvention convention) {
    learnedConventions.add(convention);
  }

  // Scans source patterns to classify styles (Riverpod, Bloc, etc.)
  List<ProjectConvention> scan(String sourceCode) {
    final list = <ProjectConvention>[];

    if (sourceCode.contains('class') && sourceCode.contains('Controller extends GetxController')) {
      final conv = const ProjectConvention(
        type: ConventionType.stateManagement,
        name: 'GetX Controller Structure',
        pattern: r'class .*Controller extends GetxController',
        examples: ['class ChatController extends GetxController'],
      );
      list.add(conv);
      learn(conv);
    }

    if (sourceCode.contains('class') && sourceCode.contains('extends StatelessWidget')) {
      final conv = const ProjectConvention(
        type: ConventionType.folderLayout,
        name: 'Stateless UI Component',
        pattern: r'class .* extends StatelessWidget',
        examples: ['class ChatPanel extends StatelessWidget'],
      );
      list.add(conv);
      learn(conv);
    }

    return list;
  }
}
