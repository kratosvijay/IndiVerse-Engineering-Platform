import 'package:flutter/material.dart';
import '../../../core/state/studio_state.dart';
import 'explorer_widget.dart';
import '../../outline/widgets/outline_widget.dart';

class CollapsibleAccordionSidebar extends StatefulWidget {
  final StudioState state;

  const CollapsibleAccordionSidebar({super.key, required this.state});

  @override
  State<CollapsibleAccordionSidebar> createState() => _CollapsibleAccordionSidebarState();
}

class _CollapsibleAccordionSidebarState extends State<CollapsibleAccordionSidebar> {
  bool _filesExpanded = true;
  bool _outlineExpanded = true;
  bool _workspaceExpanded = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      decoration: const BoxDecoration(
        color: Color(0xFF0F0C1B),
        border: Border(right: BorderSide(color: Color(0xFF2C284D))),
      ),
      child: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                _buildAccordionHeader('FILES', _filesExpanded, () {
                  setState(() => _filesExpanded = !_filesExpanded);
                }),
                if (_filesExpanded)
                  Container(
                    constraints: const BoxConstraints(maxHeight: 400),
                    child: ExplorerWidget(state: widget.state),
                  ),
                const Divider(height: 1, color: Color(0xFF2C284D)),
                _buildAccordionHeader('OUTLINE', _outlineExpanded, () {
                  setState(() => _outlineExpanded = !_outlineExpanded);
                }),
                if (_outlineExpanded)
                  Container(
                    constraints: const BoxConstraints(maxHeight: 300),
                    child: OutlineWidget(state: widget.state),
                  ),
                const Divider(height: 1, color: Color(0xFF2C284D)),
                _buildAccordionHeader('WORKSPACE INDEX', _workspaceExpanded, () {
                  setState(() => _workspaceExpanded = !_workspaceExpanded);
                }),
                if (_workspaceExpanded)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildWorkspaceIndexSection(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccordionHeader(String title, bool expanded, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        color: const Color(0xFF131024),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white54, letterSpacing: 1.1),
            ),
            Icon(
              expanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
              size: 14,
              color: Colors.white30,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkspaceIndexSection() {
    return FutureBuilder(
      future: widget.state.workbench.workspace.getIndexStatus(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: Text('Loading stats...', style: TextStyle(fontSize: 11, color: Colors.white24)));
        }
        final res = snapshot.data!;
        if (!res.success || res.data == null) {
          return const Center(child: Text('No stats available.', style: TextStyle(fontSize: 11, color: Colors.white24)));
        }
        final stats = res.data!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatRow('Files Indexed', '${stats["indexed"] ?? 0}'),
            _buildStatRow('Total Symbols', '${stats["symbols"] ?? 0}'),
            _buildStatRow('Classes', '${stats["classes"] ?? 0}'),
            _buildStatRow('Methods / Functions', '${stats["functions"] ?? 0}'),
            _buildStatRow('Enums', '${stats["enums"] ?? 0}'),
            _buildStatRow('Indexer State', '${stats["indexerState"] ?? "Ready"}'),
          ],
        );
      },
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.white30)),
          Text(value, style: const TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
