package com.warp.warp_mediacenter_client.player

import android.content.Context
import android.util.Log
import android.view.SurfaceHolder
import android.view.SurfaceView
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import androidx.media3.ui.SubtitleView
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView

private const val TAG = "WarpPlayerView"
private const val METHOD_CHANNEL_PREFIX = "com.warp.warp_mediacenter_client/warp_player_methods/"
private const val EVENT_CHANNEL_PREFIX = "com.warp.warp_mediacenter_client/warp_player_events/"

/**
 * Hosts a bare [SurfaceView] for native ExoPlayer rendering, plus a native
 * [SubtitleView] layered above it, via hybrid composition. Both are
 * deliberately never Android-focusable and the surface consumes (never
 * propagates) touch, so they can never steal D-pad focus or leak touches
 * into Flutter's gesture system — see the native player plan, section 5,
 * for why this matters on Android TV. Subtitles render natively (not as a
 * Flutter overlay) so they stay composited in the same HWC pass as video,
 * immune to Flutter-side jank — see the plan's Context section.
 */
class WarpPlayerView(
    context: Context,
    messenger: BinaryMessenger,
    private val instanceId: String,
) : PlatformView {

    private val frameLayout: FrameLayout = FrameLayout(context)
    private val surfaceView: SurfaceView = SurfaceView(context)
    private val subtitleView: SubtitleView = SubtitleView(context)
    private val methodChannel = MethodChannel(messenger, METHOD_CHANNEL_PREFIX + instanceId)
    private val eventChannel = EventChannel(messenger, EVENT_CHANNEL_PREFIX + instanceId)
    private val controller = WarpExoPlayerController(context, methodChannel, subtitleView)

    init {
        // A bare SurfaceView composites *behind* the normal view hierarchy
        // by default (it's a hole-punch surface) — without this, Flutter's
        // own opaque background paints over it and it's invisible even
        // though decoding/rendering is happening correctly underneath.
        // setZOrderMediaOverlay (rather than setZOrderOnTop) keeps it above
        // the view hierarchy but still below system-level windows/dialogs.
        surfaceView.setZOrderMediaOverlay(true)
        surfaceView.isFocusable = false
        surfaceView.isFocusableInTouchMode = false
        surfaceView.setOnTouchListener { _, _ -> true }

        subtitleView.isFocusable = false
        subtitleView.isFocusableInTouchMode = false

        frameLayout.isFocusable = false
        frameLayout.isFocusableInTouchMode = false
        frameLayout.descendantFocusability = ViewGroup.FOCUS_BLOCK_DESCENDANTS
        frameLayout.addView(
            surfaceView,
            FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT,
            ),
        )
        // Added after surfaceView so it draws on top within the
        // FrameLayout's own child order.
        frameLayout.addView(
            subtitleView,
            FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT,
            ),
        )

        surfaceView.holder.addCallback(object : SurfaceHolder.Callback {
            override fun surfaceCreated(holder: SurfaceHolder) {
                Log.d(TAG, "surfaceCreated instanceId=$instanceId")
                controller.onSurfaceCreated(holder)
            }
            override fun surfaceChanged(holder: SurfaceHolder, format: Int, width: Int, height: Int) {
                Log.d(TAG, "surfaceChanged ${width}x$height instanceId=$instanceId")
            }
            override fun surfaceDestroyed(holder: SurfaceHolder) {
                Log.d(TAG, "surfaceDestroyed instanceId=$instanceId")
                controller.onSurfaceDestroyed()
            }
        })

        eventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, sink: EventChannel.EventSink) {
                Log.d(TAG, "eventChannel onListen instanceId=$instanceId")
                controller.attachEventSink(sink)
            }

            override fun onCancel(arguments: Any?) {
                Log.d(TAG, "eventChannel onCancel instanceId=$instanceId")
                controller.attachEventSink(null)
            }
        })

        Log.d(TAG, "WarpPlayerView constructed instanceId=$instanceId")
    }

    override fun getView(): View = frameLayout

    override fun dispose() {
        Log.d(TAG, "dispose() instanceId=$instanceId")
        eventChannel.setStreamHandler(null)
        controller.release()
    }
}
