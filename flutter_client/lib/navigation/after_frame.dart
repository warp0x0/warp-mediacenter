import 'package:flutter/scheduler.dart';

// ─────────────────────────────────────────────────────────────────────────────
// afterNextFrame — a post-frame callback that is actually guaranteed to run.
//
// `addPostFrameCallback` registers for the end of "the next frame (whenever
// that may be, *if ever*)" — Flutter's own words. It does not schedule a
// frame. That is fine inside build(), where a frame is already in flight, and
// a trap everywhere else.
//
// D-pad focus placement is exactly the "everywhere else" case. A remote key
// press marks nothing dirty, so the app is idle and no frame is pending: any
// focus work deferred with a bare `addPostFrameCallback` simply never runs.
// It then fires much later, on whatever unrelated repaint happens next —
// which is why Down from the tab bar consumed the key and went nowhere until
// the *next* key press produced a frame and belatedly flushed it.
//
// This is also why the bug looked position-dependent rather than systematic:
// navigating between two different rows animates the PageView, and an
// animation drives frames continuously, so the callback ran and the path
// "worked". Navigating to the row already on screen (Down from the tab bar to
// row 0, or any hop the PageView is already parked on) animates nothing,
// produces no frame, and stalls. Same code, opposite outcome, decided purely
// by whether something else happened to be animating.
//
// `scheduleFrame()` is idempotent — it early-returns when a frame is already
// scheduled — so pairing the two is free.
// ─────────────────────────────────────────────────────────────────────────────

void afterNextFrame(FrameCallback callback) {
  final binding = SchedulerBinding.instance;
  binding.addPostFrameCallback(callback);
  binding.scheduleFrame();
}

/// `SchedulerBinding.endOfFrame` that cannot deadlock.
///
/// `endOfFrame` looks like it schedules its own frame, and it does — but only
/// when called from `SchedulerPhase.idle`:
///
/// ```dart
/// if (schedulerPhase == SchedulerPhase.idle) {
///   scheduleFrame();
/// }
/// ```
///
/// Every focus hop here calls it from *inside* a post-frame callback (phase
/// `postFrameCallbacks`), so that branch is skipped and the returned future
/// resolves only if some frame was already pending for other reasons. When
/// nothing else is animating — the settled state right after focus has come
/// to rest — the await never returns and the whole focus chain stops silently,
/// mid-way, with no error.
///
/// That is why "Down from the tab pill" worked on the way in and hung after a
/// card -> hero -> pill round trip: the first descent still had a frame in
/// flight, the second had a fully settled tree and nothing left to schedule
/// one.
Future<void> awaitNextFrame() {
  final binding = SchedulerBinding.instance;
  final done = binding.endOfFrame;
  binding.scheduleFrame();
  return done;
}
