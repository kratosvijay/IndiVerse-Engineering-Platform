# Prompt: Repository Pattern Interface & Implementation

- **Name**: Repository Pattern Scaffolder
- **Purpose**: Builds the abstract repository interface and concrete infrastructure implementation.
- **Inputs**: Entity Name, Database type (e.g. Firestore).
- **Outputs**: Domain repository interface and Data repository implementing the interface.
- **Constraints**: Interface resides in domain, implementation resides in data.
- **Example**: `UserRepository` using Firestore.
- **Expected Result**:
- Abstract class `UserRepository` inside domain.
- Class `FirestoreUserRepository` implementing `UserRepository` inside data.
