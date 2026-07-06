// Tracks the last non-/search tab route visited. The shell's tabs switch
// via context.go(), which replaces the current location rather than
// pushing — so there is no real navigator back-stack for SearchPage's
// Back/Backspace to pop. AppShell records the active route here on every
// build except while on /search itself; SearchPage reads it back to
// return to wherever the user came from.
class LastTabRoute {
  LastTabRoute._();
  static String value = '/';
}
