# Prompt: Clean Architecture Scaffolder

- **Name**: Clean Architecture Layer Scaffolder
- **Purpose**: Scaffolds the three clean architecture directories for a new feature.
- **Inputs**: Feature Name.
- **Outputs**: Folder tree structure containing domain, data, and presentation folders.
- **Constraints**: Zero business logic, purely structure.
- **Example**: Feature `booking`.
- **Expected Result**:
- `domain/entities/`, `domain/repositories/`, `domain/usecases/`
- `data/models/`, `data/repositories/`, `data/datasources/`
- `presentation/controllers/`, `presentation/screens/`
