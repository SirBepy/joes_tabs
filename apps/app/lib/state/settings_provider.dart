import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:models/models.dart';

/// App-wide settings state for plan 08. In-memory only (Riverpod `keepAlive`
/// default for a top-level provider): these are session preferences, not
/// persisted to disk in this plan. A later plan can back the same providers
/// with a cache without changing any consumer.
///
/// The default instrument drives the Chords screen, the Tuner, and the song
/// view's preferred tab when a song has more than one.
final defaultInstrumentProvider = StateProvider<String>(
  (ref) => ChordShapes.ukulele,
);

/// Numeric font size shown in Settings -> Font Settings. Non-load-bearing for
/// other screens in this plan; kept here so the Settings stepper has a real
/// backing value.
final fontSizeProvider = StateProvider<int>((ref) => 20);

/// Dark-mode toggle. Wired to a real provider so the Settings switch reflects
/// and updates state; theme switching itself is a later polish pass.
final darkModeProvider = StateProvider<bool>((ref) => false);
