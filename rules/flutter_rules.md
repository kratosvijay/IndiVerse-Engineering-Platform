# Flutter Coding Rules

Guidelines for building premium, responsive, and robust mobile interfaces in the IndiVerse ecosystem.

## Clean Architecture in Flutter
- Keep UI widgets stateless whenever possible. Delegate state updates to controllers.
- Use GetX controllers to coordinate state. Avoid inline state management.
- Always use relative imports inside the package. Avoid package: imports for internal files.

## UI Design & Aesthetics
- All visual elements must adhere to the design system (curated palettes, typography, margins).
- Use proper typography styling from `GoogleFonts` or custom theme files.
- Enable smooth hover and click micro-animations to enhance interactive feedback.
