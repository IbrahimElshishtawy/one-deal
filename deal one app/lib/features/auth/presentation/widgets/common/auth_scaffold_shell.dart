import 'package:flutter/material.dart';

import 'package:market_space/features/auth/presentation/theme/auth_design_tokens.dart';

/// Compact, standardized 44px top utility bar shared across auth screens so
/// the Deal One logo header stays vertically aligned across transitions.
class AuthTopBar extends StatelessWidget {
  final VoidCallback? onBack;
  final Widget? trailing;

  const AuthTopBar({super.key, this.onBack, this.trailing});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AuthDesignTokens.topBarHeight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (onBack != null)
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 40, height: 40),
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 19,
                color: AuthDesignTokens.headingOf(context),
              ),
              onPressed: onBack,
            )
          else
            const SizedBox(width: 40, height: 40),
          if (trailing != null) trailing! else const SizedBox(width: 40),
        ],
      ),
    );
  }
}

/// Responsive centered RTL/LTR shell shared across all authentication pages.
/// Supports optional [footer] pinned cleanly to the bottom on tall viewports
/// while scrolling smoothly when the soft keyboard opens.
class AuthScaffoldShell extends StatelessWidget {
  final Widget child;
  final Widget? footer;
  final PreferredSizeWidget? appBar;
  final Widget? bottomBar;
  final EdgeInsetsGeometry? padding;
  final bool centerVertically;

  const AuthScaffoldShell({
    super.key,
    required this.child,
    this.footer,
    this.appBar,
    this.bottomBar,
    this.padding,
    this.centerVertically = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuthDesignTokens.backgroundOf(context),
      appBar: appBar,
      bottomNavigationBar: bottomBar,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final minHeight =
                (constraints.maxHeight - (AuthDesignTokens.verticalPadding * 2))
                    .clamp(0.0, double.infinity);

            Widget bodyContent;
            if (centerVertically) {
              bodyContent = Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  child,
                  if (footer != null) ...[
                    const SizedBox(height: AuthDesignTokens.spaceXl),
                    footer!,
                  ],
                ],
              );
            } else if (footer != null) {
              bodyContent = Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  child,
                  Padding(
                    padding: const EdgeInsets.only(
                      top: AuthDesignTokens.spaceXl,
                    ),
                    child: footer!,
                  ),
                ],
              );
            } else {
              bodyContent = child;
            }

            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding:
                  padding ??
                  const EdgeInsets.symmetric(
                    horizontal: AuthDesignTokens.horizontalPadding,
                    vertical: AuthDesignTokens.verticalPadding,
                  ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: AuthDesignTokens.maxContentWidth,
                    minHeight: (centerVertically || footer != null)
                        ? minHeight
                        : 0,
                  ),
                  child: bodyContent,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
