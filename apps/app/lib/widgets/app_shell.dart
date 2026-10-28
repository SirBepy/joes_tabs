import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../router/app_routes.dart';
import '../router/app_tabs.dart';
import '../theme/app_breakpoints.dart';
import '../theme/app_colors.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';
import 'tab_scroll.dart';

/// Per-route trailing actions for the section header. A section screen registers
/// its own action widgets here (typically in a post-frame callback during build)
/// and clears them on dispose, so the [SectionHeader] stays route-agnostic: it
/// renders whatever the active screen registered, and nothing when the list is
/// empty. Routes that never set it show no stray action.
final sectionActionsProvider = StateProvider<List<Widget>>((ref) => const []);

/// How long the "Press back again to exit" prompt stays armed.
const Duration kExitPromptWindow = Duration(seconds: 2);

/// Chrome around the five tabs: a bottom [NavigationBar] on phones, a side
/// [NavigationRail] from [kBreakpointMedium] up. The top bar is route-dependent:
///
///  * Browse screens (Home, Trending) keep the sky-blue app bar with the
///    rounded search field; Trending adds a back button.
///  * Section screens (Tuner, Chords, Saved Tabs, Settings, Support Us) show a
///    [SectionHeader]: the screen title in the "bubble" heading font on
///    a white bar, with no search. Only Support Us, a pushed page, has
///    a back button.
///
/// It also owns system back for the whole tab area: see [_AppShellState._onBack].
class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.navigationShell,
    required this.scroll,
  });

  final StatefulNavigationShell navigationShell;

  /// Scroll controllers of the tab roots, used to scroll the active tab to the
  /// top.
  final TabScrollRegistry scroll;

  /// Section screens: route path -> the title shown in the bubble header.
  static const Map<String, String> _sectionTitles = {
    AppRoutes.settings: 'Settings',
    AppRoutes.support: 'Support us',
    AppRoutes.saved: 'Saved tabs',
    AppRoutes.chords: 'Chords',
    AppRoutes.tuner: 'Tuner',
  };

  /// Pushed pages that sit above a tab root and show a back button, mapped to
  /// the route back falls back to when nothing is beneath them (a deep link).
  static const Map<String, String> _pushedPages = {
    AppRoutes.trending: AppRoutes.home,
    AppRoutes.support: AppRoutes.settings,
  };

  /// Griddy routes are capped wider than reading routes so their grid layouts can
  /// use the available width up to [kPageMaxWidth]; everything else stays a
  /// centered reading column at [kReadingMaxWidth]. Chords hosts BOTH a reading
  /// picker and a griddy library, so it caps at [kPageMaxWidth] and the picker
  /// self-limits its own body width. On viewports narrower than the cap the
  /// [ConstrainedBox] is a no-op, so mobile (390px) is unchanged either way.
  static const Set<String> _griddyRoutes = {AppRoutes.saved, AppRoutes.chords};

  static double _maxContentWidthFor(String location) =>
      _griddyRoutes.contains(location) ? kPageMaxWidth : kReadingMaxWidth;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  bool _exitArmed = false;
  Timer? _exitTimer;

  StatefulNavigationShell get _shell => widget.navigationShell;

  @override
  void didUpdateWidget(AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    // An armed exit belongs to Home; leaving it must not let the next back
    // close the app from another tab.
    if (oldWidget.navigationShell.currentIndex != _shell.currentIndex) {
      _disarmExit();
    }
  }

  @override
  void dispose() {
    _exitTimer?.cancel();
    super.dispose();
  }

  void _disarmExit() {
    _exitTimer?.cancel();
    _exitTimer = null;
    _exitArmed = false;
  }

  /// System back when no page sits above the shell and no branch has a pushed
  /// page (go_router pops those first; open sheets and dialogs close first too).
  /// So this only runs at a tab root:
  ///  * another tab -> switch to Home;
  ///  * Home, scrolled down -> scroll to the top;
  ///  * Home at the top -> prompt, and a second back inside
  ///    [kExitPromptWindow] is let through (`canPop`) so the app exits.
  void _onBack(bool didPop, Object? result) {
    if (didPop) return;
    if (_shell.currentIndex != kHomeTabIndex) {
      _shell.goBranch(kHomeTabIndex);
      return;
    }
    if (!widget.scroll.isAtTop(kHomeTabIndex)) {
      widget.scroll.scrollToTop(kHomeTabIndex);
      return;
    }
    setState(() => _exitArmed = true);
    _exitTimer?.cancel();
    _exitTimer = Timer(kExitPromptWindow, () {
      if (mounted) setState(_disarmExit);
    });
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Press back again to exit'),
          duration: kExitPromptWindow,
        ),
      );
  }

  /// Switching tab restores that tab's own stack. Tapping the active tab pops
  /// its stack to the root, and from the root scrolls it to the top.
  void _onSelect(int index) {
    if (index != _shell.currentIndex) {
      _shell.goBranch(index);
      return;
    }
    final branchNavigator = _shell.route.branches[index].navigatorKey;
    if (branchNavigator.currentState?.canPop() ?? false) {
      _shell.goBranch(index, initialLocation: true);
    } else {
      widget.scroll.scrollToTop(index);
    }
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    String location,
    VoidCallback? onBack,
  ) {
    final sectionTitle = AppShell._sectionTitles[location];
    if (sectionTitle != null) {
      return SectionHeader(title: sectionTitle, onBack: onBack);
    }
    return AppBar(
      automaticallyImplyLeading: false,
      leading: onBack == null
          ? null
          : IconButton(
              icon: const Icon(PhosphorIconsRegular.caretLeft),
              tooltip: 'Back',
              onPressed: onBack,
            ),
      title: const _SearchField(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final router = GoRouter.of(context);
    // The deepest match, not `uri`: a pushed page (Support Us over Settings)
    // doesn't change the shell's own `uri`.
    final location =
        router.routerDelegate.currentConfiguration.last.matchedLocation;
    final fallback = AppShell._pushedPages[location];
    final onBack = fallback == null
        ? null
        : () => router.canPop() ? router.pop() : router.go(fallback);

    final content = Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: AppShell._maxContentWidthFor(location),
        ),
        child: _shell,
      ),
    );
    final wide = MediaQuery.sizeOf(context).width >= kBreakpointMedium;

    return PopScope(
      canPop: _exitArmed && _shell.currentIndex == kHomeTabIndex,
      onPopInvokedWithResult: _onBack,
      child: Scaffold(
        appBar: _buildAppBar(context, location, onBack),
        // The app bar and the Scaffold background stay full-bleed; only the
        // routed content is centered into a capped column so wide desktop
        // windows don't stretch the mobile layout edge to edge. The rail sits
        // outside that cap, flush with the window edge.
        body: wide
            ? Row(
                children: [
                  _TabRail(
                    selectedIndex: _shell.currentIndex,
                    onSelect: _onSelect,
                  ),
                  Expanded(child: content),
                ],
              )
            : content,
        bottomNavigationBar: wide
            ? null
            : _TabBar(selectedIndex: _shell.currentIndex, onSelect: _onSelect),
      ),
    );
  }
}

/// Bottom bar on phones. Sky-blue pill behind the active white icon; surfaces
/// come from the palette so it follows light and dark.
class _TabBar extends StatelessWidget {
  const _TabBar({required this.selectedIndex, required this.onSelect});

  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: palette.divider)),
      ),
      child: NavigationBar(
        key: const Key('app-navigation-bar'),
        selectedIndex: selectedIndex,
        onDestinationSelected: onSelect,
        backgroundColor: palette.sheet,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: AppColors.orange,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w800
                : FontWeight.w600,
            color: states.contains(WidgetState.selected)
                ? palette.accent
                : palette.mutedInk,
          ),
        ),
        destinations: [
          for (final tab in appTabs)
            NavigationDestination(
              label: tab.label,
              icon: Icon(tab.icon, color: palette.mutedInk),
              selectedIcon: Icon(tab.selectedIcon, color: AppColors.white),
            ),
        ],
      ),
    );
  }
}

/// Side rail from [kBreakpointMedium] up, same destinations and order as
/// [_TabBar].
class _TabRail extends StatelessWidget {
  const _TabRail({required this.selectedIndex, required this.onSelect});

  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    // Five labelled destinations need ~380px; a landscape phone is shorter, so
    // it drops the labels rather than overflowing. (Not a SingleChildScrollView:
    // an extra Scrollable beside the page makes every unscoped
    // `find.byType(Scrollable)` ambiguous.)
    return LayoutBuilder(
      builder: (context, constraints) => DecoratedBox(
        decoration: BoxDecoration(
          border: Border(right: BorderSide(color: palette.divider)),
        ),
        child: NavigationRail(
          key: const Key('app-navigation-rail'),
          selectedIndex: selectedIndex,
          onDestinationSelected: onSelect,
          labelType: constraints.maxHeight >= 400
              ? NavigationRailLabelType.all
              : NavigationRailLabelType.none,
          backgroundColor: palette.sheet,
          indicatorColor: AppColors.orange,
          selectedLabelTextStyle: TextStyle(
            color: palette.accent,
            fontWeight: FontWeight.w800,
          ),
          unselectedLabelTextStyle: TextStyle(
            color: palette.mutedInk,
            fontWeight: FontWeight.w600,
          ),
          destinations: [
            for (final tab in appTabs)
              NavigationRailDestination(
                label: Text(tab.label),
                icon: Icon(tab.icon, color: palette.mutedInk),
                selectedIcon: Icon(tab.selectedIcon, color: AppColors.white),
              ),
          ],
        ),
      ),
    );
  }
}

/// The section-screen header: a white bar with the screen [title] in the brand
/// "bubble" heading font (Fredoka). When [onBack] is set (a pushed page
/// like Support Us) a circular accent-outlined back button (Phosphor caret) sits
/// at the leading edge; the top-level tabs have none.
///
/// Implemented as a [PreferredSizeWidget] so it can slot straight into
/// [Scaffold.appBar].
class SectionHeader extends ConsumerWidget implements PreferredSizeWidget {
  const SectionHeader({super.key, required this.title, this.onBack});

  final String title;
  final VoidCallback? onBack;

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = ref.watch(sectionActionsProvider);
    // The bar, its divider and the accent foreground come from the palette so
    // dark mode darkens with the body.
    final palette = context.palette;
    final barColor = palette.sheet;
    final borderColor = palette.divider;
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: barColor,
      foregroundColor: palette.accent,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: 72,
      leadingWidth: 72,
      shape: Border(bottom: BorderSide(color: borderColor, width: 1)),
      leading: onBack == null
          ? null
          : Padding(
              padding: const EdgeInsets.only(left: AppSpacing.md),
              child: _BackCircle(onTap: onBack!),
            ),
      title: Text(title, style: Theme.of(context).textTheme.headlineMedium),
      centerTitle: false,
      actions: actions.isEmpty ? null : actions,
    );
  }
}

/// The circular back control: an accent-outlined circle wrapping a Phosphor
/// caret-left, matching the section mockups.
class _BackCircle extends StatelessWidget {
  const _BackCircle({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = context.palette.accent;
    return Semantics(
      button: true,
      label: 'Back',
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: accent, width: 2),
          ),
          child: Icon(PhosphorIconsBold.caretLeft, color: accent, size: 22),
        ),
      ),
    );
  }
}

/// Rounded search field in the browse app bar. Tapping it opens the dedicated
/// [SearchScreen] (`/search`), which searches ukulele-tabs.com.
class _SearchField extends StatelessWidget {
  const _SearchField();

  @override
  Widget build(BuildContext context) {
    // bodyLarge, not a bare TextStyle: the app bar's default text style is the
    // Fredoka title face, which a color-only style would inherit.
    final hintStyle = Theme.of(
      context,
    ).textTheme.bodyLarge?.copyWith(color: AppColors.textMuted);
    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      onTap: () => context.push(AppRoutes.search),
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1F12324A),
              offset: Offset(0, 1),
              blurRadius: 2,
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(child: Text('Search ukulele-tabs.com', style: hintStyle)),
            const Icon(
              PhosphorIconsRegular.magnifyingGlass,
              color: AppColors.textMuted,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
