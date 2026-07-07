import 'package:flutter/material.dart';
import '../../../models/ai_models.dart';
import 'code_block_widget.dart';

sealed class MessageBlock {}

class ParagraphBlock extends MessageBlock {
  final String text;
  ParagraphBlock(this.text);
}

class CodeBlock extends MessageBlock {
  final String language;
  final String code;
  CodeBlock({required this.language, required this.code});
}

abstract class ChatMessageRenderer {
  Widget render(ChatMessage message);
}

class MarkdownChatRenderer implements ChatMessageRenderer {
  final void Function(String code)? onInsertCode;

  const MarkdownChatRenderer({this.onInsertCode});

  @override
  Widget render(ChatMessage message) {
    final blocks = _parseMarkdown(message.content);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: blocks.map((block) {
        switch (block) {
          case ParagraphBlock():
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: _renderParagraph(block.text),
            );
          case CodeBlock():
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: CodeBlockWidget(
                language: block.language,
                code: block.code,
                onInsert: onInsertCode,
              ),
            );
        }
      }).toList(),
    );
  }

  List<MessageBlock> _parseMarkdown(String content) {
    final List<MessageBlock> blocks = [];
    final lines = content.split('\n');
    final List<String> currentParagraph = [];

    int i = 0;
    while (i < lines.length) {
      final line = lines[i];
      if (line.trim().startsWith('```')) {
        // Clear previous paragraph
        if (currentParagraph.isNotEmpty) {
          blocks.add(ParagraphBlock(currentParagraph.join('\n')));
          currentParagraph.clear();
        }

        final lang = line.trim().substring(3).trim();
        final List<String> codeLines = [];
        i++;
        while (i < lines.length && !lines[i].trim().startsWith('```')) {
          codeLines.add(lines[i]);
          i++;
        }
        blocks.add(
          CodeBlock(
            language: lang.isEmpty ? 'text' : lang,
            code: codeLines.join('\n'),
          ),
        );
      } else {
        currentParagraph.add(line);
      }
      i++;
    }

    if (currentParagraph.isNotEmpty) {
      blocks.add(ParagraphBlock(currentParagraph.join('\n')));
    }

    return blocks;
  }

  Widget _renderParagraph(String text) {
    // Basic inline code parsing (e.g. `code`)
    final spans = <TextSpan>[];
    final parts = text.split('`');
    bool isCode = false;

    for (final part in parts) {
      if (isCode) {
        spans.add(
          TextSpan(
            text: part,
            style: const TextStyle(
              fontFamily: 'monospace',
              backgroundColor: Color(0x1F808080),
              color: Color(0xFFE2E2E2),
              fontSize: 12,
            ),
          ),
        );
      } else {
        spans.add(
          TextSpan(
            text: part,
            style: const TextStyle(
              color: Color(0xFFD4D4D4),
              fontSize: 13,
              height: 1.4,
            ),
          ),
        );
      }
      isCode = !isCode;
    }

    return RichText(text: TextSpan(children: spans));
  }
}
