package com.warp.warp_mediacenter_client

import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import android.content.Context
import io.flutter.plugin.common.BinaryMessenger

object NativeMedia3PlayerPlugin {
    private const val VIEW_TYPE = "warp/native_media3_player"

    fun registerWith(flutterEngine: FlutterEngine) {
        flutterEngine
            .platformViewsController
            .registry
            .registerViewFactory(
                VIEW_TYPE,
                NativeMedia3PlayerFactory(flutterEngine.dartExecutor.binaryMessenger),
            )
    }
}

private class NativeMedia3PlayerFactory(
    private val messenger: BinaryMessenger,
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        @Suppress("UNCHECKED_CAST")
        val params = args as? Map<String, Any?>
        return NativeMedia3PlayerView(context, viewId, messenger, params)
    }
}
