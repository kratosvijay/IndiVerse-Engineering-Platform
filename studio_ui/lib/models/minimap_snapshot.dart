import 'folding_region.dart';

class MinimapSnapshot {
  final List<String> lines;
  final int firstVisibleLine;
  final int lastVisibleLine;
  final List<FoldingRegion> foldedRegions;
  final List<dynamic> searchMatches;
  final List<dynamic> diagnostics;
  final List<dynamic> gitChanges;

  const MinimapSnapshot({
    required this.lines,
    required this.firstVisibleLine,
    required this.lastVisibleLine,
    this.foldedRegions = const [],
    this.searchMatches = const [],
    this.diagnostics = const [],
    this.gitChanges = const [],
  });
}
