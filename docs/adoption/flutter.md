# Adoption Guide: Flutter Projects

To adopt the IDP in a Flutter project, follow these steps:

1. **Scaffold Layout**: Clean up the `lib/` directory to match the clean architecture schema:
   - `lib/domain/` (entities, usecases, repositories)
   - `lib/data/` (models, datasources, repositories)
   - `lib/presentation/` (controllers, screens)
2. **Apply Linting**: Configure `analysis_options.yaml` to reference rules in the IDP.
3. **AI Integration**: Copy prompts from the IDP `prompts/flutter/` directory into your coding assistant's context when generating features.
