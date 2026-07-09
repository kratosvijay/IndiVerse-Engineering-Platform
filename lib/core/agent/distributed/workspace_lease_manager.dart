import 'distributed_models.dart';

class WorkspaceLeaseManager {
  final Map<String, WorkspaceLease> activeLeases = {};

  WorkspaceLease? acquireLease({
    required LeaseType type,
    required String resourcePath,
    required String ownerAgentId,
    required Duration duration,
  }) {
    final active = activeLeases[resourcePath];
    final now = DateTime.now();

    if (active != null && now.isBefore(active.expiresAt)) {
      if (active.ownerAgentId != ownerAgentId) {
        throw Exception('Lease Conflict: resource $resourcePath is locked by agent ${active.ownerAgentId}.');
      }
      // Re-acquired/renewed by same owner
      return renewLease(active.leaseId, duration);
    }

    final lease = WorkspaceLease(
      leaseId: 'lease-${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      resourcePath: resourcePath,
      ownerAgentId: ownerAgentId,
      leaseVersion: (active?.leaseVersion ?? 0) + 1,
      acquiredAt: now,
      expiresAt: now.add(duration),
      renewCount: 0,
    );

    activeLeases[resourcePath] = lease;
    return lease;
  }

  WorkspaceLease? renewLease(String leaseId, Duration extension) {
    final now = DateTime.now();
    for (final entry in activeLeases.entries) {
      if (entry.value.leaseId == leaseId) {
        final current = entry.value;
        final updated = WorkspaceLease(
          leaseId: current.leaseId,
          type: current.type,
          resourcePath: current.resourcePath,
          ownerAgentId: current.ownerAgentId,
          leaseVersion: current.leaseVersion + 1,
          acquiredAt: current.acquiredAt,
          expiresAt: now.add(extension),
          renewCount: current.renewCount + 1,
        );
        activeLeases[current.resourcePath] = updated;
        return updated;
      }
    }
    return null;
  }

  void releaseLease(String leaseId) {
    activeLeases.removeWhere((_, lease) => lease.leaseId == leaseId);
  }

  // Evicts expired locks
  void evictExpiredLeases() {
    final now = DateTime.now();
    activeLeases.removeWhere((_, lease) => now.isAfter(lease.expiresAt));
  }
}
