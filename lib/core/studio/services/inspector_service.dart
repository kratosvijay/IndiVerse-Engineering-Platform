import 'dart:io';
import '../../../../platform_sdk/platform_sdk.dart';

class InspectorService {
  final PlatformSDK sdk;

  InspectorService(this.sdk);

  Future<Map<String, dynamic>> inspect(
      {required String id, required String type}) async {
    switch (type) {
      case "workspace":
        final file = File(Directory.current.path + '/' + id);
        if (!file.existsSync()) {
          throw Exception("File not found for inspection: $id");
        }
        final content = file.readAsStringSync();
        final lines = content.split('\n');

        // Extract mock symbol signatures
        final symbols = <String>[];
        final classRegex = RegExp(r'class\s+([A-Za-z0-9_]+)');
        final methodRegex =
            RegExp(r'(?:Future<)?[A-Za-z0-9_]+>?\s+([A-Za-z0-9_]+)\(');

        for (final line in lines) {
          final classMatch = classRegex.firstMatch(line);
          if (classMatch != null) {
            symbols.add("• Class: ${classMatch.group(1)}");
          }
          final methodMatch = methodRegex.firstMatch(line);
          if (methodMatch != null &&
              !line.contains('class ') &&
              !line.contains('if(') &&
              !line.contains('for(')) {
            final name = methodMatch.group(1);
            if (name != 'if' &&
                name != 'for' &&
                name != 'while' &&
                name != 'switch') {
              symbols.add("• Method: $name()");
            }
          }
        }

        return {
          "type": "workspace",
          "id": id,
          "details": {
            "path": id,
            "size": "${(file.lengthSync() / 1024).toStringAsFixed(1)} KB",
            "lines": lines.length,
            "language": id.endsWith('.dart') ? 'Dart' : 'Unknown',
            "gitStatus": "Clean",
            "indexed": true,
            "embeddings": "Generated",
            "symbols": symbols.take(10).toList(),
          }
        };

      case "search":
        return {
          "type": "search",
          "id": id,
          "details": {
            "file": id,
            "score": "0.98",
            "reason": "Exact symbol match found",
            "snippet": "class PlatformSDK { ... }",
          }
        };

      case "workflow":
        return {
          "type": "workflow",
          "id": id,
          "details": {
            "state": "idle",
            "duration": "1.2s",
            "tokens": 1845,
            "cost": "\$0.0018",
            "currentStep": "Awaiting execution trigger",
          }
        };

      case "architecture":
        return {
          "type": "architecture",
          "id": id,
          "details": {
            "name": id,
            "health": "Healthy",
            "latency": "3ms",
            "status": "ready",
          }
        };

      default:
        throw Exception("Unknown inspection type: $type");
    }
  }
}
