import 'package:flutter/material.dart';
import '../../../core/state/studio_state.dart';
import '../../../core/services/keyboard_shortcut_manager.dart';

class CommandPaletteWidget extends StatefulWidget {
  final StudioState state;
  final VoidCallback onClose;

  const CommandPaletteWidget({
    super.key,
    required this.state,
    required this.onClose,
  });

  @override
  State<CommandPaletteWidget> createState() => _CommandPaletteWidgetState();
}

class _CommandPaletteWidgetState extends State<CommandPaletteWidget> {
  final TextEditingController _filterController = TextEditingController();
  List<Command> _filteredCommands = [];

  @override
  void initState() {
    super.initState();
    _filteredCommands = widget.state.commandRegistry.all();
  }

  void _filter(String text) {
    setState(() {
      _filteredCommands = widget.state.commandRegistry.all()
          .where(
            (c) =>
                c.title.toLowerCase().contains(text.toLowerCase()) ||
                c.description.toLowerCase().contains(text.toLowerCase()),
          )
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      alignment: Alignment.topCenter,
      padding: const EdgeInsets.only(top: 100),
      child: Material(
        color: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxHeight: 300, maxWidth: 500),
          decoration: BoxDecoration(
            color: const Color(0xFF131024),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF2C284D)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _filterController,
                onChanged: _filter,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Type a command to execute...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                  prefixIcon: Icon(Icons.keyboard, color: Colors.white54),
                ),
              ),
              const Divider(height: 1, color: Color(0xFF2C284D)),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _filteredCommands.length,
                  itemBuilder: (context, index) {
                    final cmd = _filteredCommands[index];
                    return ListTile(
                      title: Text(
                        cmd.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        cmd.description,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white30,
                        ),
                      ),
                      trailing: cmd.shortcut != null
                          ? Text(
                              '${cmd.shortcut!.control ? "Ctrl+" : ""}${cmd.shortcut!.meta ? "Cmd+" : ""}${cmd.shortcut!.shift ? "Shift+" : ""}${cmd.shortcut!.trigger.keyLabel}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFFA78BFA),
                              ),
                            )
                          : null,
                      onTap: () {
                        widget.state.dispatcher.execute(
                          cmd.id,
                          const CommandContext(),
                        );
                        widget.onClose();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
