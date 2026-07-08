import '../../models/inline_ai_models.dart';

class DiffEngine {
  static List<DiffBlock> computeDiff(
    List<String> originalLines,
    List<String> newLines,
  ) {
    final int m = originalLines.length;
    final int n = newLines.length;

    // DP table for LCS
    final List<List<int>> dp = List.generate(
      m + 1,
      (_) => List.filled(n + 1, 0),
    );

    for (int i = 1; i <= m; i++) {
      for (int j = 1; j <= n; j++) {
        if (originalLines[i - 1] == newLines[j - 1]) {
          dp[i][j] = dp[i - 1][j - 1] + 1;
        } else {
          dp[i][j] = dp[i - 1][j] > dp[i][j - 1] ? dp[i - 1][j] : dp[i][j - 1];
        }
      }
    }

    final List<DiffBlock> diff = [];
    int i = m;
    int j = n;

    while (i > 0 || j > 0) {
      if (i > 0 && j > 0 && originalLines[i - 1] == newLines[j - 1]) {
        diff.insert(
          0,
          DiffBlock(
            type: DiffType.unchanged,
            oldLine: i,
            newLine: j,
            text: originalLines[i - 1],
          ),
        );
        i--;
        j--;
      } else if (j > 0 && (i == 0 || dp[i][j - 1] >= dp[i - 1][j])) {
        diff.insert(
          0,
          DiffBlock(
            type: DiffType.inserted,
            oldLine: 0,
            newLine: j,
            text: newLines[j - 1],
          ),
        );
        j--;
      } else {
        diff.insert(
          0,
          DiffBlock(
            type: DiffType.deleted,
            oldLine: i,
            newLine: 0,
            text: originalLines[i - 1],
          ),
        );
        i--;
      }
    }

    return diff;
  }
}
