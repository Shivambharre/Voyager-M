import 'filter_result.dart';
import 'filter_rules.dart';

enum FilterRequestScope { applicationManaged, youtubePlayer, extractedMedia }

class FilterRequest {
  const FilterRequest({
    required this.url,
    required this.resourceType,
    required this.scope,
    this.sourceUrl,
  });

  final Uri url;
  final String resourceType;
  final FilterRequestScope scope;
  final Uri? sourceUrl;
}

abstract interface class ContentFilterEngine {
  Future<void> initialize();
  Future<FilterResult> shouldBlockRequest(FilterRequest request);
  Future<FilterRules?> getCosmeticRules(Uri resource);
  Future<void> dispose();
}

class NoOpContentFilterEngine implements ContentFilterEngine {
  @override
  Future<void> initialize() async {}

  @override
  Future<FilterResult> shouldBlockRequest(FilterRequest request) async =>
      const FilterResult.allow(reason: 'Filtering engine is disabled.');

  @override
  Future<FilterRules?> getCosmeticRules(Uri resource) async => null;

  @override
  Future<void> dispose() async {}
}

class UnavailableContentFilterEngine implements ContentFilterEngine {
  const UnavailableContentFilterEngine(this.engineName);

  final String engineName;

  UnsupportedError _unavailable() => UnsupportedError(
    'Content filter engine "$engineName" is not integrated in this build.',
  );

  @override
  Future<void> initialize() async => throw _unavailable();

  @override
  Future<FilterResult> shouldBlockRequest(FilterRequest request) async =>
      throw _unavailable();

  @override
  Future<FilterRules?> getCosmeticRules(Uri resource) async =>
      throw _unavailable();

  @override
  Future<void> dispose() async {}
}
