import 'package:web/web.dart' as web;

const _storageKey = 'voyager-learning.notes.v1';

String? readNotes() => web.window.localStorage.getItem(_storageKey);

void writeNotes(String value) =>
    web.window.localStorage.setItem(_storageKey, value);
