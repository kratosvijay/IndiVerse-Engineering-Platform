import '../middleware/middleware.dart';
import '../models/ai_request.dart';
import '../models/ai_response.dart';

class Pipeline {
  final List<Middleware> _middlewares = [];

  void add(Middleware middleware) {
    _middlewares.add(middleware);
  }

  void clear() {
    _middlewares.clear();
  }

  Future<AIResponse> execute(
      AIRequest request, Future<AIResponse> Function(AIRequest) endpoint) {
    Future<AIResponse> dispatch(int index, AIRequest req) {
      if (index >= _middlewares.length) {
        return endpoint(req);
      }
      return _middlewares[index]
          .next(req, (nextReq) => dispatch(index + 1, nextReq));
    }

    return dispatch(0, request);
  }
}
