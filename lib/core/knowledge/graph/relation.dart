import 'relation_type.dart';

class Relation {
  final String from;
  final String to;
  final RelationType type;

  const Relation({required this.from, required this.to, required this.type});
}
