import 'package:flutter/services.dart';

abstract interface class SharedVideoIntentSource {
  Stream<String> get sharedTexts;
}

class AndroidSharedVideoIntentSource implements SharedVideoIntentSource {
  AndroidSharedVideoIntentSource() {
    _sharedTexts = _channel
        .receiveBroadcastStream()
        .where((text) => text is String)
        .cast<String>();
  }

  static const _channel = EventChannel('com.voyager/share');

  late final Stream<String> _sharedTexts;

  @override
  Stream<String> get sharedTexts => _sharedTexts;
}
