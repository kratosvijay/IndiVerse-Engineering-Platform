# Prompt: Offline First Synchronization Sync Policy

- **Name**: Offline-First Local Cache Sync Generator
- **Purpose**: Generates synchronization rules that check local cache before querying network.
- **Inputs**: Data type, cache duration constraint.
- **Outputs**: Logic block handling local caching (SQLite/Hive) and remote fetch with background sync.
- **Constraints**: Must handle network failure gracefully.
- **Example**: `CachingDriverProfileRepository`.
- **Expected Result**: Implementation caching local profile and updating in background upon internet restoral.
