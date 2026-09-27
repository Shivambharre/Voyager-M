import 'package:flutter/material.dart';

import '../../../core/design/brutalist_components.dart';
import '../../../core/design/design_tokens.dart';

class LearningPlayerScreen extends StatefulWidget {
  const LearningPlayerScreen({super.key});

  @override
  State<LearningPlayerScreen> createState() => _LearningPlayerScreenState();
}

class _LearningPlayerScreenState extends State<LearningPlayerScreen> {
  bool _isPlaying = false;
  bool _isSaved = false;
  double _position = 0.12;
  double _speed = 1;
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FOCUSED STUDY'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(DesignTokens.borderStrong),
          child: Container(height: DesignTokens.borderStrong, color: context.outlineColor),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(DesignTokens.space4),
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Semantics(
              label: 'Mock video player area',
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF111111),
                  border: Border.all(color: context.outlineColor, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: context.hardShadowColor,
                      offset: const Offset(DesignTokens.shadowSmall, DesignTokens.shadowSmall),
                    ),
                  ],
                ),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.ondemand_video, color: Colors.white, size: 48),
                      SizedBox(height: DesignTokens.space2),
                      Text(
                        'PLAYER PREVIEW',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: DesignTokens.space5),
          Text('Gradient Descent, Clearly Explained', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: DesignTokens.space1),
          Text(
            'STATQUEST  ·  MACHINE LEARNING / FOUNDATIONS',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: context.mutedColor),
          ),
          const SizedBox(height: DesignTokens.space4),
          Slider(
            value: _position,
            onChanged: (value) => setState(() => _position = value),
            semanticFormatterCallback: (value) => '${(value * 18.7).toStringAsFixed(1)} minutes',
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_formatTime((_position * 1122).round()), style: Theme.of(context).textTheme.labelSmall),
              Text('18:42', style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
          const SizedBox(height: DesignTokens.space3),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              BrutalistIconButton(
                icon: Icons.replay_10,
                label: 'Seek back ten seconds',
                onPressed: () => setState(() => _position = (_position - 0.01).clamp(0, 1)),
              ),
              const SizedBox(width: DesignTokens.space3),
              BrutalistButton(
                label: _isPlaying ? 'Pause' : 'Play',
                icon: _isPlaying ? Icons.pause : Icons.play_arrow,
                onPressed: () => setState(() => _isPlaying = !_isPlaying),
              ),
              const SizedBox(width: DesignTokens.space3),
              BrutalistIconButton(
                icon: Icons.forward_10,
                label: 'Seek forward ten seconds',
                onPressed: () => setState(() => _position = (_position + 0.01).clamp(0, 1)),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.space4),
          Wrap(
            spacing: DesignTokens.space2,
            runSpacing: DesignTokens.space2,
            alignment: WrapAlignment.center,
            children: [
              BrutalistButton(
                label: '${_speed.toStringAsFixed(1)}× speed',
                icon: Icons.speed,
                secondary: true,
                onPressed: _cycleSpeed,
              ),
              BrutalistButton(
                label: 'Add note',
                icon: Icons.edit_note,
                secondary: true,
                onPressed: () => _noteController.text = '${_formatTime((_position * 1122).round())} ',
              ),
              BrutalistButton(
                label: _isSaved ? 'Saved' : 'Save moment',
                icon: _isSaved ? Icons.bookmark : Icons.bookmark_border,
                secondary: true,
                onPressed: () => setState(() => _isSaved = !_isSaved),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.space6),
          const BrutalistSectionHeader(title: 'Notes for this lesson'),
          const SizedBox(height: DesignTokens.space3),
          BrutalistCard(
            padding: const EdgeInsets.all(DesignTokens.space3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('12:42  /  NEURAL NETWORKS', style: Theme.of(context).textTheme.labelSmall),
                const SizedBox(height: DesignTokens.space2),
                const Text('Gradient descent minimizes the cost function by iteratively updating parameters.'),
              ],
            ),
          ),
          const SizedBox(height: DesignTokens.space3),
          BrutalistInput(
            controller: _noteController,
            hint: 'Write a note at this moment...',
            minLines: 2,
            maxLines: 4,
          ),
        ],
      ),
    );
  }

  void _cycleSpeed() {
    setState(() {
      _speed = switch (_speed) {
        1 => 1.25,
        1.25 => 1.5,
        1.5 => 2,
        _ => 1,
      };
    });
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}
