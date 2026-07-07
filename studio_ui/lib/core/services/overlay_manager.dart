import 'package:flutter/material.dart';

enum OverlayType {
  completion(1),
  signature(2),
  hover(3),
  codeAction(4),
  chat(5),
  inlineAI(6),
  rename(7),
  peekDefinition(8);

  final int priority;
  const OverlayType(this.priority);
}

class OverlayDescriptor {
  final String id;
  final OverlayType type;
  final OverlayEntry entry;
  final FocusNode? focusScope;

  const OverlayDescriptor({
    required this.id,
    required this.type,
    required this.entry,
    this.focusScope,
  });
}

class OverlayManager {
  final Map<String, OverlayDescriptor> _overlays = {};

  void register(OverlayDescriptor descriptor) {
    // If there is an existing overlay of the same type or ID, hide it first
    hide(descriptor.id);

    // Resolve conflicts based on priority:
    // If a higher priority overlay is registered, we automatically dismiss lower priority ones.
    final toRemove = <String>[];
    _overlays.forEach((id, existing) {
      if (descriptor.type.priority > existing.type.priority) {
        toRemove.add(id);
      }
    });

    for (final id in toRemove) {
      hide(id);
    }

    _overlays[descriptor.id] = descriptor;
  }

  void show(BuildContext context, String id) {
    final descriptor = _overlays[id];
    if (descriptor != null) {
      Overlay.of(context).insert(descriptor.entry);
      if (descriptor.focusScope != null) {
        descriptor.focusScope!.requestFocus();
      }
    }
  }

  void hide(String id) {
    final descriptor = _overlays[id];
    if (descriptor != null) {
      try {
        descriptor.entry.remove();
      } catch (_) {}
      _overlays.remove(id);
    }
  }

  void hideAll() {
    final keys = List<String>.from(_overlays.keys);
    for (final key in keys) {
      hide(key);
    }
  }

  void bringToFront(String id) {
    final descriptor = _overlays[id];
    if (descriptor != null) {
      try {
        descriptor.entry.remove();
        descriptor.entry.markNeedsBuild();
      } catch (_) {}
    }
  }

  bool isActive(String id) => _overlays.containsKey(id);
}
