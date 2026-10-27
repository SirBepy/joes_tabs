import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'app_routes.dart';

/// One bottom-bar / side-rail destination.
class AppTab {
  const AppTab(this.label, this.icon, this.selectedIcon, this.route);

  final String label;
  final PhosphorIconData icon;
  final PhosphorIconData selectedIcon;

  /// The tab's root path; also the branch's initial location.
  final String route;
}

/// Destinations in display order. The index is the `StatefulShellRoute` branch
/// index, so the router's branch list must follow this order exactly.
final List<AppTab> appTabs = [
  AppTab(
    'Tuner',
    PhosphorIconsRegular.gauge,
    PhosphorIconsFill.gauge,
    AppRoutes.tuner,
  ),
  AppTab(
    'Chords',
    PhosphorIconsRegular.musicNotes,
    PhosphorIconsFill.musicNotes,
    AppRoutes.chords,
  ),
  AppTab(
    'Home',
    PhosphorIconsRegular.house,
    PhosphorIconsFill.house,
    AppRoutes.home,
  ),
  AppTab(
    'Saved',
    PhosphorIconsRegular.bookmarkSimple,
    PhosphorIconsFill.bookmarkSimple,
    AppRoutes.saved,
  ),
  AppTab(
    'Settings',
    PhosphorIconsRegular.gearSix,
    PhosphorIconsFill.gearSix,
    AppRoutes.settings,
  ),
];

/// Home is the middle tab and the one back-navigation falls back to.
const int kHomeTabIndex = 2;
