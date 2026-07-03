class CommandContext {
  final dynamic state;
  CommandContext(this.state);
}

class Command {
  final String id;
  final String title;
  final String description;
  final String? shortcut;
  final String category;
  final Future<void> Function(CommandContext) execute;

  const Command({
    required this.id,
    required this.title,
    required this.description,
    this.shortcut,
    required this.category,
    required this.execute,
  });
}
