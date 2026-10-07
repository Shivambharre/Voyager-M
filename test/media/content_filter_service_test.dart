import 'package:flutter_test/flutter_test.dart';
import 'package:voyager_learning/core/config/app_config.dart';
import 'package:voyager_learning/core/content_filter/filter_engine.dart';
import 'package:voyager_learning/core/content_filter/filter_result.dart';
import 'package:voyager_learning/core/content_filter/filter_service.dart';
import 'package:voyager_learning/core/content_filter/filter_rules.dart';

void main() {
  test(
    'disabled filtering always allows without initializing engine',
    () async {
      final engine = _RecordingEngine();
      final service = ContentFilterService(
        config: const AppConfig(contentFilteringEnabled: false),
        engine: engine,
      );
      await service.initialize();
      final result = await service.shouldBlockRequest(
        FilterRequest(
          url: Uri.parse('https://ads.example/resource'),
          resourceType: 'script',
          scope: FilterRequestScope.applicationManaged,
        ),
      );

      expect(result.shouldBlock, isFalse);
      expect(engine.initialized, isFalse);
      expect(engine.requestCount, 0);
    },
  );

  test('never sends YouTube player requests to the filter engine', () async {
    final engine = _RecordingEngine();
    final service = ContentFilterService(
      config: const AppConfig(contentFilteringEnabled: true),
      engine: engine,
    );
    await service.initialize();
    final result = await service.shouldBlockRequest(
      FilterRequest(
        url: Uri.parse('https://www.youtube.com/api/player'),
        resourceType: 'xmlhttprequest',
        scope: FilterRequestScope.youtubePlayer,
      ),
    );

    expect(result.shouldBlock, isFalse);
    expect(engine.requestCount, 0);
  });

  test('forwards only application-managed requests when enabled', () async {
    final engine = _RecordingEngine()..blockRequests = true;
    final service = ContentFilterService(
      config: const AppConfig(contentFilteringEnabled: true),
      engine: engine,
    );
    await service.initialize();
    final result = await service.shouldBlockRequest(
      FilterRequest(
        url: Uri.parse('https://assets.example/tracker'),
        resourceType: 'image',
        scope: FilterRequestScope.applicationManaged,
      ),
    );

    expect(result.shouldBlock, isTrue);
    expect(engine.requestCount, 1);
  });

  test('fails explicitly when an unintegrated engine is selected', () async {
    final service = ContentFilterService(
      config: const AppConfig(
        contentFilteringEnabled: true,
        filterEngine: 'adblock-rust',
      ),
      engine: const UnavailableContentFilterEngine('adblock-rust'),
    );

    await expectLater(service.initialize(), throwsUnsupportedError);
  });
}

class _RecordingEngine implements ContentFilterEngine {
  bool initialized = false;
  bool blockRequests = false;
  int requestCount = 0;

  @override
  Future<void> initialize() async {
    initialized = true;
  }

  @override
  Future<FilterResult> shouldBlockRequest(FilterRequest request) async {
    requestCount++;
    return blockRequests
        ? const FilterResult.block()
        : const FilterResult.allow();
  }

  @override
  Future<FilterRules?> getCosmeticRules(Uri resource) async => null;

  @override
  Future<void> dispose() async {}
}
