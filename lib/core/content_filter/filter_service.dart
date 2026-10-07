import '../config/app_config.dart';
import 'filter_engine.dart';
import 'filter_result.dart';
import 'filter_rules.dart';

class ContentFilterService {
  const ContentFilterService({required this.config, required this.engine});

  final AppConfig config;
  final ContentFilterEngine engine;

  Future<void> initialize() async {
    if (config.contentFilteringEnabled) await engine.initialize();
  }

  Future<FilterResult> shouldBlockRequest(FilterRequest request) async {
    if (!config.contentFilteringEnabled) {
      return const FilterResult.allow(reason: 'Filtering is disabled.');
    }
    if (request.scope != FilterRequestScope.applicationManaged) {
      return const FilterResult.allow(
        reason: 'Request is outside filter scope.',
      );
    }
    return engine.shouldBlockRequest(request);
  }

  Future<FilterRules?> getCosmeticRules(Uri resource) async {
    if (!config.contentFilteringEnabled) return null;
    return engine.getCosmeticRules(resource);
  }

  Future<void> dispose() async {
    if (config.contentFilteringEnabled) await engine.dispose();
  }
}
