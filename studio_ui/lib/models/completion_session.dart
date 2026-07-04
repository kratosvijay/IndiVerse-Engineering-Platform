import 'editor_document.dart';
import 'language_intelligence_models.dart';

class CompletionSession {
  final String id;
  final Position anchor;
  final int documentRevision;
  final CompletionTrigger trigger;
  final List<CompletionItem> items;
  int selectedIndex;
  bool isActive;

  CompletionSession({
    required this.id,
    required this.anchor,
    required this.documentRevision,
    required this.trigger,
    required this.items,
    this.selectedIndex = 0,
    this.isActive = true,
  });
}
