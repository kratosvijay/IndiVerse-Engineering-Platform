import '../../models/language_intelligence_models.dart';

class CompletionRanker {
  static List<CompletionItem> rank(List<CompletionItem> items, String prefix) {
    if (prefix.isEmpty) {
      final results = List<CompletionItem>.from(items);
      results.sort((a, b) {
        if (a.preselect && !b.preselect) return -1;
        if (!a.preselect && b.preselect) return 1;
        final sortA = a.sortText ?? a.label;
        final sortB = b.sortText ?? b.label;
        return sortA.compareTo(sortB);
      });
      return results;
    }

    final prefixLower = prefix.toLowerCase();
    final scored = <_ScoredItem>[];

    for (final item in items) {
      final label = item.label;
      final labelLower = label.toLowerCase();
      double score = 0.0;

      if (labelLower.startsWith(prefixLower)) {
        score += 100.0;
        if (label.startsWith(prefix)) {
          score += 20.0;
        }
        score += (1.0 / label.length) * 10.0;
      } else if (_isCamelCaseMatch(label, prefix)) {
        score += 70.0;
      } else if (labelLower.contains(prefixLower)) {
        score += 40.0;
        final idx = labelLower.indexOf(prefixLower);
        score += (1.0 / (idx + 1)) * 10.0;
      } else {
        continue;
      }

      score += item.score;
      scored.add(_ScoredItem(item: item, score: score));
    }

    scored.sort((a, b) {
      if (a.score != b.score) {
        return b.score.compareTo(a.score);
      }
      if (a.item.preselect && !b.item.preselect) return -1;
      if (!a.item.preselect && b.item.preselect) return 1;
      return a.item.label.compareTo(b.item.label);
    });

    return scored.map((s) {
      return CompletionItem(
        label: s.item.label,
        kind: s.item.kind,
        detail: s.item.detail,
        documentation: s.item.documentation,
        insertText: s.item.insertText,
        insertTextFormat: s.item.insertTextFormat,
        textEdit: s.item.textEdit,
        additionalTextEdits: s.item.additionalTextEdits,
        sortText: s.item.sortText,
        filterText: s.item.filterText,
        deprecated: s.item.deprecated,
        preselect: s.item.preselect,
        score: s.score,
      );
    }).toList();
  }

  static bool _isCamelCaseMatch(String label, String prefix) {
    if (prefix.isEmpty) return false;
    int labelIdx = 0;
    int prefixIdx = 0;

    while (prefixIdx < prefix.length) {
      final pChar = prefix[prefixIdx];
      bool matched = false;

      while (labelIdx < label.length) {
        final lChar = label[labelIdx];
        if (lChar.toLowerCase() == pChar.toLowerCase()) {
          if (prefixIdx == 0 || _isWordBoundary(label, labelIdx)) {
            matched = true;
            labelIdx++;
            break;
          }
        }
        labelIdx++;
      }

      if (!matched) return false;
      prefixIdx++;
    }

    return true;
  }

  static bool _isWordBoundary(String s, int index) {
    if (index == 0) return true;
    final prev = s[index - 1];
    final curr = s[index];
    if (prev == prev.toLowerCase() &&
        curr == curr.toUpperCase() &&
        curr != curr.toLowerCase()) {
      return true;
    }
    if (prev == '_' || prev == '-' || prev == ' ') return true;
    return false;
  }
}

class _ScoredItem {
  final CompletionItem item;
  final double score;

  _ScoredItem({required this.item, required this.score});
}
