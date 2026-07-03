# Prompt: Architecture Dependency Rule Test Generator

- **Name**: Codebase Architecture Rule Tester
- **Purpose**: Creates validation scripts checking package boundary imports.
- **Inputs**: Forbidden imports list (e.g. data layer importing presentation).
- **Outputs**: Script or Dart test checks.
- **Constraints**: Run over static imports inside raw source folders.
- **Example**: Assert presentation is not imported in domain.
- **Expected Result**: Python or shell check running regex over imports.
