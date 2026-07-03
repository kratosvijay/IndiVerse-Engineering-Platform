import 'package:flutter/material.dart';

class FindOverlayWidget extends StatefulWidget {
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onNext;
  final VoidCallback onPrev;
  final VoidCallback onClose;
  final int totalMatches;
  final int currentIdx;

  const FindOverlayWidget({
    super.key,
    required this.onSearchChanged,
    required this.onNext,
    required this.onPrev,
    required this.onClose,
    required this.totalMatches,
    required this.currentIdx,
  });

  @override
  State<FindOverlayWidget> createState() => _FindOverlayWidgetState();
}

class _FindOverlayWidgetState extends State<FindOverlayWidget> {
  final TextEditingController _controller = TextEditingController();
  bool _caseSensitive = false;
  bool _regex = false;
  bool _wholeWord = false;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 16,
      right: 16,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(4),
        color: const Color(0xFF131024),
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF2C284D)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  style: const TextStyle(fontSize: 12, color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Find...',
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 4),
                  ),
                  onChanged: widget.onSearchChanged,
                ),
              ),
              const SizedBox(width: 4),
              _buildToggle('Aa', _caseSensitive, () {
                setState(() => _caseSensitive = !_caseSensitive);
              }),
              _buildToggle('.*', _regex, () {
                setState(() => _regex = !_regex);
              }),
              _buildToggle('""', _wholeWord, () {
                setState(() => _wholeWord = !_wholeWord);
              }),
              const SizedBox(width: 8),
              Text(
                widget.totalMatches > 0 ? '${widget.currentIdx + 1}/${widget.totalMatches}' : '0/0',
                style: const TextStyle(fontSize: 11, color: Colors.white30),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.arrow_upward, size: 14, color: Colors.white54),
                onPressed: widget.onPrev,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_downward, size: 14, color: Colors.white54),
                onPressed: widget.onNext,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 14, color: Colors.white54),
                onPressed: widget.onClose,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggle(String label, bool active, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF8B5CF6) : Colors.transparent,
          borderRadius: BorderRadius.circular(2),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 10, color: active ? Colors.white : Colors.white54, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
