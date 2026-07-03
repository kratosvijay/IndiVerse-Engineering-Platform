import 'package:flutter/material.dart';
import '../../../core/state/studio_state.dart';

class ArchitectureWidget extends StatelessWidget {
  final StudioState state;

  const ArchitectureWidget({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Architecture Explorer',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'Visualize the system layers, contracts, health states, and inter-component dependencies.',
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 24),
          // We can show the graph visualization
          Expanded(
            child: ListView.builder(
              itemCount: 4,
              itemBuilder: (context, index) {
                String label;
                String layer;
                String id;
                switch (index) {
                  case 0:
                    label = 'Agent Orchestration Engine';
                    layer = 'Agent';
                    id = 'agent';
                    break;
                  case 1:
                    label = 'Knowledge & Vector Search';
                    layer = 'Knowledge';
                    id = 'knowledge';
                    break;
                  case 2:
                    label = 'Workspace context Manager';
                    layer = 'Workspace';
                    id = 'workspace';
                    break;
                  default:
                    label = 'Core Execution Pipeline';
                    layer = 'Runtime';
                    id = 'runtime';
                }

                return InkWell(
                  onTap: () {
                    state.selectArchitectureNode(id);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1B4B),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF312E81)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Layer: $layer',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white30,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withAlpha(25),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Healthy',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
