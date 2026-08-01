import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:warp_mediacenter_client/navigation/after_frame.dart';

// Regression cover for the D-pad focus stall.
//
// Focus placement (Down from the tab bar into row 0, Up from one row into the
// previous one) is deferred to a post-frame callback. A remote key press marks
// nothing dirty, so the app is idle and no frame is pending — and
// `addPostFrameCallback` runs after the next frame "whenever that may be, if
// ever" without ever asking for one. The deferred focus work then simply never
// ran, until some unrelated repaint (the *next* key press) belatedly flushed
// it: the key looked swallowed, and the following press appeared to "resolve"
// it.
//
// This is asserted on frame *scheduling* rather than by driving keys through a
// widget, because `tester.pump()` produces a frame unconditionally — which is
// precisely what hides the defect. `hasScheduledFrame` is the one observable
// that distinguishes "will definitely run" from "will run if something else
// happens to redraw".

void main() {
  testWidgets('afterNextFrame requests the frame it intends to run after', (
    tester,
  ) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(
      SchedulerBinding.instance.hasScheduledFrame,
      isFalse,
      reason: 'precondition: the app must be idle, as it is after a key press',
    );

    var ran = false;
    afterNextFrame((_) => ran = true);

    expect(
      SchedulerBinding.instance.hasScheduledFrame,
      isTrue,
      reason: 'afterNextFrame must schedule a frame, not hope for one',
    );

    await tester.pump();
    expect(ran, isTrue);
  });

  testWidgets('bare addPostFrameCallback does not — this was the defect', (
    tester,
  ) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(SchedulerBinding.instance.hasScheduledFrame, isFalse);

    WidgetsBinding.instance.addPostFrameCallback((_) {});

    expect(
      SchedulerBinding.instance.hasScheduledFrame,
      isFalse,
      reason:
          'documents why deferred focus placement stalled while the app was '
          'idle; afterNextFrame exists to close exactly this gap',
    );

    await tester.pump();
  });

  testWidgets('awaitNextFrame resolves from inside a post-frame callback', (
    tester,
  ) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(SchedulerBinding.instance.hasScheduledFrame, isFalse);

    // The exact shape of the focus chain: a post-frame callback that then
    // waits for the *following* frame. `endOfFrame` only schedules a frame
    // when called from SchedulerPhase.idle, so from in here it waits on a
    // frame nobody requested and never completes.
    var resolved = false;
    afterNextFrame((_) async {
      expect(SchedulerBinding.instance.schedulerPhase,
          SchedulerPhase.postFrameCallbacks);
      await awaitNextFrame();
      resolved = true;
    });

    await tester.pump(); // runs the post-frame callback
    await tester.pump(); // the frame awaitNextFrame asked for
    await tester.pump(); // let the continuation run

    expect(
      resolved,
      isTrue,
      reason: 'awaitNextFrame must schedule the frame it waits on',
    );
  });
}
