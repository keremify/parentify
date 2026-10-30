import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class SoftCard extends StatelessWidget {
  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.margin,
    this.color = AppColors.paper,
    this.gradient,
    this.radius = 24,
    this.border,
    this.boxShadow,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color color;
  final Gradient? gradient;
  final double radius;
  final BoxBorder? border;
  final List<BoxShadow>? boxShadow;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final decoration = BoxDecoration(
      color: gradient == null ? color : null,
      gradient: gradient,
      borderRadius: BorderRadius.circular(radius),
      border:
          border ?? Border.all(color: AppColors.line.withValues(alpha: 0.8)),
      boxShadow: boxShadow,
    );

    final content = Padding(padding: padding, child: child);

    final card = Container(
      margin: margin,
      decoration: decoration,
      clipBehavior: Clip.antiAlias,
      child: onTap == null
          ? content
          : Material(
              color: Colors.transparent,
              child: InkWell(onTap: onTap, child: content),
            ),
    );

    return onTap == null ? card : Semantics(button: true, child: card);
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.padding = EdgeInsets.zero,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
                ],
              ],
            ),
          ),
          if (actionLabel != null)
            if (onAction != null)
              TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 48),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(actionLabel!),
                    const SizedBox(width: 2),
                    const Icon(Icons.arrow_forward_rounded, size: 15),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  actionLabel!,
                  style: const TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.subtle,
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class TrendChip extends StatelessWidget {
  const TrendChip({
    super.key,
    required this.change,
    this.onDark = false,
    this.positiveIsGood = false,
    this.iconOnly = false,
  });

  /// Signed ratio, e.g. 0.24 for +24%.
  final double change;
  final bool onDark;
  final bool positiveIsGood;
  final bool iconOnly;

  @override
  Widget build(BuildContext context) {
    final flat = change.abs() < 0.005;
    final isUp = change > 0;
    final good = positiveIsGood ? isUp : !isUp;

    final tint = flat
        ? AppColors.muted
        : good
        ? (onDark ? AppColors.mintBright : AppColors.good)
        : (onDark ? const Color(0xFFFFA991) : AppColors.coral);
    final background = onDark
        ? Colors.white.withValues(alpha: 0.12)
        : flat
        ? AppColors.parchment
        : good
        ? AppColors.mintSoft
        : AppColors.coralSoft;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: iconOnly ? 6 : 9, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!flat)
            Icon(
              isUp ? Icons.north_east_rounded : Icons.south_west_rounded,
              size: 12,
              color: tint,
            ),
          if (!flat) const SizedBox(width: 3),
          Text(
            formatSignedPercent(change, strings: context.strings),
            style: TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: tint,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class DemoPill extends StatelessWidget {
  const DemoPill({
    super.key,
    this.label,
    this.onDark = false,
    this.icon = Icons.auto_awesome_rounded,
  });

  final String? label;
  final bool onDark;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final color = onDark ? Colors.white : AppColors.violet;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: onDark
            ? Colors.white.withValues(alpha: 0.14)
            : AppColors.violetSoft,
        borderRadius: BorderRadius.circular(30),
        border: onDark
            ? Border.all(color: Colors.white.withValues(alpha: 0.18))
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label ?? context.strings.demo,
            style: TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: color,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = 48,
    this.background = AppColors.paper,
    this.color = AppColors.ink,
    this.tooltip,
    this.semanticLabel,
    this.showBadge = false,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final double size;
  final Color background;
  final Color color;
  final String? tooltip;
  final String? semanticLabel;
  final bool showBadge;

  @override
  Widget build(BuildContext context) {
    final label =
        semanticLabel ??
        tooltip ??
        (icon == Icons.close_rounded ? 'Close' : 'Button');
    final target = size < 48 ? 48.0 : size;

    final visual = Material(
      color: background,
      shape: const CircleBorder(side: BorderSide(color: AppColors.line)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        excludeFromSemantics: true,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(icon, size: size * 0.44, color: color),
              if (showBadge)
                Positioned(
                  top: size * 0.26,
                  right: size * 0.28,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: AppColors.coral,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.paper, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    return Semantics(
      button: true,
      label: label,
      onTap: onPressed,
      child: Tooltip(
        message: tooltip ?? label,
        excludeFromSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onPressed,
          child: SizedBox(
            width: target,
            height: target,
            child: Center(child: visual),
          ),
        ),
      ),
    );
  }
}

class SmallAvatar extends StatelessWidget {
  const SmallAvatar({
    super.key,
    required this.initials,
    required this.color,
    this.size = 40,
  });

  final String initials;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, Color.lerp(color, Colors.white, 0.32)!],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.7),
          width: 1.5,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          fontFamily: 'PlusJakartaSans',
          color: Colors.white,
          fontSize: size * 0.34,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
      ),
    );
  }
}

class IconBubble extends StatelessWidget {
  const IconBubble({
    super.key,
    required this.icon,
    required this.color,
    this.size = 42,
    this.iconSize,
    this.radius = 14,
    this.background,
  });

  final IconData icon;
  final Color color;
  final double size;
  final double? iconSize;
  final double radius;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background ?? color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(radius),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: color, size: iconSize ?? size * 0.48),
    );
  }
}
