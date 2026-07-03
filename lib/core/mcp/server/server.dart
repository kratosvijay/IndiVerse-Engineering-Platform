import '../contracts/transport.dart';
import '../contracts/gateway.dart';
import '../../../platform_sdk/platform_sdk.dart';

class McpServer {
  final McpTransport transport;
  final McpGateway gateway;
  final PlatformSDK sdk;

  McpServer(this.transport, this.gateway, this.sdk) {
    transport.messageStream.listen(_onMessage);
  }

  void _onMessage(String line) async {
    try {
      // JSON-RPC handler mapping
    } catch (_) {}
  }
}
