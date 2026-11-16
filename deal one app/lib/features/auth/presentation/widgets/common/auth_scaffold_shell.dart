import 'package:flutter/material.dart';

import '../../theme/auth_design_tokens.dart';

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
            final minHeight = (constraints.maxHeight - 32).clamp(
              0.0,
              double.infinity,
            );

            Widget bodyContent;
            if (centerVertically) {
              bodyContent = Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  child,
                  if (footer != null) ...[const SizedBox(height: 24), footer!],
                ],
              );
            } else if (footer != null) {
              bodyContent = Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  child,
                  Padding(
                    padding: const EdgeInsets.only(top: 24),
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
                    vertical: 16,
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
