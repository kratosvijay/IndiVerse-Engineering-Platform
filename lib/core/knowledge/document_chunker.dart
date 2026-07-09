import 'knowledge_item.dart';

class DocumentChunker {
  // Splits a KnowledgeDocument content into overlapping chunks
  List<KnowledgeChunk> chunk(
    KnowledgeDocument doc, {
    int chunkSize = 250, // maximum character size
    int chunkOverlap = 50,
  }) {
    final chunks = <KnowledgeChunk>[];
    final text = doc.content;
    if (text.isEmpty) {
      return chunks;
    }

    var start = 0;
    var index = 0;

    while (start < text.length) {
      var end = start + chunkSize;
      if (end >= text.length) {
        end = text.length;
      } else {
        // Try to break at whitespace to avoid truncating words
        final lastSpace = text.substring(start, end).lastIndexOf(' ');
        if (lastSpace > 0 && lastSpace > (chunkSize * 0.7)) {
          end = start + lastSpace;
        }
      }

      final chunkText = text.substring(start, end);
      // Heuristic token estimation: characters count divided by 4 plus spaces
      final words = chunkText.split(RegExp(r'\s+')).length;
      final tokens = (words * 1.3).round() + 1;

      chunks.add(KnowledgeChunk(
        documentId: doc.id,
        chunkId: '${doc.id}_chunk_$index',
        text: chunkText,
        startOffset: start,
        endOffset: end,
        tokenEstimate: tokens,
      ));

      index++;
      start = end - chunkOverlap;
      if (start >= text.length || end == text.length) {
        break;
      }
      if (start <= 0) {
        start = end; // prevent infinite loop in degenerate overlaps
      }
    }

    return chunks;
  }
}
