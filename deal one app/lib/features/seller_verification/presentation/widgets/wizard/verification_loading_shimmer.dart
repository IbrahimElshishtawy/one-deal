import 'package:flutter/material.dart';
import 'package:market_space/features/seller_verification/presentation/widgets/wizard/wizard_theme.dart';

/// Independent animated shimmer skeleton matching the 3-step Seller Verification layout
/// while initial account verification status & locations are loading.
class VerificationLoadingShimmer extends StatefulWidget {
  const VerificationLoadingShimmer({super.key});

  @override
  State<VerificationLoadingShimmer> createState() =>
      _VerificationLoadingShimmerState();
}

class _VerificationLoadingShimmerState extends State<VerificationLoadingShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1350),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = WizardTheme.isDark(context);
    final baseColor =
        isDark ? const Color(0xFF1E222B) : const Color(0xFFE9EEF5);
    final highlightColor =
        isDark ? const Color(0xFF2B313E) : const Color(0xFFF7FAFF);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = (_controller.value * 2) - 1;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(-1.0 + t, 0),
              end: Alignment(1.0 + t, 0),
              colors: [baseColor, highlightColor, baseColor],
              stops: const [0.1, 0.5, 0.9],
            ).createShader(bounds);
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: _box(width: 150, height: 32, radius: 999),
                ),
                const SizedBox(height: 14),
                _box(width: 220, height: 28, radius: 8),
                const SizedBox(height: 10),
                _box(width: double.infinity, height: 14, radius: 6),
                const SizedBox(height: 6),
                _box(width: 240, height: 14, radius: 6),
                const SizedBox(height: 24),
                for (var i = 0; i < 4; i++) ...[
                  _box(width: 140, height: 14, radius: 6),
                  const SizedBox(height: 8),
                  _box(width: double.infinity, height: 52, radius: 14),
                  const SizedBox(height: 16),
                ],
                _box(width: double.infinity, height: 82, radius: 16),
                const SizedBox(height: 20),
                _box(width: double.infinity, height: 54, radius: 14),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _box({
    required double width,
    required double height,
    required double radius,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
