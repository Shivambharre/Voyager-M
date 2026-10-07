import 'package:flutter/services.dart';

import 'filter_engine.dart';
import 'filter_result.dart';
import 'filter_rules.dart';

class NativeFilterBridge implements ContentFilterEngine {
  NativeFilterBridge({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('voyager/content_filter');

  final MethodChannel _channel;

  @override
  Future<void> initialize() async {
    await _channel.invokeMethod<void>('initialize');
  }

  @override
  Future<FilterResult> shouldBlockRequest(FilterRequest request) async {
    if (request.scope != FilterRequestScope.applicationManaged) {
      return const FilterResult.allow(
        reason: 'Request is outside filter scope.',
      );
    }
    final blocked =
        await _channel.invokeMethod<bool>('shouldBlockRequest', {
          'url': request.url.toString(),
          'resourceType': request.resourceType,
          'sourceUrl': request.sourceUrl?.toString(),
        }) ??
        false;
    return blocked
        ? const FilterResult.block(
            reason: 'Blocked by configured filter rules.',
          )
        : const FilterResult.allow();
  }

  @override
  Future<FilterRules?> getCosmeticRules(Uri resource) async {
    final result = await _channel.invokeMapMethod<String, Object?>(
      'getCosmeticRules',
      {'url': resource.toString()},
    );
    if (result == null) return null;
    final name = result['name'];
    final text = result['text'];
    if (name is! String || text is! String) return null;
    return FilterRules(name: name, text: text);
  }

  @override
  Future<void> dispose() async {
    await _channel.invokeMethod<void>('dispose');
  }
}
