import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'workbench_providers.dart';

class CommandContext {
  final dynamic target;
  final Map<String, dynamic> arguments;

  const CommandContext({this.target, this.arguments = const {}});
}

class Command {
  final String id;
  final String title;
  final String category;
  final String description;
  final SingleActivator? shortcut;
  final IconData? icon;
  bool enabled;
  bool visible;
  final Future<OperationResult<void>> Function(CommandContext context) handler;

  Command({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    this.shortcut,
    this.icon,
    this.enabled = true,
    this.visible = true,
    required this.handler,
  });
}

class CommandRegistry {
  final Map<String, Command> _commands = {};

  void register(Command cmd) {
    _commands[cmd.id] = cmd;
  }

  Command? get(String id) => _commands[id];

  List<Command> all() => _commands.values.toList();
}

class CommandDispatcher {
  final CommandRegistry registry;

  CommandDispatcher(this.registry);

  Future<OperationResult<void>> execute(String id, CommandContext context) async {
    final cmd = registry.get(id);
    if (cmd == null) {
      return OperationResult.fail(WorkbenchError(
        code: "COMMAND_NOT_FOUND",
        message: "Command '$id' not registered.",
      ));
    }
    if (!cmd.enabled) {
      return OperationResult.fail(WorkbenchError(
        code: "COMMAND_DISABLED",
        message: "Command '$id' is disabled.",
      ));
    }

    try {
      return await cmd.handler(context);
    } catch (e) {
      return OperationResult.fail(WorkbenchError(
        code: "EXECUTION_ERROR",
        message: e.toString(),
      ));
    }
  }
}

class KeyboardShortcutManager {
  final CommandDispatcher dispatcher;
  final CommandRegistry registry;

  KeyboardShortcutManager({required this.dispatcher, required this.registry});

  bool handleKeyEvent(KeyEvent event, CommandContext context) {
    if (event is! KeyDownEvent) return false;

    final allCmds = registry.all();
    for (final cmd in allCmds) {
      final shortcut = cmd.shortcut;
      if (shortcut != null) {
        if (shortcut.control == HardwareKeyboard.instance.isControlPressed &&
            shortcut.meta == HardwareKeyboard.instance.isMetaPressed &&
            shortcut.shift == HardwareKeyboard.instance.isShiftPressed &&
            shortcut.alt == HardwareKeyboard.instance.isAltPressed &&
            shortcut.trigger == event.logicalKey) {
          dispatcher.execute(cmd.id, context);
          return true;
        }
      }
    }
    return false;
  }
}
