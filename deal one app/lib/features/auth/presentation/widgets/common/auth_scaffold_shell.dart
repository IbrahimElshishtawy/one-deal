import 'package:flutter/material.dart';

import '../../theme/auth_design_tokens.dart';

/// Responsive centered RTL/LTR shell shared across all authentication pages.
class AuthScaffoldShell extends StatelessWidget {
  final Widget child;
  final PreferredSizeWidget? appBar;
  final Widget? bottomBar;
  final EdgeInsetsGeometry? padding;
  final bool centerVertically;

  const AuthScaffoldShell({
    super.key,
    required this.child,
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
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: padding ??
                  const EdgeInsets.symmetric(
                    horizontal: AuthDesignTokens.horizontalPadding,
                    vertical: 16,
                  ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: AuthDesignTokens.maxContentWidth,
                    minHeight: centerVertically
                        ? (constraints.maxHeight - 32).clamp(0, double.infinity)
                        : 0,
                  ),
                  child: centerVertically
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [child],
                        )
                      : child,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
