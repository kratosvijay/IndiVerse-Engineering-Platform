import '../chunk.dart';
import '../document.dart';

abstract class Chunker {
  String get type;
  List<Chunk> chunk(Document document);
}
