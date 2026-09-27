enum ContentDecision {
  allow,
  block,
  ignore,
  unavailable,
}

abstract interface class ContentPolicy {
  ContentDecision evaluate(String sourceUrl);
}

class LearningContentPolicy implements ContentPolicy {
  static const _blockedSegments = {'shorts', 'trending', 'recommended'};

  @override
  ContentDecision evaluate(String sourceUrl) {
    final uri = Uri.tryParse(sourceUrl);
    if (uri == null || !uri.hasScheme) {
      return ContentDecision.unavailable;
    }
    final segments = uri.pathSegments.map((segment) => segment.toLowerCase());
    return segments.any(_blockedSegments.contains)
        ? ContentDecision.block
        : ContentDecision.allow;
  }
}
