import '../contracts/transport.dart';
import 'transport.dart';

class TransportFactory {
  McpTransport createStdio() => StdioTransport();
}
