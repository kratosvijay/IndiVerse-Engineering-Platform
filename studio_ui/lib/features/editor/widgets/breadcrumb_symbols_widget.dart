import 'package:flutter/material.dart';
import '../../../core/state/studio_state.dart';
import '../../../models/ids.dart';

class BreadcrumbSymbolsWidget extends StatelessWidget {
  final StudioState state;

  const BreadcrumbSymbolsWidget({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final activeTab = state.editor.activeTab;
    if (activeTab == null) return const SizedBox();

    final doc = activeTab.document;
    final docId = DocumentId(doc.path);
    final outline = state.documentService.getOutline(docId) ?? [];

    String? activeClass;
    String? activeMember;

    for (final sym in outline) {
      final symLine = sym['line'] as int? ?? 1;
      if (sym['kind'] == 'Class') {
        if (doc.cursorLine >= symLine) {
          activeClass = sym['name'];
        }
        final children = sym['children'] as List? ?? [];
        for (final child in children) {
          final childLine = child['line'] as int? ?? 1;
          if (doc.cursorLine >= childLine) {
            activeMember = child['name'];
          }
        }
      }
    }

    final pathSegments = doc.path
        .split('/')
        .where((s) => s.isNotEmpty)
        .toList();

    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: const Color(0xFF110E22),
      child: Row(
        children: [
          ...pathSegments.map((segment) {
            return Row(
              children: [
                Text(
                  segment,
                  style: const TextStyle(fontSize: 11, color: Colors.white30),
                ),
                const Icon(
                  Icons.chevron_right,
                  size: 12,
                  color: Colors.white10,
                ),
              ],
            );
          }),
          if (activeClass != null) ...[
            const Icon(Icons.category, size: 12, color: Color(0xFF3B82F6)),
            const SizedBox(width: 4),
            Text(
              activeClass,
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
            const Icon(Icons.chevron_right, size: 12, color: Colors.white10),
          ],
          if (activeMember != null) ...[
            const Icon(Icons.functions, size: 12, color: Color(0xFF10B981)),
            const SizedBox(width: 4),
            Text(
              activeMember,
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ],
      ),
    );
  }
}
