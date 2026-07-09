import 'planning_models.dart';

class RequirementExtractor {
  // Extracts requirements lists based on GoalAnalysis parameters
  Requirement extract(GoalAnalysis goalAnalysis) {
    final functional = <String>[];
    final nonFunctional = <String>[];
    final assumptions = <String>[
      'Standard Flutter/Dart workspace layout is active.',
      'Active codebase is under git version control.',
    ];

    switch (goalAnalysis.type) {
      case GoalType.feature:
        functional.add('Implement modules parsing core inputs.');
        nonFunctional.add('Clean Architecture boundaries must not be violated.');
        break;
      case GoalType.bugfix:
        functional.add('Resolve diagnostics error stack trace.');
        nonFunctional.add('Do not introduce regressions in clean modules.');
        break;
      case GoalType.refactor:
        functional.add('Refactor modules to reuse shared utils.');
        nonFunctional.add('Execution performance must not degrade.');
        break;
      default:
        functional.add('Process task goal action.');
        nonFunctional.add('Standard compilation compliance.');
    }

    return Requirement(
      functional: functional,
      nonFunctional: nonFunctional,
      constraints: goalAnalysis.constraints,
      assumptions: assumptions,
    );
  }
}
