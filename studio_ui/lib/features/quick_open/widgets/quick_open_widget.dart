import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../core/state/studio_state.dart';

class QuickOpenWidget extends StatefulWidget {
  final StudioState state;
  final VoidCallback onClose;

  const QuickOpenWidget({super.key, required this.state, required this.onClose});

  @override
  State<QuickOpenWidget> createState() => _QuickOpenWidgetState();
}

class _QuickOpenWidgetState extends State<QuickOpenWidget> {
  final TextEditingController _controller = TextEditingController();
  List<String> _allFiles = [];
  List<String> _filteredFiles = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  void _loadFiles() async {
    try {
      final res = await http.get(
        Uri.parse('http://localhost:${widget.state.serverPort}/api/v1/workspace?path=&recursive=true'),
      );
      final envelope = jsonDecode(res.body);
      if (envelope["success"] == true) {
        final filesList = envelope["data"]["files"] as List? ?? [];
        final paths = filesList
            .where((item) => item["type"] == "file")
            .map<String>((item) => item["path"] as String)
            .toList();
        if (mounted) {
          setState(() {
            _allFiles = paths;
            _filteredFiles = paths;
            _loading = false;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _filterFiles(String query) {
    if (query.isEmpty) {
      setState(() => _filteredFiles = _allFiles);
      return;
    }

    final querySegments = query.toLowerCase().split(' ').where((s) => s.isNotEmpty).toList();

    setState(() {
      _filteredFiles = _allFiles.where((filePath) {
        final pathLower = filePath.toLowerCase();
        return querySegments.every((seg) => pathLower.contains(seg));
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF131024),
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Color(0xFF2C284D)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Container(
        width: 500,
        height: 350,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              style: const TextStyle(fontSize: 13, color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Search files by name (e.g. "pla sdk")...',
                hintStyle: TextStyle(color: Colors.white24),
                border: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF2C284D))),
                isDense: true,
              ),
              onChanged: _filterFiles,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredFiles.isEmpty
                      ? const Center(child: Text('No matching files found.', style: TextStyle(color: Colors.white24, fontSize: 12)))
                      : ListView.builder(
                          itemCount: _filteredFiles.length,
                          itemBuilder: (context, index) {
                            final path = _filteredFiles[index];
                            final name = path.split('/').last;

                            return ListTile(
                              dense: true,
                              title: Text(name, style: const TextStyle(fontSize: 13, color: Colors.white70)),
                              subtitle: Text(path, style: const TextStyle(fontSize: 11, color: Colors.white24)),
                              onTap: () {
                                widget.state.navigation.openFile(path);
                                widget.onClose();
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
