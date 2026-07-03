import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/state/studio_state.dart';

class SearchWidget extends StatefulWidget {
  final StudioState state;

  const SearchWidget({super.key, required this.state});

  @override
  State<SearchWidget> createState() => _SearchWidgetState();
}

class _SearchWidgetState extends State<SearchWidget> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  void _onSearchChanged(String query) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 250), () {
      widget.state.executeSearch(query);
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Incremental Code Search',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: const InputDecoration(
              hintText: 'Search classes, symbols, or files incrementally...',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: widget.state.searchResults.isEmpty
                ? const Center(
                    child: Text(
                      'No search matches found.',
                      style: TextStyle(color: Colors.white24),
                    ),
                  )
                : ListView.builder(
                    itemCount: widget.state.searchResults.length,
                    itemBuilder: (context, index) {
                      final item = widget.state.searchResults[index];
                      final file = item['file'] ?? '';
                      final snippet = item['snippet'] ?? '';
                      final line = item['lineNumber'] ?? 1;
                      final score = item['score'] ?? 0.0;

                      return ListTile(
                        leading: const Icon(Icons.search, color: Color(0xFF8B5CF6), size: 18),
                        title: Text(file, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFA78BFA))),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(snippet, style: const TextStyle(color: Colors.white70)),
                            const SizedBox(height: 4),
                            Text("Line $line • Match Score: $score", style: const TextStyle(fontSize: 11, color: Colors.white30)),
                          ],
                        ),
                        onTap: () {
                          widget.state.navigation.openFile(file, line: line);
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
