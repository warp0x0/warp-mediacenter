package com.warp.warp_mediacenter_client.player

import android.content.Context
import android.util.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

private const val TAG = "WarpPlayerViewFactory"

/**
 * Creates [WarpPlayerView] instances for the "warp_player_view" platform
 * view type. The instance id is generated Dart-side and passed as a
 * creation param, so the Dart controller can construct its MethodChannel/
 * EventChannel names synchronously, without waiting on a native round trip.
 */
class WarpPlayerViewFactory(
    private val messenger: BinaryMessenger,
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {

    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        @Suppress("UNCHECKED_CAST")
        val creationParams = args as? Map<String, Any?>
        val instanceId = creationParams?.get("instanceId") as? String
            ?: throw IllegalArgumentException("WarpPlayerView requires an 'instanceId' creation param")
        Log.d(TAG, "create() viewId=$viewId instanceId=$instanceId")
        return WarpPlayerView(context, messenger, instanceId)
    }
}
