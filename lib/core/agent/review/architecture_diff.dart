import 'review_models.dart';

class ArchitectureDiffCalculator {
  const ArchitectureDiffCalculator();

  // Computes deltas between workspace architectures and classes
  ArchitectureDiff calculateDiff({
    required List<String> oldClasses,
    required List<String> newClasses,
    required List<String> oldRoutes,
    required List<String> newRoutes,
  }) {
    final added = newClasses.where((c) => !oldClasses.contains(c)).toList();
    final removed = oldClasses.where((c) => !newClasses.contains(c)).toList();
    final addedR = newRoutes.where((r) => !oldRoutes.contains(r)).toList();

    return ArchitectureDiff(
      addedServices: added,
      removedServices: removed,
      addedRoutes: addedR,
      dependencyChanges: const [],
      breakingChanges: removed.isNotEmpty ? const ['Removal of active service classes.'] : const [],
    );
  }
}
