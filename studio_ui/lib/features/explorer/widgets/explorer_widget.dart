import 'package:flutter/material.dart';
import '../../../core/state/studio_state.dart';
import '../../../models/tree_node.dart';

class ExplorerWidget extends StatefulWidget {
  final StudioState state;

  const ExplorerWidget({super.key, required this.state});

  @override
  State<ExplorerWidget> createState() => _ExplorerWidgetState();
}

class _ExplorerWidgetState extends State<ExplorerWidget> {
  Map<String, dynamic> _indexStatus = {};

  @override
  void initState() {
    super.initState();
    _loadIndexStatus();
  }

  @override
  void didUpdateWidget(covariant ExplorerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadIndexStatus();
  }

  void _loadIndexStatus() async {
    final res = await widget.state.workbench.workspace.getIndexStatus();
    if (res.success && res.data != null) {
      if (mounted) {
        setState(() {
          _indexStatus = res.data!;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'PROJECT EXPLORER',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 14, color: Colors.white30),
                  onPressed: () {
                    widget.state.reloadWorkspace();
                    _loadIndexStatus();
                  },
                  tooltip: 'Reload Explorer',
                )
              ],
            ),
          ),
          Expanded(
            child: widget.state.rootNodes.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: widget.state.rootNodes.length,
                    itemBuilder: (context, index) {
                      return _buildNode(widget.state.rootNodes[index], 0);
                    },
                  ),
          ),
          const Divider(color: Color(0xFF2C284D), height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'WORKSPACE INDEX STATUS',
                  style: TextStyle(fontSize: 10, color: Colors.white30, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildStatusRow('Files Indexed', '${_indexStatus["indexed"] ?? 0}'),
                _buildStatusRow('Total Symbols', '${_indexStatus["symbols"] ?? 0}'),
                _buildStatusRow('Classes', '${_indexStatus["classes"] ?? 0}'),
                _buildStatusRow('Methods / Functions', '${_indexStatus["functions"] ?? 0}'),
                _buildStatusRow('Indexer State', '${_indexStatus["indexerState"] ?? "Ready"}'),
              ],
            ),
          ),
        ],
      );
  }

  Widget _buildStatusRow(String label, String value) {
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

  Widget _buildNode(TreeNode node, int depth) {
    final isSel = widget.state.explorer.selectedPath == node.path;
    final isExp = widget.state.explorer.isExpanded(node.path);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () async {
            if (node.isDirectory) {
              setState(() {
                widget.state.explorer.toggleExpand(node.path);
              });
              if (node.children.isEmpty && widget.state.explorer.isExpanded(node.path)) {
                final children = await widget.state.fetchDirectoryContents(node.path);
                setState(() {
                  node.children.clear();
                  node.children.addAll(children);
                });
              }
            } else {
              widget.state.explorer.select(node.path);
              widget.state.navigation.openFile(node.path);
            }
          },
          child: Container(
            color: isSel ? const Color(0xFF2E1065) : Colors.transparent,
            padding: EdgeInsets.only(
              left: 16.0 + (depth * 12.0),
              right: 16.0,
              top: 6.0,
              bottom: 6.0,
            ),
            child: Row(
              children: [
                Icon(
                  node.isDirectory
                      ? (isExp ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right)
                      : Icons.description,
                  size: 16,
                  color: node.isDirectory ? Colors.white54 : const Color(0xFFA78BFA),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    node.name,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                      color: isSel ? Colors.white : Colors.white70,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (node.isDirectory && isExp)
          ...node.children.map((child) => _buildNode(child, depth + 1)),
      ],
    );
  }
}
