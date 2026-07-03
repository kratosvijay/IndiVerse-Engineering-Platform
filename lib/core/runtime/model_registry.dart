import '../models/model_metadata.dart';

class ModelRegistry {
  final Map<String, ModelMetadata> _models = {};

  void registerModel(ModelMetadata model) {
    _models[model.name] = model;
  }

  ModelMetadata? getModel(String name) => _models[name];

  List<ModelMetadata> getModelsByCapability(dynamic capability) {
    return _models.values
        .where((m) => m.capabilities.contains(capability))
        .toList();
  }
}
