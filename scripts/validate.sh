#!/usr/bin/env bash
# Platform Validation Entrypoint
python3 "$(dirname "$0")/validate_platform.py" || exit 1

echo "=== Running Dart Quality Gates ==="
dart analyze lib test tool benchmark bin || { echo "Dart static analysis failed!"; exit 1; }
dart test || { echo "Dart unit tests failed!"; exit 1; }
dart format --output=none --set-exit-if-changed lib test tool benchmark bin || { echo "Dart formatting check failed!"; exit 1; }

echo "=== All Platform Gates Passed successfully! ==="
