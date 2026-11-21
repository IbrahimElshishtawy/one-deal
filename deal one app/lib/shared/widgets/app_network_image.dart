import 'package:flutter/material.dart';

import 'package:market_space/core/theme/app_colors.dart';

/// Professional Image Loading Component for Market Space.
/// Features:
/// 1. Smooth Grayscale Shimmer / Skeleton Placeholder (No layout shift)
/// 2. Smooth Fade Transition on success
/// 3. Resilient Error & Offline Fallback with optional Retry
/// 4. Strict Monochrome styling (No random colored spinners)
/// 5. Safe URL handling (handles empty/malformed URLs without crashing)
class AppNetworkImage extends StatefulWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final BoxShape shape;
  final double? aspectRatio;
  final IconData fallbackIcon;
  final Widget? placeholder;
  final Widget? errorWidget;
  final bool enableRetry;
  final VoidCallback? onRetry;
  final String? semanticLabel;

  const AppNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.shape = BoxShape.rectangle,
    this.aspectRatio,
    this.fallbackIcon = Icons.image_outlined,
    this.placeholder,
    this.errorWidget,
    this.enableRetry = false,
    this.onRetry,
    this.semanticLabel,
  });

  @override
  State<AppNetworkImage> createState() => _AppNetworkImageState();
}

class _AppNetworkImageState extends State<AppNetworkImage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerController;
  int _retryKey = 0;
  bool _isLoaded = false;

  static String _optimizeUrl(String url, {double? width}) {
    final trimmed = url.trim();
    if (trimmed.contains('images.unsplash.com') && !trimmed.contains('w=')) {
      final sep = trimmed.contains('?') ? '&' : '?';
      final targetW = (width != null && width > 0)
          ? (width * 2.5).clamp(300, 900).toInt()
          : 600;
      return '$trimmed${sep}auto=format&fit=crop&w=$targetW&q=80';
    }
    return trimmed;
  }

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    final isTest = WidgetsBinding.instance.runtimeType.toString().toLowerCase().contains('test') ||
        WidgetsBinding.instance is! WidgetsFlutterBinding;
    if (!isTest) {
      _shimmerController.repeat();
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  void _handleRetry() {
    setState(() {
      _isLoaded = false;
      _retryKey++;
    });
    if (!_shimmerController.isAnimating) {
      _shimmerController.repeat();
    }
    widget.onRetry?.call();
  }

  @override
  Widget build(BuildContext context) {
    final rawUrl = widget.imageUrl?.trim();

    Widget content;
    if (rawUrl == null || rawUrl.isEmpty) {
      content = _buildErrorFallback();
    } else {
      final optimizedUrl = _optimizeUrl(rawUrl, width: widget.width);
      final cacheW = (widget.width != null && widget.width! > 0)
          ? (widget.width! * 2.5).clamp(200, 1000).toInt()
          : (widget.height != null && widget.height! > 0 ? null : 600);
      final cacheH = (widget.height != null && widget.height! > 0)
          ? (widget.height! * 2.5).clamp(200, 1000).toInt()
          : null;

      content = Image.network(
        optimizedUrl,
        key: ValueKey('${optimizedUrl}_$_retryKey'),
        width: widget.width,
        height: widget.height,
        cacheWidth: cacheW,
        cacheHeight: cacheH,
        fit: widget.fit,
        semanticLabel: widget.semanticLabel,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded || frame != null) {
            if (!_isLoaded) {
              _isLoaded = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && _shimmerController.isAnimating) {
                  _shimmerController.stop();
                }
              });
            }
            return child;
          }
          return widget.placeholder ?? _buildShimmerSkeleton();
        },
        errorBuilder: (context, error, stackTrace) {
          if (_shimmerController.isAnimating) {
            _shimmerController.stop();
          }
          return widget.errorWidget ?? _buildErrorFallback();
        },
      );
    }

    if (widget.shape == BoxShape.circle) {
      content = ClipOval(child: content);
    } else if (widget.borderRadius != null) {
      content = ClipRRect(
        borderRadius: widget.borderRadius!,
        child: content,
      );
    }

    if (widget.aspectRatio != null) {
      content = AspectRatio(
        aspectRatio: widget.aspectRatio!,
        child: content,
      );
    }

    return content;
  }

  Widget _buildShimmerSkeleton() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-1.5 + (_shimmerController.value * 3.0), -0.3),
              end: Alignment(0.5 + (_shimmerController.value * 3.0), 0.3),
              colors: isDark
                  ? const [
                      AppColors.darkSurfaceSecondary,
                      AppColors.darkSurfaceTertiary,
                      AppColors.darkSurfaceSecondary,
                    ]
                  : const [
                      AppColors.surfaceSecondary,
                      AppColors.surfaceTertiary,
                      AppColors.surfaceSecondary,
                    ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorFallback() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: widget.width,
      height: widget.height,
      color: isDark ? AppColors.darkSurfaceSecondary : AppColors.surfaceSecondary,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxDim = constraints.biggest.shortestSide;
          if (maxDim.isFinite && maxDim < 28.0) {
            return Center(
              child: Icon(
                widget.fallbackIcon,
                size: (maxDim * 0.75).clamp(8.0, 16.0),
                color: isDark ? AppColors.darkIconSecondary : AppColors.iconSecondary,
              ),
            );
          }
          final isSmall = (widget.height != null && widget.height! < 60) || (maxDim.isFinite && maxDim < 60);
          return Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      widget.fallbackIcon,
                      size: isSmall ? 18.0 : 28.0,
                      color: isDark ? AppColors.darkIconSecondary : AppColors.iconSecondary,
                    ),
                    if (widget.enableRetry && (!maxDim.isFinite || maxDim >= 60)) ...[
                      const SizedBox(height: 4.0),
                      InkWell(
                        onTap: _handleRetry,
                        borderRadius: BorderRadius.circular(16.0),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.refresh_rounded,
                                size: 14.0,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 2.0),
                              Text(
                                'إعادة المحاولة',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
