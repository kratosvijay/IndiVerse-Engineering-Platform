# Prompt: Domain-Driven Design (DDD) Entity Generator

- **Name**: DDD Entity Generator
- **Purpose**: Generates decoupled Domain Entities matching DDD guidelines.
- **Inputs**: Entity Name, List of attributes with types, optional validation rules.
- **Outputs**: Dart class file containing immutable properties, custom constructor, and validation rules.
- **Constraints**: No database packages or dependencies (pure Dart). Attributes must be final.
- **Example**: `User` with `id (String)`, `phone (String)`.
- **Expected Result**:
```dart
class User {
  final String id;
  final String phone;
  User({required this.id, required this.phone}) {
    if (phone.isEmpty) throw ArgumentError("Phone cannot be empty");
  }
}
```
