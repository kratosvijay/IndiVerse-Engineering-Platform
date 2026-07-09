import 'git_models.dart';

class PullRequestGenerator {
  const PullRequestGenerator();

  // Compiles structured PullRequestDraft to beautiful markdown descriptions
  String generateDescription(PullRequestDraft draft) {
    final buffer = StringBuffer();
    buffer.writeln('# PR Draft: ${draft.title}');
    buffer.writeln();
    buffer.writeln('## Summary');
    buffer.writeln(draft.summary);
    buffer.writeln();

    buffer.writeln('## Changes Made');
    for (final change in draft.changes) {
      buffer.writeln('- $change');
    }
    buffer.writeln();

    buffer.writeln('## Risks & Mitigation');
    for (final risk in draft.risks) {
      buffer.writeln('- $risk');
    }
    buffer.writeln();

    buffer.writeln('## Verification Results');
    for (final res in draft.verificationResults) {
      buffer.writeln('- $res');
    }
    buffer.writeln();

    buffer.writeln('## ADR & Architecture References');
    for (final ref in draft.adrReferences) {
      buffer.writeln('- $ref');
    }
    buffer.writeln();

    buffer.writeln('## Related Tasks');
    for (final task in draft.relatedTasks) {
      buffer.writeln('- $task');
    }

    return buffer.toString();
  }
}
