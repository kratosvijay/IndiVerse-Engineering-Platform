class PackageModel {
  final String name;
  final String path;
  final List<String> modules;

  const PackageModel(
      {required this.name, required this.path, this.modules = const []});
}
