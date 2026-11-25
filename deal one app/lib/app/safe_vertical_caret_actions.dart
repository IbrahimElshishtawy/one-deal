import 'package:flutter/widgets.dart';

/// Workaround for a Flutter 3.47.x framework assertion bug in
/// `VerticalCaretMovementRun.isValid` (`rendering/editable.dart`).
///
/// When a `TextField` is RTL (e.g. Arabic) or non-left-aligned so that
/// `TextPainter`'s `paintOffset != Offset.zero`, `TextPainter.computeLineMetrics()`
/// allocates a new `List<LineMetrics>` via `.map(...).toList()` on every call.
/// `VerticalCaretMovementRun.isValid` compares the returned list by `identical()`,
/// which immediately fails `assert(isValid)` in debug mode when pressing Up/Down
/// or Page Up/Down on a hardware keyboard.
///
/// Wrapping the app subtree in [SafeVerticalCaretActions] delegates to Flutter's
/// default vertical caret action and absorbs only that specific `isValid`
/// framework assertion in debug builds, while preserving normal vertical caret
/// movement everywhere else.
class SafeVerticalCaretActions extends StatelessWidget {
  final Widget child;

  const SafeVerticalCaretActions({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Actions(
      actions: <Type, Action<Intent>>{
        ExtendSelectionVerticallyToAdjacentLineIntent:
            _SafeVerticalCaretAction(),
        ExtendSelectionVerticallyToAdjacentPageIntent:
            _SafeVerticalCaretAction(),
      },
      child: child,
    );
  }
}

class _SafeVerticalCaretAction
    extends ContextAction<DirectionalCaretMovementIntent> {
  @override
  bool isEnabled(
    DirectionalCaretMovementIntent intent, [
    BuildContext? context,
  ]) {
    final Action<DirectionalCaretMovementIntent>? defaultAction = callingAction;
    if (defaultAction == null) {
      return false;
    }
    if (defaultAction is ContextAction<DirectionalCaretMovementIntent>) {
      return defaultAction.isEnabled(intent, context);
    }
    return defaultAction.isEnabled(intent);
  }

  @override
  Object? invoke(
    DirectionalCaretMovementIntent intent, [
    BuildContext? context,
  ]) {
    final Action<DirectionalCaretMovementIntent>? defaultAction = callingAction;
    if (defaultAction == null) {
      return null;
    }
    try {
      if (defaultAction is ContextAction<DirectionalCaretMovementIntent>) {
        return defaultAction.invoke(intent, context);
      }
      return defaultAction.invoke(intent);
    } on AssertionError catch (error) {
      if (!error.toString().contains('isValid')) {
        rethrow;
      }
      return null;
    }
  }
}
