import 'package:flutter/material.dart';
import '../controllers/chat_controller.dart';

class ConversationHistorySidebar extends StatelessWidget {
  final ChatController controller;

  const ConversationHistorySidebar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        border: Border(right: BorderSide(color: Color(0xFF333333))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // New conversation button
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007ACC),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4.0),
                ),
              ),
              icon: const Icon(Icons.add, size: 16),
              label: const Text(
                'New Conversation',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              onPressed: () => controller.createNewSession('New Conversation'),
            ),
          ),
          const Divider(height: 1, color: Color(0xFF333333)),
          // Sessions list
          Expanded(
            child: ListenableBuilder(
              listenable: controller,
              builder: (context, _) {
                final history = controller.historyList;
                if (history.isEmpty) {
                  return const Center(
                    child: Text(
                      'No history yet',
                      style: TextStyle(color: Color(0xFF858585), fontSize: 11),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final session = history[index];
                    final isActive = controller.state.session?.id == session.id;

                    return Container(
                      color: isActive
                          ? const Color(0xFF2D2D2D)
                          : Colors.transparent,
                      child: ListTile(
                        dense: true,
                        title: Text(
                          session.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isActive
                                ? Colors.white
                                : const Color(0xFFCCCCCC),
                            fontSize: 12.0,
                            fontWeight: isActive
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        subtitle: Row(
                          children: [
                            Text(
                              session.modelId.toUpperCase(),
                              style: const TextStyle(
                                color: Color(0xFF858585),
                                fontSize: 9.0,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '(${session.messages.length} msg)',
                              style: const TextStyle(
                                color: Color(0xFF858585),
                                fontSize: 9.0,
                              ),
                            ),
                          ],
                        ),
                        onTap: () => controller.switchSession(session),
                      ),
                    );
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
