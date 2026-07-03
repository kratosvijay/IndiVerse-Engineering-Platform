# Hello World Plugin Example

Here is a complete blueprint demonstrating how to construct a simple local execution plugin:

## 1. Directory Structure

```text
plugins/
└── hello_plugin/
    ├── manifest.json
    └── hello_plugin.dart
```

## 2. Manifest Definition

```json
{
  "id": "indiverse.hello",
  "name": "Hello World",
  "version": "1.0.0",
  "category": "tool",
  "capabilities": ["toolExecution"]
}
```

## 3. Integration Code

```dart
class HelloPlugin implements Integration {
  // Conforms to Integration lifecycle methods...
}
```
