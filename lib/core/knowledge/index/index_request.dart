class IndexRequest {
  final String path;
  final bool force;

  const IndexRequest(this.path, {this.force = false});
}
