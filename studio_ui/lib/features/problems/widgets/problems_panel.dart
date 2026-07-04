import 'package:flutter/material.dart';
import '../../../core/state/studio_state.dart';
import '../../../models/ids.dart';
import '../../../models/language_intelligence_models.dart';
import '../../../models/editor_document.dart';

class ProblemsPanel extends StatefulWidget {
  final StudioState state;
  final VoidCallback onClose;

  const ProblemsPanel({super.key, required this.state, required this.onClose});

  @override
  State<ProblemsPanel> createState() => _ProblemsPanelState();
}

class _ProblemsPanelState extends State<ProblemsPanel> {
  bool _currentFileOnly = false;
  bool _showErrors = true;
  bool _showWarnings = true;
  bool _showInfos = true;
  final Set<String> _collapsedFiles = {};

  @override
  Widget build(BuildContext context) {
    final activeDoc = widget.state.editor.activeTab?.document;
    final grouped = <String, List<Diagnostic>>{};

    widget.state.diagnostics.groupedDiagnostics.forEach((path, diags) {
      if (_currentFileOnly && path != activeDoc?.path) return;

      final filtered = diags.where((d) {
        if (d.severity == DiagnosticSeverity.error && !_showErrors) {
          return false;
        }
        if (d.severity == DiagnosticSeverity.warning && !_showWarnings) {
          return false;
        }
        if (d.severity == DiagnosticSeverity.information && !_showInfos) {
          return false;
        }
        if (d.severity == DiagnosticSeverity.hint && !_showInfos) return false;
        return true;
      }).toList();

      if (filtered.isNotEmpty) {
        grouped[path] = filtered;
      }
    });

    final totalErrors = grouped.values.fold<int>(
      0,
      (sum, list) =>
          sum +
          list.where((d) => d.severity == DiagnosticSeverity.error).length,
    );
    final totalWarnings = grouped.values.fold<int>(
      0,
      (sum, list) =>
          sum +
          list.where((d) => d.severity == DiagnosticSeverity.warning).length,
    );
    final totalInfos = grouped.values.fold<int>(
      0,
      (sum, list) =>
          sum +
          list
              .where(
                (d) =>
                    d.severity == DiagnosticSeverity.information ||
                    d.severity == DiagnosticSeverity.hint,
              )
              .length,
    );

    return Container(
      height: 220,
      decoration: const BoxDecoration(
        color: Color(0xFF131024),
        border: Border(top: BorderSide(color: Color(0xFF2C284D))),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                const Text(
                  'PROBLEMS',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: Color(0xFFA78BFA),
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(width: 16),
                _buildToggleButton(
                  label: 'Current File',
                  isSelected: _currentFileOnly,
                  onPressed: () =>
                      setState(() => _currentFileOnly = !_currentFileOnly),
                ),
                const SizedBox(width: 8),
                _buildFilterBadge(
                  label: 'Errors ($totalErrors)',
                  color: Colors.redAccent,
                  isActive: _showErrors,
                  onPressed: () => setState(() => _showErrors = !_showErrors),
                ),
                const SizedBox(width: 8),
                _buildFilterBadge(
                  label: 'Warnings ($totalWarnings)',
                  color: Colors.orangeAccent,
                  isActive: _showWarnings,
                  onPressed: () =>
                      setState(() => _showWarnings = !_showWarnings),
                ),
                const SizedBox(width: 8),
                _buildFilterBadge(
                  label: 'Info ($totalInfos)',
                  color: Colors.blueAccent,
                  isActive: _showInfos,
                  onPressed: () => setState(() => _showInfos = !_showInfos),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(
                    Icons.close,
                    size: 14,
                    color: Colors.white54,
                  ),
                  onPressed: widget.onClose,
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFF2C284D)),
          Expanded(
            child: grouped.isEmpty
                ? const Center(
                    child: Text(
                      'No problems have been detected in the workspace.',
                      style: TextStyle(color: Colors.white24, fontSize: 12),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    children: grouped.entries.map((entry) {
                      final path = entry.key;
                      final diags = entry.value;
                      final isCollapsed = _collapsedFiles.contains(path);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: () {
                              setState(() {
                                if (isCollapsed) {
                                  _collapsedFiles.remove(path);
                                } else {
                                  _collapsedFiles.add(path);
                                }
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isCollapsed
                                        ? Icons.chevron_right
                                        : Icons.expand_more,
                                    size: 14,
                                    color: Colors.white54,
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.insert_drive_file_outlined,
                                    size: 14,
                                    color: Colors.purple[200],
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    path.split('/').last,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    path,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.white30,
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white10,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '${diags.length}',
                                      style: const TextStyle(
                                        fontSize: 9,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (!isCollapsed)
                            ...diags.map((d) {
                              IconData iconData = Icons.error_outline;
                              Color iconColor = Colors.redAccent;
                              if (d.severity == DiagnosticSeverity.warning) {
                                iconData = Icons.warning_amber_outlined;
                                iconColor = Colors.orangeAccent;
                              } else if (d.severity ==
                                      DiagnosticSeverity.information ||
                                  d.severity == DiagnosticSeverity.hint) {
                                iconData = Icons.info_outline;
                                iconColor = Colors.blueAccent;
                              }

                              return InkWell(
                                onTap: () {
                                  widget.state.workbench.navigation.jumpToLine(
                                    DocumentId(path),
                                    d.range.start.line,
                                  );
                                  final doc = widget.state.documentService
                                      .getDocument(DocumentId(path));
                                  if (doc != null) {
                                    doc.updateCursor(
                                      Position(
                                        line: d.range.start.line,
                                        column: d.range.start.column,
                                      ),
                                    );
                                    doc.updateSelection(d.range);
                                    widget.state.refreshUI();
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    left: 28,
                                    right: 12,
                                    top: 3,
                                    bottom: 3,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(top: 1),
                                        child: Icon(
                                          iconData,
                                          size: 12,
                                          color: iconColor,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          '[Line ${d.range.start.line}, Col ${d.range.start.column}] ${d.message} (${d.code})',
                                          style: const TextStyle(
                                            fontFamily: 'monospace',
                                            fontSize: 11,
                                            color: Colors.white60,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                        ],
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required String label,
    required bool isSelected,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF4C457D)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected ? const Color(0xFF8B5CF6) : Colors.white10,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.white54,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterBadge({
    required String label,
    required Color color,
    required bool isActive,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      child: Opacity(
        opacity: isActive ? 1.0 : 0.4,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}
