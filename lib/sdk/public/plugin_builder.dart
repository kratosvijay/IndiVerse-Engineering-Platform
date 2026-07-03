import '../../../core/integrations/integration.dart';
import 'plugin_context.dart';

abstract class PluginBuilder {
  Integration build(PluginContext context);
}
