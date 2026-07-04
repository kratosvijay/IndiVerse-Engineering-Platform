import 'package:flutter/material.dart';
import '../../../core/state/studio_state.dart';
import '../../../models/ids.dart';

class ReferencesPanel extends StatelessWidget {
  final StudioState state;
  final List<Map<String, dynamic>> references;
  final String symbolName;
  final VoidCallback onClose;

  const ReferencesPanel({
    super.key,
    required this.state,
    required this.references,
    required this.symbolName,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: const BoxDecoration(
        color: Color(0xFF131024),
        border: Border(top: BorderSide(color: Color(0xFF2C284D))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'References for "$symbolName" (${references.length} found)',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Color(0xFFA78BFA),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.close,
                    size: 14,
                    color: Colors.white54,
                  ),
                  onPressed: onClose,
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFF2C284D)),
          Expanded(
            child: references.isEmpty
                ? const Center(
                    child: Text(
                      'No references found.',
                      style: TextStyle(color: Colors.white24, fontSize: 12),
                    ),
                  )
                : ListView.builder(
                    itemCount: references.length,
                    itemBuilder: (context, index) {
                      final ref = references[index];
                      final path = ref['path'] ?? '';
                      final line = ref['line'] ?? 1;
                      final snippet = ref['snippet'] ?? '';

                      return ListTile(
                        dense: true,
                        title: Text(
                          '$path : Line $line',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          snippet,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: Colors.white30,
                          ),
                        ),
                        onTap: () {
                          state.workbench.navigation.jumpToLine(
                            DocumentId(path),
                            line,
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
