import 'package:flutter/material.dart';
import '../../../core/state/studio_state.dart';

class InspectorWidget extends StatelessWidget {
  final StudioState state;

  const InspectorWidget({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final sel = state.currentSelection;

    return Container(
      width: 280,
      decoration: const BoxDecoration(
        color: Color(0xFF110E22),
        border: Border(left: BorderSide(color: Color(0xFF2C284D))),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'INSPECTOR',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (sel == null)
                const Text(
                  'No active execution segment selected.',
                  style: TextStyle(color: Colors.white30, fontSize: 12),
                )
              else ...[
                Text(
                  sel.id,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFA78BFA)),
                ),
                const SizedBox(height: 4),
                Text(
                  'Type: ${sel.type.name.toUpperCase()}',
                  style: const TextStyle(fontSize: 10, color: Colors.white30),
                ),
                const Divider(color: Color(0xFF2C284D), height: 24),
                ..._buildDetails(sel.metadata),
              ]
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildDetails(Map<String, dynamic> metadata) {
    final widgets = <Widget>[];

    // Details Map entries
    metadata.forEach((key, val) {
      if (val is Map) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Text(
            key.toUpperCase(),
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white54),
          ),
        ));
        val.forEach((subKey, subVal) {
          widgets.add(_buildInspectorRow(subKey.toString(), subVal.toString()));
        });
      } else if (val is List) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Text(
            key.toUpperCase(),
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white54),
          ),
        ));
        for (final item in val) {
          widgets.add(Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(item.toString(), style: const TextStyle(fontSize: 11, color: Colors.white30)),
          ));
        }
      } else {
        widgets.add(_buildInspectorRow(key, val.toString()));
      }
    });

    return widgets;
  }

  Widget _buildInspectorRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white30, fontSize: 11)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11, color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
}
