import 'package:flutter/material.dart';

import 'design_tokens.dart';

class BrutalistButton extends StatefulWidget {
  const BrutalistButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.secondary = false,
    this.expand = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool secondary;
  final bool expand;

  @override
  State<BrutalistButton> createState() => _BrutalistButtonState();
}

class _BrutalistButtonState extends State<BrutalistButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final background = widget.secondary
        ? context.surfaceColor
        : (context.isDarkMode
              ? DesignTokens.darkYellow
              : DesignTokens.pompeianRed);
    final foreground = widget.secondary
        ? context.inkColor
        : (context.isDarkMode ? DesignTokens.ink : DesignTokens.white);

    return Semantics(
      button: true,
      enabled: widget.onPressed != null,
      child: GestureDetector(
        onTapDown: widget.onPressed == null
            ? null
            : (_) => setState(() => _pressed = true),
        onTapUp: widget.onPressed == null
            ? null
            : (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          constraints: const BoxConstraints(
            minHeight: DesignTokens.minTapTarget,
          ),
          transform: Matrix4.translationValues(
            _pressed ? 1 : 0,
            _pressed ? 1 : 0,
            0,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.space4,
            vertical: DesignTokens.space2,
          ),
          decoration: BoxDecoration(
            color: widget.onPressed == null
                ? background.withValues(alpha: 0.45)
                : background,
            border: Border.all(
              color: widget.secondary ? context.outlineColor : background,
              width: DesignTokens.border,
            ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: _pressed
                ? const []
                : [
                    BoxShadow(
                      color: context.hardShadowColor.withValues(alpha: 0.1),
                      blurRadius: DesignTokens.shadowSmall,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 18, color: foreground),
                const SizedBox(width: DesignTokens.space2),
              ],
              Text(
                widget.label.toUpperCase(),
                style: Theme.of(context).textTheme.labelLarge
                    ?.copyWith(color: foreground, fontWeight: FontWeight.w800),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BrutalistIconButton extends StatelessWidget {
  const BrutalistIconButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.active = false,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          child: Container(
            constraints: const BoxConstraints(
              minWidth: DesignTokens.minTapTarget,
              minHeight: DesignTokens.minTapTarget,
            ),
            decoration: BoxDecoration(
              color: active ? context.accentColor : context.surfaceColor,
              border: Border.all(
                color: context.outlineColor,
                width: DesignTokens.border,
              ),
              borderRadius: BorderRadius.circular(DesignTokens.radius),
            ),
            child: Icon(icon, color: context.inkColor),
          ),
        ),
      ),
    );
  }
}

class BrutalistCard extends StatelessWidget {
  const BrutalistCard({
    required this.child,
    this.padding = const EdgeInsets.all(DesignTokens.space4),
    this.color,
    this.shadow = true,
    this.onTap,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final bool shadow;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? context.surfaceColor,
        border: Border.all(
          color: context.outlineColor,
          width: DesignTokens.border,
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radius),
        boxShadow: shadow
            ? [
                BoxShadow(
                  color: context.hardShadowColor.withValues(alpha: 0.08),
                  blurRadius: DesignTokens.shadowMedium,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: child,
    );

    if (onTap == null) return card;
    return Semantics(
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(DesignTokens.radius),
          onTap: onTap,
          child: card,
        ),
      ),
    );
  }
}

class BrutalistSectionHeader extends StatelessWidget {
  const BrutalistSectionHeader({required this.title, this.trailing, super.key});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: context.isDarkMode
                  ? DesignTokens.darkText
                  : DesignTokens.romanOlive,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        trailing ?? const SizedBox.shrink(),
      ],
    );
  }
}

class BrutalistChip extends StatelessWidget {
  const BrutalistChip({
    required this.label,
    this.selected = false,
    this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final chip = Container(
      constraints: BoxConstraints(
        minHeight: onTap == null ? 36 : DesignTokens.minTapTarget,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.space3,
        vertical: DesignTokens.space2,
      ),
      decoration: BoxDecoration(
        color: selected ? context.accentColor : context.surfaceColor,
        border: Border.all(
          color: context.outlineColor,
          width: DesignTokens.border,
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: context.inkColor, fontWeight: FontWeight.w800),
      ),
    );
    if (onTap == null) return chip;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(onTap: onTap, child: chip),
    );
  }
}

class BrutalistProgressBar extends StatelessWidget {
  const BrutalistProgressBar({required this.value, this.label, super.key})
    : assert(value >= 0 && value <= 1);

  final double value;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final percentage = (value * 100).round();
    return Semantics(
      label: label ?? 'Progress',
      value: '$percentage percent',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (label != null)
                Text(label!, style: Theme.of(context).textTheme.labelMedium),
              Text(
                '$percentage%',
                style: Theme.of(context).textTheme.labelMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.space2),
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: context.raisedColor,
              borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: value,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: context.accentColor,
                    borderRadius: BorderRadius.circular(
                      DesignTokens.radiusPill,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BrutalistSearchField extends StatelessWidget {
  const BrutalistSearchField({
    required this.controller,
    required this.hint,
    this.onChanged,
    super.key,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: context.surfaceColor,
        constraints: const BoxConstraints(minHeight: 52),
        contentPadding: const EdgeInsets.all(DesignTokens.space3),
        border: OutlineInputBorder(
          borderSide: BorderSide(color: context.outlineColor),
          borderRadius: BorderRadius.circular(8),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: context.outlineColor),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: context.blueAccentColor, width: 1.5),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

class BrutalistInput extends StatelessWidget {
  const BrutalistInput({
    required this.controller,
    required this.hint,
    this.label,
    this.minLines = 1,
    this.maxLines = 1,
    this.onChanged,
    super.key,
  }) : assert(maxLines >= minLines);

  final TextEditingController controller;
  final String hint;
  final String? label;
  final int minLines;
  final int maxLines;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      minLines: minLines,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: context.surfaceColor,
        alignLabelWithHint: maxLines > 1,
        contentPadding: const EdgeInsets.all(DesignTokens.space3),
        border: OutlineInputBorder(
          borderSide: BorderSide(color: context.outlineColor),
          borderRadius: BorderRadius.circular(8),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: context.outlineColor),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: context.blueAccentColor, width: 1.5),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

class BrutalistCheckbox extends StatelessWidget {
  const BrutalistCheckbox({
    required this.label,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      checked: value,
      label: label,
      child: InkWell(
        onTap: () => onChanged(!value),
        child: Container(
          constraints: const BoxConstraints(
            minHeight: DesignTokens.minTapTarget,
          ),
          padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space2),
          decoration: BoxDecoration(
            color: context.surfaceColor,
            border: Border.all(
              color: context.outlineColor,
              width: DesignTokens.border,
            ),
            borderRadius: BorderRadius.circular(DesignTokens.radius),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Checkbox(
                value: value,
                onChanged: (next) => onChanged(next ?? false),
              ),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }
}

class BrutalistEmptyState extends StatelessWidget {
  const BrutalistEmptyState({
    required this.title,
    required this.message,
    this.action,
    super.key,
  });

  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return BrutalistCard(
      color: context.raisedColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: DesignTokens.space2),
          Text(message, style: Theme.of(context).textTheme.bodyMedium),
          if (action != null) ...[
            const SizedBox(height: DesignTokens.space4),
            action!,
          ],
        ],
      ),
    );
  }
}

Future<T?> showBrutalistDialog<T>({
  required BuildContext context,
  required String title,
  required Widget content,
  required List<Widget> actions,
}) {
  return showDialog<T>(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(DesignTokens.space4),
      child: BrutalistCard(
        color: context.surfaceColor,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: DesignTokens.space3),
            content,
            const SizedBox(height: DesignTokens.space4),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: DesignTokens.space2,
              runSpacing: DesignTokens.space2,
              children: actions,
            ),
          ],
        ),
      ),
    ),
  );
}

Future<T?> showBrutalistBottomSheet<T>({
  required BuildContext context,
  required Widget child,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.pageColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => SafeArea(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(DesignTokens.space4),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: context.outlineColor)),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: child,
      ),
    ),
  );
}

class BrutalistLoadingState extends StatelessWidget {
  const BrutalistLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        label: 'Loading study materials',
        child: SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(strokeWidth: 3),
        ),
      ),
    );
  }
}

class BrutalistErrorState extends StatelessWidget {
  const BrutalistErrorState({
    required this.message,
    required this.onRetry,
    super.key,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return BrutalistEmptyState(
      title: 'Could not load',
      message: message,
      action: BrutalistButton(
        label: 'Try again',
        icon: Icons.refresh,
        onPressed: onRetry,
      ),
    );
  }
}

class BrutalistListItem extends StatelessWidget {
  const BrutalistListItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.trailing,
    this.onTap,
    super.key,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return BrutalistCard(
      padding: const EdgeInsets.all(DesignTokens.space3),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: context.isDarkMode
                  ? DesignTokens.darkBackground
                  : DesignTokens.romanOlive,
              borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
            ),
            child: Icon(
              icon,
              color: context.isDarkMode
                  ? DesignTokens.parchment
                  : DesignTokens.white,
            ),
          ),
          const SizedBox(width: DesignTokens.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: DesignTokens.space1),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: context.mutedColor),
                ),
              ],
            ),
          ),
          trailing ?? const SizedBox.shrink(),
        ],
      ),
    );
  }
}
