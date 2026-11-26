import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/theme/app_colors.dart';
import 'package:market_space/core/theme/app_spacing.dart';

/// Sleek, non-spinning 3-dot wave/pulse loader matching Deal One's design language.
/// Works seamlessly inside buttons, cards, and full-screen loading states.
class DealOneDotLoader extends StatefulWidget {
  final Color? color;
  final double dotSize;
  final double spacing;

  const DealOneDotLoader({
    super.key,
    this.color,
    this.dotSize = 9.0,
    this.spacing = 6.0,
  });

  @override
  State<DealOneDotLoader> createState() => _DealOneDotLoaderState();
}

class _DealOneDotLoaderState extends State<DealOneDotLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor = widget.color ??
        (AppColors.isDark(context)
            ? DealOneTokens.amberWarm
            : DealOneTokens.navy);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            final phase = (_controller.value - index * 0.18) % 1.0;
            final wave = math.sin(phase * math.pi * 2);
            final normalized = (wave + 1) / 2; // 0.0 -> 1.0
            final scale = 0.72 + (normalized * 0.42);
            final opacity = 0.35 + (normalized * 0.65);
            final dy = -normalized * (widget.dotSize * 0.45);

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: widget.spacing / 2),
              child: Transform.translate(
                offset: Offset(0, dy),
                child: Transform.scale(
                  scale: scale,
                  child: Opacity(
                    opacity: opacity,
                    child: Container(
                      width: widget.dotSize,
                      height: widget.dotSize,
                      decoration: BoxDecoration(
                        color: effectiveColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class AppLoadingIndicator extends StatelessWidget {
  final String? message;
  final double size;
  final Color? color;

  const AppLoadingIndicator({
    super.key,
    this.message,
    this.size = 36.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final dotSize = (size * 0.28).clamp(6.0, 14.0);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          DealOneDotLoader(
            color: color,
            dotSize: dotSize,
            spacing: dotSize * 0.65,
          ),
          if (message != null && message!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondaryOf(context),
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
