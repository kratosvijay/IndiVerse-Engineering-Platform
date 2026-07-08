import 'package:flutter/material.dart';
import '../../../models/inline_ai_models.dart';
import '../controllers/inline_ai_controller.dart';

class InlineAIOverlayWidget extends StatefulWidget {
  final InlineAISession session;
  final InlineAIController controller;
  final double globalX;
  final double globalY;

  const InlineAIOverlayWidget({
    super.key,
    required this.session,
    required this.controller,
    required this.globalX,
    required this.globalY,
  });

  @override
  State<InlineAIOverlayWidget> createState() => _InlineAIOverlayWidgetState();
}

class _InlineAIOverlayWidgetState extends State<InlineAIOverlayWidget> {
  final TextEditingController _promptTextController = TextEditingController();
  InlineAction _selectedAction = InlineAction.edit;

  @override
  void initState() {
    super.initState();
    _promptTextController.text = widget.session.request.prompt;
    _selectedAction = widget.session.request.action;
  }

  @override
  void didUpdateWidget(covariant InlineAIOverlayWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session.request.prompt != widget.session.request.prompt) {
      _promptTextController.text = widget.session.request.prompt;
    }
    if (oldWidget.session.request.action != widget.session.request.action) {
      _selectedAction = widget.session.request.action;
    }
  }

  @override
  void dispose() {
    _promptTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final screenHeight = media.size.height;
    final screenWidth = media.size.width;

    const double overlayWidth = 450.0;
    double maxOverlayHeight = 350.0;

    if (widget.session.state == InlineAIState.prompting) {
      maxOverlayHeight = 120.0;
    }

    double left = widget.globalX;
    double top = widget.globalY;

    if (left + overlayWidth > screenWidth) {
      left = screenWidth - overlayWidth - 16;
    }
    if (left < 16) left = 16;

    if (top + maxOverlayHeight > screenHeight) {
      top = widget.globalY - maxOverlayHeight - 24;
    }
    if (top < 16) top = 16;

    return Positioned(
      left: left,
      top: top,
      width: overlayWidth,
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E2E),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF3F3F56), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: const BoxDecoration(
                  color: Color(0xFF161622),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _getHeaderText(),
                      style: const TextStyle(
                        color: Color(0xFFA78BFA),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (widget.session.state == InlineAIState.prompting)
                      DropdownButton<InlineAction>(
                        value: _selectedAction,
                        dropdownColor: const Color(0xFF1E1E2E),
                        underline: const SizedBox(),
                        style: const TextStyle(color: Colors.white, fontSize: 10),
                        isDense: true,
                        items: InlineAction.values.map((action) {
                          return DropdownMenuItem<InlineAction>(
                            value: action,
                            child: Text(action.name.toUpperCase()),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedAction = val;
                            });
                          }
                        },
                      ),
                  ],
                ),
              ),

              // Content Area
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: _buildBody(),
              ),

              // Footer Action Bar
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  String _getHeaderText() {
    switch (widget.session.state) {
      case InlineAIState.prompting:
        return 'INLINE AI EDIT';
      case InlineAIState.buildingContext:
        return 'GATHERING CONTEXT...';
      case InlineAIState.waitingProvider:
        return 'CONNECTING...';
      case InlineAIState.streaming:
        return 'STREAMING CHANGES...';
      case InlineAIState.computingDiff:
        return 'COMPUTING DIFF...';
      case InlineAIState.reviewing:
        return 'REVIEW PROPOSED CHANGES';
      case InlineAIState.applying:
        return 'APPLYING CHANGES...';
      case InlineAIState.applied:
        return 'CHANGES APPLIED';
      case InlineAIState.rejected:
        return 'CHANGES REJECTED';
      case InlineAIState.cancelled:
        return 'GENERATION CANCELLED';
      case InlineAIState.failed:
        return 'GENERATION FAILED';
      default:
        return 'INLINE AI';
    }
  }

  Widget _buildBody() {
    final state = widget.session.state;

    if (state == InlineAIState.prompting) {
      return TextField(
        controller: _promptTextController,
        autofocus: true,
        style: const TextStyle(color: Colors.white, fontSize: 12),
        decoration: const InputDecoration(
          hintText: 'Describe changes to make to the selection...',
          hintStyle: TextStyle(color: Colors.white30, fontSize: 12),
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
        onSubmitted: (val) {
          if (val.trim().isNotEmpty) {
            widget.controller.submitPrompt(val.trim(), _selectedAction);
          }
        },
      );
    }

    if (state == InlineAIState.buildingContext ||
        state == InlineAIState.waitingProvider ||
        state == InlineAIState.applying) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24.0),
        child: Column(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFA78BFA)),
              ),
            ),
          ],
        ),
      );
    }

    if (state == InlineAIState.failed) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Error details:',
            style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            widget.session.error ?? 'Unknown error.',
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      );
    }

    // Diff / Preview Panel
    final result = widget.session.result;
    if (result == null || result.diff.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24.0),
        child: Center(
          child: Text(
            'Waiting for code...',
            style: TextStyle(color: Colors.white30, fontSize: 11),
          ),
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        color: const Color(0xFF131024),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF3F3F56), width: 1),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: result.diff.length,
        itemBuilder: (context, index) {
          final block = result.diff[index];
          return _buildDiffLine(block);
        },
      ),
    );
  }

  Widget _buildDiffLine(DiffBlock block) {
    Color textColor = const Color(0xFFD9E0EE);
    Color? bgColor;
    String prefix = '  ';
    TextDecoration? decoration;

    switch (block.type) {
      case DiffType.inserted:
        textColor = const Color(0xFFA6E3A1);
        bgColor = const Color(0x1FA6E3A1);
        prefix = '+ ';
        break;
      case DiffType.deleted:
        textColor = const Color(0xFFF38BA8);
        bgColor = const Color(0x1FF38BA8);
        prefix = '- ';
        decoration = TextDecoration.lineThrough;
        break;
      case DiffType.modified:
        textColor = const Color(0xFFF9E2AF);
        bgColor = const Color(0x1FF9E2AF);
        prefix = '~ ';
        break;
      default:
        break;
    }

    return Container(
      color: bgColor,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      child: RichText(
        text: TextSpan(
          text: prefix,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 11,
            color: textColor.withValues(alpha: 0.7),
          ),
          children: [
            TextSpan(
              text: block.text,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: textColor,
                decoration: decoration,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    final state = widget.session.state;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF161622),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: _getFooterActions(state),
      ),
    );
  }

  List<Widget> _getFooterActions(InlineAIState state) {
    if (state == InlineAIState.prompting) {
      return [
        TextButton(
          onPressed: () => widget.controller.reject(),
          child: const Text('Cancel', style: TextStyle(color: Colors.white54, fontSize: 11)),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () {
            final val = _promptTextController.text.trim();
            if (val.isNotEmpty) {
              widget.controller.submitPrompt(val, _selectedAction);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8B5CF6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            minimumSize: Size.zero,
          ),
          child: const Text('Generate', style: TextStyle(color: Colors.white, fontSize: 11)),
        ),
      ];
    }

    if (state == InlineAIState.streaming) {
      return [
        ElevatedButton(
          onPressed: () => widget.controller.cancel(),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            minimumSize: Size.zero,
          ),
          child: const Text('Stop', style: TextStyle(color: Colors.white, fontSize: 11)),
        ),
      ];
    }

    if (state == InlineAIState.reviewing) {
      return [
        OutlinedButton(
          onPressed: () => widget.controller.reject(),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.redAccent),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            minimumSize: Size.zero,
          ),
          child: const Text('Reject', style: TextStyle(color: Colors.redAccent, fontSize: 11)),
        ),
        const SizedBox(width: 8),
        OutlinedButton(
          onPressed: () => widget.controller.retry(),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFF3F3F56)),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            minimumSize: Size.zero,
          ),
          child: const Text('Retry', style: TextStyle(color: Colors.white70, fontSize: 11)),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () => widget.controller.accept(),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            minimumSize: Size.zero,
          ),
          child: const Text('Accept', style: TextStyle(color: Colors.white, fontSize: 11)),
        ),
      ];
    }

    if (state == InlineAIState.failed) {
      return [
        TextButton(
          onPressed: () => widget.controller.reject(),
          child: const Text('Dismiss', style: TextStyle(color: Colors.white54, fontSize: 11)),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () => widget.controller.retry(),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8B5CF6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            minimumSize: Size.zero,
          ),
          child: const Text('Retry', style: TextStyle(color: Colors.white, fontSize: 11)),
        ),
      ];
    }

    return [
      Text(
        state.name.toUpperCase(),
        style: const TextStyle(color: Colors.white24, fontSize: 10),
      )
    ];
  }
}
