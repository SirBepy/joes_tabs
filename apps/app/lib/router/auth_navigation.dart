import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Marks an auth screen pushed by the other auth screen's cross-link.
const _authToggleExtra = 'auth-toggle';

/// Follows the Log In / Register cross-link to [target]. If the current screen
/// was itself opened by the other one's link, that screen is directly beneath,
/// so pop back to it; otherwise push [target]. Back from Register still lands
/// on the Log In that opened it, but toggling never stacks more than one pair.
void toggleAuthScreen(BuildContext context, String target) {
  if (GoRouterState.of(context).extra == _authToggleExtra && context.canPop()) {
    context.pop();
  } else {
    context.push(target, extra: _authToggleExtra);
  }
}
