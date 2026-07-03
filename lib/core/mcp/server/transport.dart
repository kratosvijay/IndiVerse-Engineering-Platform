import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../contracts/transport.dart';

class StdioTransport implements McpTransport {
  final _controller = StreamController<String>.broadcast();

  StdioTransport() {
    stdin
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
      _controller.add(line);
    });
  }

  @override
  Stream<String> get messageStream => _controller.stream;

  @override
  void sendMessage(String message) {
    stdout.writeln(message);
  }

  @override
  Future<void> close() async {
    await _controller.close();
  }
}
