import '../graph/workspace_symbol.dart';

class ArchitectureIndex {
  final Map<String, WorkspaceSymbol> _classes = {};
  final Map<String, WorkspaceSymbol> _enums = {};
  final Map<String, WorkspaceSymbol> _mixins = {};
  final Map<String, WorkspaceSymbol> _typedefs = {};
  final Map<String, WorkspaceSymbol> _extensions = {};
  
  // Custom Architecture Roles parsed from names, directories or inheritance/annotations
  final Map<String, WorkspaceSymbol> _routes = {};
  final Map<String, WorkspaceSymbol> _services = {};
  final Map<String, WorkspaceSymbol> _providers = {};

  void indexSymbol(WorkspaceSymbol symbol) {
    switch (symbol.kind) {
      case SymbolKind.classSymbol:
        _classes[symbol.id] = symbol;
        _detectArchitectureRoles(symbol);
        break;
      case SymbolKind.enumSymbol:
        _enums[symbol.id] = symbol;
        break;
      case SymbolKind.mixin:
        _mixins[symbol.id] = symbol;
        break;
      case SymbolKind.typedefSymbol:
        _typedefs[symbol.id] = symbol;
        break;
      case SymbolKind.extensionSymbol:
        _extensions[symbol.id] = symbol;
        break;
      default:
        break;
    }
  }

  void removeSymbolsForFile(String filePath) {
    _classes.removeWhere((_, s) => s.filePath == filePath);
    _enums.removeWhere((_, s) => s.filePath == filePath);
    _mixins.removeWhere((_, s) => s.filePath == filePath);
    _typedefs.removeWhere((_, s) => s.filePath == filePath);
    _extensions.removeWhere((_, s) => s.filePath == filePath);
    _routes.removeWhere((_, s) => s.filePath == filePath);
    _services.removeWhere((_, s) => s.filePath == filePath);
    _providers.removeWhere((_, s) => s.filePath == filePath);
  }

  void clear() {
    _classes.clear();
    _enums.clear();
    _mixins.clear();
    _typedefs.clear();
    _extensions.clear();
    _routes.clear();
    _services.clear();
    _providers.clear();
  }

  void _detectArchitectureRoles(WorkspaceSymbol symbol) {
    final lowerName = symbol.name.toLowerCase();
    
    // Services: e.g. class AuthService, UserToolService
    if (lowerName.contains('service') || symbol.annotations.any((a) => a.contains('Service'))) {
      _services[symbol.id] = symbol;
    }
    
    // Providers: e.g. class UserProvider, ThemeProvider, AIProvider
    if (lowerName.contains('provider') || symbol.annotations.any((a) => a.contains('Provider'))) {
      _providers[symbol.id] = symbol;
    }

    // Routes: e.g. class UserRoute, router mappings, or path constants
    if (lowerName.contains('route') || lowerName.contains('router') || symbol.annotations.any((a) => a.contains('Route'))) {
      _routes[symbol.id] = symbol;
    }
  }

  List<WorkspaceSymbol> get classes => List.unmodifiable(_classes.values);
  List<WorkspaceSymbol> get enums => List.unmodifiable(_enums.values);
  List<WorkspaceSymbol> get mixins => List.unmodifiable(_mixins.values);
  List<WorkspaceSymbol> get typedefs => List.unmodifiable(_typedefs.values);
  List<WorkspaceSymbol> get extensions => List.unmodifiable(_extensions.values);
  List<WorkspaceSymbol> get routes => List.unmodifiable(_routes.values);
  List<WorkspaceSymbol> get services => List.unmodifiable(_services.values);
  List<WorkspaceSymbol> get providers => List.unmodifiable(_providers.values);
}
