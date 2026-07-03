abstract class McpTransport {
  Stream<String> get messageStream;
  void sendMessage(String message);
  Future<void> close();
}
