import 'session_context.dart';
import 'request_context.dart';
import '../../../platform_sdk/platform_sdk.dart';

class ToolExecutionContext {
  final SessionContext session;
  final RequestContext request;
  final PlatformSDK sdk;

  const ToolExecutionContext({
    required this.session,
    required this.request,
    required this.sdk,
  });
}
