import 'package:flutter/material.dart';
import '../../../core/state/studio_state.dart';
import '../../../models/ids.dart';

class OutlineWidget extends StatefulWidget {
  final StudioState state;

  const OutlineWidget({super.key, required this.state});

  @override
  State<OutlineWidget> createState() => _OutlineWidgetState();
}

class _OutlineWidgetState extends State<OutlineWidget> {
  List<Map<String, dynamic>> _outline = [];
  bool _loading = false;
  DocumentId? _currentDocId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadOutline();
  }

  @override
  void didUpdateWidget(covariant OutlineWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadOutline();
  }

  void _loadOutline() async {
    final activeTab = widget.state.editor.activeTab;
    if (activeTab == null) {
      if (mounted) {
        setState(() {
          _outline = [];
          _currentDocId = null;
        });
      }
      return;
    }

    final docId = DocumentId(activeTab.document.path);
    if (docId == _currentDocId) return;

    if (mounted) {
      setState(() {
        _loading = true;
        _currentDocId = docId;
      });
    }

    final cached = widget.state.documentService.getOutline(docId);
    if (cached != null) {
      if (mounted) {
        setState(() {
          _outline = cached;
          _loading = false;
        });
      }
      return;
    }

    final res = await widget.state.workbench.symbol.openOutline(docId);
    if (res.success && res.data != null) {
      if (mounted) {
        setState(() {
          _outline = res.data!;
          _loading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _outline = [];
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentDocId == null) {
      return const Center(
        child: Text('No active document.', style: TextStyle(color: Colors.white24, fontSize: 12)),
      );
    }

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_outline.isEmpty) {
      return const Center(
        child: Text('No symbols found.', style: TextStyle(color: Colors.white24, fontSize: 12)),
      );
    }

    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'DOCUMENT OUTLINE',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white30,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _outline.length,
              itemBuilder: (context, index) {
                return _buildOutlineItem(_outline[index], 0);
              },
            ),
          ),
        ],
      );
  }

  Widget _buildOutlineItem(Map<String, dynamic> item, int depth) {
    final children = item['children'] as List? ?? [];
    final name = item['name'] ?? '';
    final kind = item['kind'] ?? '';
    final line = item['line'] ?? 1;

    IconData icon;
    Color iconColor;

    switch (kind) {
      case 'Class':
        icon = Icons.grid_view;
        iconColor = const Color(0xFF3B82F6);
        break;
      case 'Constructor':
        icon = Icons.settings;
        iconColor = const Color(0xFF8B5CF6);
        break;
      case 'Method':
      case 'Function':
        icon = Icons.functions;
        iconColor = const Color(0xFF10B981);
        break;
      case 'Variable':
        icon = Icons.circle;
        iconColor = const Color(0xFFF59E0B);
        break;
      default:
        icon = Icons.code;
        iconColor = Colors.white54;
    }

    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.only(left: 16.0 + (depth * 16.0), right: 16.0),
          dense: true,
          leading: Icon(icon, size: 14, color: iconColor),
          title: Text(
            name,
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
          onTap: () {
            widget.state.workbench.navigation.jumpToLine(_currentDocId!, line);
          },
        ),
        if (children.isNotEmpty)
          ...children.map((child) => _buildOutlineItem(Map<String, dynamic>.from(child), depth + 1)),
      ],
    );
  }
}
