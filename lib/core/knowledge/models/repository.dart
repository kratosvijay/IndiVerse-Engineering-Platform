class RepositoryModel {
  final String name;
  final String path;
  final List<String> packages;

  const RepositoryModel(
      {required this.name, required this.path, this.packages = const []});
}
