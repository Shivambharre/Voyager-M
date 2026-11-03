import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

class NoteTableEmbedBuilder extends EmbedBuilder {
  const NoteTableEmbedBuilder({required this.onEdit});

  static const embedName = 'note_table';

  final Future<void> Function(EmbedContext context) onEdit;

  @override
  String get key => BlockEmbed.customType;

  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    try {
      final custom = CustomBlockEmbed.fromJsonString(
        embedContext.node.value.data as String,
      );
      if (custom.type != embedName) {
        return const SizedBox.shrink();
      }
      final rows = (jsonDecode(custom.data as String) as List)
          .map((row) => (row as List).map((cell) => cell.toString()).toList())
          .toList();
      return GestureDetector(
        onTap: embedContext.readOnly ? null : () => onEdit(embedContext),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Table(
            defaultColumnWidth: const IntrinsicColumnWidth(),
            border: TableBorder.all(color: Theme.of(context).dividerColor),
            children: [
              for (final row in rows)
                TableRow(
                  children: [
                    for (final cell in row)
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(cell.isEmpty ? ' ' : cell),
                      ),
                  ],
                ),
            ],
          ),
        ),
      );
    } on Object {
      return const Text('Table could not be displayed.');
    }
  }

  @override
  String toPlainText(Embed node) {
    try {
      final custom = CustomBlockEmbed.fromJsonString(node.value.data as String);
      if (custom.type != embedName) return '';
      final rows = jsonDecode(custom.data as String) as List;
      return rows
          .map((row) => (row as List).map((cell) => cell.toString()).join(' '))
          .join('\n');
    } on Object {
      return '';
    }
  }
}

Future<List<List<String>>?> showNoteTableDialog(
  BuildContext context, {
  List<List<String>>? initialRows,
}) async {
  final rows = initialRows == null
      ? [
          ['', ''],
          ['', ''],
        ]
      : initialRows.map(List<String>.of).toList();
  final controllers = <TextEditingController>[
    for (final row in rows)
      for (final cell in row) TextEditingController(text: cell),
  ];
  try {
    return await showDialog<List<List<String>>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit table'),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var row = 0; row < rows.length; row++)
                    Row(
                      children: [
                        for (
                          var column = 0;
                          column < rows[row].length;
                          column++
                        )
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(3),
                              child: TextField(
                                controller:
                                    controllers[row * rows[row].length +
                                        column],
                                decoration: InputDecoration(
                                  border: const OutlineInputBorder(),
                                  hintText: 'Cell',
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  TextButton.icon(
                    onPressed: () => setState(() {
                      rows.add(List<String>.filled(rows.first.length, ''));
                      controllers.addAll(
                        List.generate(
                          rows.first.length,
                          (_) => TextEditingController(),
                        ),
                      );
                    }),
                    icon: const Icon(Icons.add),
                    label: const Text('Add row'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final columns = rows.first.length;
                Navigator.pop(context, [
                  for (var row = 0; row < rows.length; row++)
                    [
                      for (var column = 0; column < columns; column++)
                        controllers[row * columns + column].text,
                    ],
                ]);
              },
              child: const Text('Save table'),
            ),
          ],
        ),
      ),
    );
  } finally {
    for (final controller in controllers) {
      controller.dispose();
    }
  }
}
