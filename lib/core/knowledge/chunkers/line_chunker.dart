import '../contracts/chunker.dart';
import '../chunk.dart';
import '../document.dart';

class LineChunker implements Chunker {
  final int maxLines;

  const LineChunker({this.maxLines = 50});

  @override
  String get type => "line";

  @override
  List<Chunk> chunk(Document document) {
    final chunks = <Chunk>[];
    final lines = document.content.split('\n');
    for (int i = 0; i < lines.length; i += maxLines) {
      final end = (i + maxLines < lines.length) ? i + maxLines : lines.length;
      final chunkLines = lines.sublist(i, end);
      final content = chunkLines.join('\n');
      final checksum = content.hashCode.toString();
      final id = "${document.id}-line-$i";
      chunks.add(Chunk(
        id: id,
        documentId: document.id,
        startLine: i + 1,
        endLine: end,
        content: content,
        checksum: checksum,
        language: document.language,
        symbolIds: const [],
        tokenCount: content.split(RegExp(r'\s+')).length,
        metadata: const {},
      ));
    }
    return chunks;
  }
}
