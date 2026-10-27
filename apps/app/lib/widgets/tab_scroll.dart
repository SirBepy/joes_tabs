import 'package:flutter/material.dart';

/// One [ScrollController] per bottom-nav tab, owned by the router so the shell
/// can scroll a tab to the top without any screen knowing about it.
///
/// A tab's root page wraps its screen in [TabScrollScope]; the screen's own
/// vertical scrollable then picks the controller up through
/// [PrimaryScrollController] with zero screen edits.
class TabScrollRegistry {
  final Map<int, ScrollController> _controllers = {};

  ScrollController controllerFor(int branch) =>
      _controllers.putIfAbsent(branch, ScrollController.new);

  /// True when nothing in [branch] is scrolled away from the top (also when the
  /// tab has no attached scrollable yet).
  bool isAtTop(int branch) {
    final controller = _controllers[branch];
    if (controller == null) return true;
    // A screen may host several primary scrollables; every one must be at 0.
    return controller.positions.every((p) => p.pixels <= 0);
  }

  Future<void> scrollToTop(int branch) async {
    final controller = _controllers[branch];
    if (controller == null) return;
    await Future.wait([
      for (final position in controller.positions)
        position.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        ),
    ]);
  }
}

/// Hands [controller] to every vertical scrollable below as its primary
/// controller.
class TabScrollScope extends StatelessWidget {
  const TabScrollScope({
    super.key,
    required this.controller,
    required this.child,
  });

  final ScrollController controller;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PrimaryScrollController(
      controller: controller,
      // The default only inherits on mobile platforms; the app also runs on web
      // under a desktop browser, where back-to-top must work the same.
      automaticallyInheritForPlatforms: TargetPlatform.values.toSet(),
      child: child,
    );
  }
}
