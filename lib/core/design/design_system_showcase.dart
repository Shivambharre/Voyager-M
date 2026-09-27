import 'package:flutter/material.dart';

import 'brutalist_components.dart';
import 'design_tokens.dart';

class DesignSystemShowcase extends StatefulWidget {
  const DesignSystemShowcase({super.key});

  @override
  State<DesignSystemShowcase> createState() => _DesignSystemShowcaseState();
}

class _DesignSystemShowcaseState extends State<DesignSystemShowcase> {
  final _searchController = TextEditingController();
  bool _checked = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DESIGN SYSTEM')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(DesignTokens.space4),
          children: [
            Text(
              'NEO-BRUTALIST V1.0',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: context.mutedColor,
                  ),
            ),
            const SizedBox(height: DesignTokens.space5),
            const BrutalistSectionHeader(title: 'Color palette'),
            const SizedBox(height: DesignTokens.space3),
            Wrap(
              spacing: DesignTokens.space2,
              runSpacing: DesignTokens.space2,
              children: [
                _ColorSwatch(name: 'Paper', color: context.pageColor),
                _ColorSwatch(name: 'Ink', color: context.inkColor),
                _ColorSwatch(name: 'Electric yellow', color: context.accentColor),
                _ColorSwatch(name: 'Bright blue', color: context.blueAccentColor),
              ],
            ),
            const SizedBox(height: DesignTokens.space5),
            const BrutalistSectionHeader(title: 'Typography'),
            const SizedBox(height: DesignTokens.space3),
            BrutalistCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Headline large', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: DesignTokens.space2),
                  Text('Title medium bold', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: DesignTokens.space2),
                  Text('Body medium regular', style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: DesignTokens.space2),
                  Text(
                    'METADATA MONOSPACE STYLE',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontFamily: 'monospace',
                          color: context.mutedColor,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: DesignTokens.space5),
            const BrutalistSectionHeader(title: 'Buttons & chips'),
            const SizedBox(height: DesignTokens.space3),
            Wrap(
              spacing: DesignTokens.space3,
              runSpacing: DesignTokens.space3,
              children: [
                BrutalistButton(
                  label: 'Start learning',
                  icon: Icons.play_arrow,
                  onPressed: () => _showMessage(context, 'Primary action pressed'),
                ),
                BrutalistButton(
                  label: 'Add material',
                  icon: Icons.add,
                  secondary: true,
                  onPressed: () => _showMessage(context, 'Secondary action pressed'),
                ),
                const BrutalistChip(label: 'In progress', selected: true),
                const BrutalistChip(label: 'Saved'),
              ],
            ),
            const SizedBox(height: DesignTokens.space5),
            const BrutalistSectionHeader(title: 'Cards & progress'),
            const SizedBox(height: DesignTokens.space3),
            BrutalistCard(
              color: context.accentColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ACTIVE ROADMAP', style: Theme.of(context).textTheme.labelMedium),
                  const SizedBox(height: DesignTokens.space2),
                  Text('Learning foundations', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: DesignTokens.space4),
                  const BrutalistProgressBar(value: 0.68, label: '4 OF 6 TOPICS'),
                ],
              ),
            ),
            const SizedBox(height: DesignTokens.space5),
            const BrutalistSectionHeader(title: 'Input & selection'),
            const SizedBox(height: DesignTokens.space3),
            BrutalistSearchField(
              controller: _searchController,
              hint: 'Search your learning library',
            ),
            const SizedBox(height: DesignTokens.space2),
            BrutalistCard(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.space3,
                vertical: DesignTokens.space2,
              ),
              child: Row(
                children: [
                  const Expanded(child: Text('Use dark appearance')),
                  Semantics(
                    label: 'Use dark appearance',
                    child: Switch(
                      value: _checked,
                      onChanged: (value) => setState(() => _checked = value),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: DesignTokens.space2),
            BrutalistCheckbox(
              label: 'Mark as important',
              value: _checked,
              onChanged: (value) => setState(() => _checked = value),
            ),
            const SizedBox(height: DesignTokens.space5),
            const BrutalistSectionHeader(title: 'States'),
            const SizedBox(height: DesignTokens.space3),
            const BrutalistEmptyState(
              title: 'Nothing saved yet',
              message: 'Save a useful moment while studying and it will appear here.',
            ),
            const SizedBox(height: DesignTokens.space3),
            const BrutalistCard(
              shadow: false,
              child: Row(
                children: [
                  Icon(Icons.info_outline),
                  SizedBox(width: DesignTokens.space2),
                  Expanded(child: Text('A quiet, simple loading state.')),
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              ),
            ),
            const SizedBox(height: DesignTokens.space3),
            BrutalistErrorState(
              message: 'The saved study material is unavailable right now.',
              onRetry: () => _showMessage(context, 'Retry requested'),
            ),
          ],
        ),
      ),
    );
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 1)),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({required this.name, required this.color});

  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return BrutalistCard(
      padding: const EdgeInsets.all(DesignTokens.space2),
      shadow: false,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: color,
              border: Border.all(color: context.outlineColor, width: 2),
            ),
          ),
          const SizedBox(width: DesignTokens.space2),
          Text(name, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}
