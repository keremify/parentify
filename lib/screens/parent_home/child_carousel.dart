import 'package:flutter/material.dart';

import '../../models/child.dart';
import '../../widgets/child_selector_card.dart';

class ChildCarousel extends StatelessWidget {
  const ChildCarousel({
    super.key,
    required this.children,
    required this.gutter,
    required this.onTap,
  });

  final List<Child> children;
  final double gutter;
  final ValueChanged<Child> onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        if (width > 620) {
          final cardWidth = (width - gutter * 2 - 14) / 2;
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: gutter),
            child: Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                for (final child in children)
                  SizedBox(
                    width: cardWidth,
                    child: ChildSelectorCard(
                      child: child,
                      onTap: () => onTap(child),
                    ),
                  ),
              ],
            ),
          );
        }

        final cardWidth = (width * 0.86).clamp(270.0, 330.0);
        return SizedBox(
          height: 196,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: gutter),
            physics: const BouncingScrollPhysics(),
            itemCount: children.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final child = children[index];
              return SizedBox(
                width: cardWidth,
                child: ChildSelectorCard(
                  child: child,
                  onTap: () => onTap(child),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
