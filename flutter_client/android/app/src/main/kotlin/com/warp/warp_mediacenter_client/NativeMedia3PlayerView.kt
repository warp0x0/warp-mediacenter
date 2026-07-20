package com.warp.warp_mediacenter_client

import android.content.Context
import android.graphics.Color
import android.graphics.Typeface
import android.media.audiofx.LoudnessEnhancer
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.util.TypedValue
import android.view.Gravity
import android.view.SurfaceView
import android.view.TextureView
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import androidx.annotation.OptIn
import androidx.media3.common.C
import androidx.media3.common.Format
import androidx.media3.common.MediaItem
import androidx.media3.common.MimeTypes
import androidx.media3.common.PlaybackException
import androidx.media3.common.Player
import androidx.media3.common.TrackSelectionOverride
import androidx.media3.common.Tracks
import androidx.media3.common.VideoSize
import androidx.media3.common.text.CueGroup
import androidx.media3.common.util.UnstableApi
import androidx.media3.datasource.BaseDataSource
import androidx.media3.datasource.DataSource
import androidx.media3.datasource.DataSpec
import androidx.media3.datasource.DefaultDataSource
import androidx.media3.datasource.DefaultHttpDataSource
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.DefaultRenderersFactory
import androidx.media3.exoplayer.source.MediaSource
import androidx.media3.exoplayer.source.MergingMediaSource
import androidx.media3.exoplayer.trackselection.DefaultTrackSelector
import androidx.media3.ui.AspectRatioFrameLayout
import androidx.media3.ui.CaptionStyleCompat
import androidx.media3.ui.SubtitleView
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView
import kotlin.math.roundToInt
import java.io.IOException
import java.io.InputStream
import java.io.OutputStream
import java.net.HttpURLConnection
import java.net.URL
import kotlin.math.min

@OptIn(UnstableApi::class)
class NativeMedia3PlayerView(
    private val context: Context,
    viewId: Int,
    messenger: BinaryMessenger,
    params: Map<String, Any?>?,
) : PlatformView, MethodChannel.MethodCallHandler, EventChannel.StreamHandler {
    private val root = FrameLayout(context)
    private val contentFrame = AspectRatioFrameLayout(context)
    private val surfaceView = SurfaceView(context)
    private val textureView = TextureView(context)
    private val subtitleView = SubtitleView(context)
    private val handler = Handler(Looper.getMainLooper())
    private val methodChannel = MethodChannel(messenger, "warp/native_media3_player/$viewId/methods")
    private val eventChannel = EventChannel(messenger, "warp/native_media3_player/$viewId/events")
    private val trackSelector = DefaultTrackSelector(context)
    private val player = ExoPlayer.Builder(context)
        .setRenderersFactory(DefaultRenderersFactory(context))
        .setTrackSelector(trackSelector)
        .build()

    private var eventSink: EventChannel.EventSink? = null
    private var disposed = false
    private var positionEventsRunning = false
    private var currentRequest: Map<String, Any?>? = params
    private var loudnessEnhancer: LoudnessEnhancer? = null
    private var loudnessAudioSessionId: Int = C.AUDIO_SESSION_ID_UNSET
    private var audioBoostMb = 0
    private var subtitleDelayMs = 0L
    private var subtitleTextSizeSp = 40f
    private var videoAspectRatio = 0f
    private var aspectMode = params?.get("resizeMode") as? String ?: "fit"
    private val renderSurface = params?.get("renderSurface") as? String ?: "surface"
    private val externalSubtitles = mutableListOf<ExternalSubtitle>()

    private val positionTicker = object : Runnable {
        override fun run() {
            if (disposed || !positionEventsRunning) return
            applyLoudnessEnhancer()
            emitStatus("position")
            handler.postDelayed(this, 500)
        }
    }

    private val listener = object : Player.Listener {
        override fun onPlaybackStateChanged(playbackState: Int) {
            emitStatus("state")
            if (playbackState == Player.STATE_ENDED) {
                emitEvent(
                    mapOf(
                        "type" to "completed",
                        "positionMs" to safePositionMs(),
                        "durationMs" to safeDurationMs(),
                    ),
                )
            }
        }

        override fun onIsPlayingChanged(isPlaying: Boolean) {
            emitStatus("playing")
        }

        override fun onPlayerError(error: PlaybackException) {
            emitEvent(
                mapOf(
                    "type" to "error",
                    "code" to error.errorCodeName,
                    "message" to (error.message ?: "Unknown playback error"),
                ),
            )
        }

        override fun onVideoSizeChanged(videoSize: VideoSize) {
            val width = videoSize.width
            val height = videoSize.height
            if (width > 0 && height > 0) {
                videoAspectRatio = (width * videoSize.pixelWidthHeightRatio) / height
                applyAspectMode()
            }
            emitEvent(
                mapOf(
                    "type" to "videoSize",
                    "width" to width,
                    "height" to height,
                    "pixelWidthHeightRatio" to videoSize.pixelWidthHeightRatio.toDouble(),
                ),
            )
        }

        override fun onCues(cueGroup: CueGroup) {
            subtitleView.setCues(cueGroup.cues)
        }

        override fun onTracksChanged(tracks: Tracks) {
            emitEvent(tracksPayload())
        }

        override fun onRenderedFirstFrame() {
            emitEvent(mapOf("type" to "firstFrame"))
        }
    }

    init {
        root.setBackgroundColor(Color.BLACK)
        root.isFocusable = false
        root.isFocusableInTouchMode = false
        root.descendantFocusability = ViewGroup.FOCUS_BLOCK_DESCENDANTS
        root.setOnTouchListener { _, _ -> true }

        applyAspectMode()
        contentFrame.setBackgroundColor(Color.BLACK)
        contentFrame.isFocusable = false
        contentFrame.isFocusableInTouchMode = false
        contentFrame.descendantFocusability = ViewGroup.FOCUS_BLOCK_DESCENDANTS
        contentFrame.setOnTouchListener { _, _ -> true }

        val videoView = if (renderSurface == "texture") textureView else surfaceView
        videoView.isFocusable = false
        videoView.isFocusableInTouchMode = false
        videoView.setOnTouchListener { _, _ -> true }

        contentFrame.addView(
            videoView,
            FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT,
            ),
        )
        subtitleView.setStyle(
            CaptionStyleCompat(
                Color.WHITE,
                Color.TRANSPARENT,
                Color.TRANSPARENT,
                CaptionStyleCompat.EDGE_TYPE_DROP_SHADOW,
                Color.BLACK,
                Typeface.DEFAULT_BOLD,
            ),
        )
        subtitleView.setFixedTextSize(TypedValue.COMPLEX_UNIT_SP, subtitleTextSizeSp)
        subtitleView.setApplyEmbeddedStyles(false)
        subtitleView.setApplyEmbeddedFontSizes(false)
        subtitleView.setBottomPaddingFraction(0.06f)
        subtitleView.isFocusable = false
        subtitleView.isFocusableInTouchMode = false
        contentFrame.addView(
            subtitleView,
            FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT,
            ),
        )
        root.addView(
            contentFrame,
            FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT,
            ).apply { gravity = Gravity.CENTER },
        )

        if (renderSurface == "texture") {
            player.setVideoTextureView(textureView)
        } else {
            player.setVideoSurfaceView(surfaceView)
        }
        player.addListener(listener)

        methodChannel.setMethodCallHandler(this)
        eventChannel.setStreamHandler(this)

        val source = params?.get("source") as? String
        val videoUrl = params?.get("videoUrl") as? String
        val audioUrl = params?.get("audioUrl") as? String
        if (!source.isNullOrBlank() || (!videoUrl.isNullOrBlank() && !audioUrl.isNullOrBlank())) {
            setDataSource(params, autoplay = params?.get("autoplay") as? Boolean ?: true)
        }
    }

    override fun getView(): View = root

    override fun dispose() {
        if (disposed) return
        disposed = true
        positionEventsRunning = false
        handler.removeCallbacksAndMessages(null)
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        player.removeListener(listener)
        if (renderSurface == "texture") {
            player.clearVideoTextureView(textureView)
        } else {
            player.clearVideoSurfaceView(surfaceView)
        }
        releaseLoudnessEnhancer()
        player.release()
        eventSink = null
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        positionEventsRunning = true
        emitStatus("listen")
        handler.removeCallbacks(positionTicker)
        handler.post(positionTicker)
    }

    override fun onCancel(arguments: Any?) {
        positionEventsRunning = false
        handler.removeCallbacks(positionTicker)
        eventSink = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "setDataSource" -> {
                    @Suppress("UNCHECKED_CAST")
                    val args = call.arguments as? Map<String, Any?> ?: emptyMap()
                    setDataSource(args, autoplay = args["autoplay"] as? Boolean ?: true)
                    result.success(statusPayload("setDataSource"))
                }

                "play" -> {
                    player.play()
                    result.success(statusPayload("play"))
                }

                "pause" -> {
                    player.pause()
                    result.success(statusPayload("pause"))
                }

                "seekTo" -> {
                    val positionMs = (call.argument<Number>("positionMs") ?: 0).toLong()
                    player.seekTo(positionMs.coerceAtLeast(0L))
                    result.success(statusPayload("seekTo"))
                }

                "seekBy" -> {
                    val deltaMs = (call.argument<Number>("deltaMs") ?: 0).toLong()
                    val duration = safeDurationMs()
                    val target = (safePositionMs() + deltaMs).coerceAtLeast(0L)
                    player.seekTo(if (duration > 0L) target.coerceAtMost(duration) else target)
                    result.success(statusPayload("seekBy"))
                }

                "setVolume" -> {
                    val volume = (call.argument<Number>("volume") ?: 1.0).toFloat()
                    player.volume = volume.coerceIn(0f, 1f)
                    result.success(statusPayload("setVolume"))
                }

                "setAudioBoost" -> {
                    val boostDb = (call.argument<Number>("boostDb") ?: 0).toDouble()
                    setAudioBoost(boostDb)
                    result.success(statusPayload("setAudioBoost"))
                }

                "setAspectRatioMode" -> {
                    val mode = call.argument<String>("mode") ?: "fit"
                    aspectMode = mode
                    applyAspectMode()
                    result.success(statusPayload("setAspectRatioMode"))
                }

                "setSubtitleDelay" -> {
                    val delayMs = (call.argument<Number>("delayMs") ?: 0).toLong()
                    subtitleDelayMs = delayMs.coerceIn(-5000L, 5000L)
                    result.success(statusPayload("setSubtitleDelay"))
                }

                "setSubtitleTextSize" -> {
                    val sizeSp = (call.argument<Number>("sizeSp") ?: 40).toFloat()
                    subtitleTextSizeSp = sizeSp.coerceIn(20f, 100f)
                    subtitleView.setFixedTextSize(TypedValue.COMPLEX_UNIT_SP, subtitleTextSizeSp)
                    result.success(statusPayload("setSubtitleTextSize"))
                }

                "loadSubtitle" -> {
                    val uri = call.argument<String>("uri") ?: ""
                    if (uri.isBlank()) throw IllegalArgumentException("subtitle uri is required")
                    val title = call.argument<String>("title")
                    val language = call.argument<String>("language")
                    externalSubtitles.add(ExternalSubtitle(uri, title, language))
                    reloadCurrentSource(selectLastSubtitle = true)
                    result.success(tracksPayload())
                }

                "selectAudioTrack" -> {
                    selectTrack(C.TRACK_TYPE_AUDIO, call.argument<String>("id") ?: "auto")
                    result.success(tracksPayload())
                }

                "selectSubtitleTrack" -> {
                    selectTrack(C.TRACK_TYPE_TEXT, call.argument<String>("id") ?: "auto")
                    result.success(tracksPayload())
                }

                "getTracks" -> {
                    result.success(tracksPayload())
                }

                "setAudioPassthrough" -> {
                    result.success(statusPayload("setAudioPassthrough"))
                }

                "setDolbyMode" -> {
                    result.success(statusPayload("setDolbyMode"))
                }

                "stop" -> {
                    player.stop()
                    result.success(statusPayload("stop"))
                }

                "dispose" -> {
                    dispose()
                    result.success(mapOf("ok" to true))
                }

                else -> result.notImplemented()
            }
        } catch (error: Throwable) {
            result.error("NATIVE_MEDIA3_ERROR", error.message, null)
        }
    }

    private fun setDataSource(args: Map<String, Any?>?, autoplay: Boolean) {
        currentRequest = args
        val headers = readHeaders(args?.get("headers"))
        val source = args?.get("source") as? String
        val videoUrl = args?.get("videoUrl") as? String
        val audioUrl = args?.get("audioUrl") as? String
        val startPositionMs = (args?.get("startPositionMs") as? Number)?.toLong() ?: 0L
        val youtubeTrailerMode = args?.get("youtubeTrailerMode") as? Boolean ?: false

        val mediaSource = if (!videoUrl.isNullOrBlank() && !audioUrl.isNullOrBlank()) {
            MergingMediaSource(
                buildMediaSource(videoUrl, headers, youtubeTrailerMode, includeSubtitles = true),
                buildMediaSource(audioUrl, headers, youtubeTrailerMode),
            )
        } else if (!source.isNullOrBlank()) {
            buildMediaSource(source, headers, youtubeTrailerMode, includeSubtitles = true)
        } else {
            throw IllegalArgumentException("source or videoUrl/audioUrl is required")
        }

        player.stop()
        player.setMediaSource(mediaSource, startPositionMs.coerceAtLeast(0L))
        player.prepare()
        player.playWhenReady = autoplay
        applyLoudnessEnhancer()
        emitStatus("setDataSource")
    }

    private fun buildMediaSource(
        url: String,
        headers: Map<String, String>,
        youtubeTrailerMode: Boolean,
        includeSubtitles: Boolean = false,
    ): MediaSource {
        val httpFactory = DefaultHttpDataSource.Factory()
            .setAllowCrossProtocolRedirects(true)
            .setDefaultRequestProperties(headers)
        val upstreamFactory = DefaultDataSource.Factory(context, httpFactory)
        val dataSourceFactory = if (youtubeTrailerMode) {
            YouTubeTrailerDataSourceFactory(upstreamFactory, headers)
        } else {
            upstreamFactory
        }
        val itemBuilder = MediaItem.Builder()
            .setUri(Uri.parse(url))
        if (includeSubtitles && externalSubtitles.isNotEmpty()) {
            itemBuilder.setSubtitleConfigurations(externalSubtitles.map { it.toMedia3Configuration() })
        }
        val item = itemBuilder.build()
        return androidx.media3.exoplayer.source.DefaultMediaSourceFactory(dataSourceFactory)
            .createMediaSource(item)
    }

    private fun reloadCurrentSource(selectLastSubtitle: Boolean = false) {
        val args = currentRequest ?: throw IllegalStateException("No active media source")
        val positionMs = safePositionMs()
        val autoplay = player.playWhenReady
        setDataSource(
            args + mapOf(
                "startPositionMs" to positionMs,
                "autoplay" to autoplay,
            ),
            autoplay = autoplay,
        )
        if (selectLastSubtitle) {
            handler.postDelayed({ selectLastExternalSubtitle() }, 250)
        }
    }

    private fun selectLastExternalSubtitle() {
        val textTracks = trackItems(C.TRACK_TYPE_TEXT).filter { it["id"] !in listOf("no", "auto") }
        val id = textTracks.lastOrNull()?.get("id") as? String ?: return
        selectTrack(C.TRACK_TYPE_TEXT, id)
        emitEvent(tracksPayload())
    }

    private fun setAudioBoost(boostDb: Double) {
        val steppedDb = boostDb.coerceIn(0.0, 30.0).roundToInt().coerceIn(0, 30)
        audioBoostMb = steppedDb * 1000
        applyLoudnessEnhancer()
    }

    private fun applyAspectMode() {
        val fixedRatio = fixedAspectRatio(aspectMode)
        when (aspectMode) {
            "fill" -> {
                contentFrame.resizeMode = AspectRatioFrameLayout.RESIZE_MODE_FILL
                contentFrame.setAspectRatio(videoAspectRatio.takeIf { it > 0f } ?: 0f)
            }

            "zoom" -> {
                contentFrame.resizeMode = AspectRatioFrameLayout.RESIZE_MODE_ZOOM
                contentFrame.setAspectRatio(videoAspectRatio.takeIf { it > 0f } ?: 0f)
            }

            else -> {
                contentFrame.resizeMode = AspectRatioFrameLayout.RESIZE_MODE_FIT
                contentFrame.setAspectRatio(fixedRatio ?: videoAspectRatio.takeIf { it > 0f } ?: 0f)
            }
        }
    }

    private fun fixedAspectRatio(mode: String): Float? = when (mode) {
        "4:3" -> 4f / 3f
        "14:9" -> 14f / 9f
        "16:9" -> 16f / 9f
        "18:9" -> 18f / 9f
        "21:9" -> 21f / 9f
        "2.35:1" -> 2.35f
        "2.39:1" -> 2.39f
        else -> null
    }

    private fun applyLoudnessEnhancer() {
        val sessionId = player.audioSessionId
        if (sessionId == C.AUDIO_SESSION_ID_UNSET) return
        if (loudnessEnhancer == null || loudnessAudioSessionId != sessionId) {
            releaseLoudnessEnhancer()
            loudnessEnhancer = LoudnessEnhancer(sessionId)
            loudnessAudioSessionId = sessionId
        }
        loudnessEnhancer?.let { enhancer ->
            enhancer.setTargetGain(audioBoostMb)
            enhancer.enabled = audioBoostMb > 0
        }
    }

    private fun releaseLoudnessEnhancer() {
        loudnessEnhancer?.let { enhancer ->
            try {
                enhancer.enabled = false
            } catch (_: Throwable) {
            }
            enhancer.release()
        }
        loudnessEnhancer = null
        loudnessAudioSessionId = C.AUDIO_SESSION_ID_UNSET
    }

    private fun selectTrack(trackType: Int, id: String) {
        val builder = player.trackSelectionParameters.buildUpon()
        if (id == "no") {
            builder.clearOverridesOfType(trackType)
            builder.setTrackTypeDisabled(trackType, true)
            player.trackSelectionParameters = builder.build()
            return
        }
        builder.setTrackTypeDisabled(trackType, false)
        if (id == "auto") {
            builder.clearOverridesOfType(trackType)
            player.trackSelectionParameters = builder.build()
            return
        }
        val parts = id.split(":")
        if (parts.size != 3) return
        val groupIndex = parts[1].toIntOrNull() ?: return
        val trackIndex = parts[2].toIntOrNull() ?: return
        val group = player.currentTracks.groups.getOrNull(groupIndex) ?: return
        if (group.type != trackType || trackIndex !in 0 until group.length) return
        builder.setOverrideForType(TrackSelectionOverride(group.mediaTrackGroup, listOf(trackIndex)))
        player.trackSelectionParameters = builder.build()
    }

    private fun tracksPayload(): Map<String, Any?> = mapOf(
        "type" to "tracks",
        "audioTracks" to trackItems(C.TRACK_TYPE_AUDIO),
        "subtitleTracks" to trackItems(C.TRACK_TYPE_TEXT),
        "selectedAudioTrackId" to selectedTrackId(C.TRACK_TYPE_AUDIO),
        "selectedSubtitleTrackId" to selectedTrackId(C.TRACK_TYPE_TEXT),
    )

    private fun trackItems(trackType: Int): List<Map<String, Any?>> {
        val items = mutableListOf<Map<String, Any?>>()
        if (trackType == C.TRACK_TYPE_AUDIO) {
            items.add(mapOf("id" to "auto", "title" to "Auto", "selected" to (selectedTrackId(trackType) == "auto")))
        } else if (trackType == C.TRACK_TYPE_TEXT) {
            items.add(mapOf("id" to "no", "title" to "Disabled", "selected" to (selectedTrackId(trackType) == "no")))
            items.add(mapOf("id" to "auto", "title" to "Auto", "selected" to (selectedTrackId(trackType) == "auto")))
        }
        for ((groupIndex, group) in player.currentTracks.groups.withIndex()) {
            if (group.type != trackType) continue
            for (trackIndex in 0 until group.length) {
                val format = group.getTrackFormat(trackIndex)
                items.add(trackPayload(trackType, groupIndex, trackIndex, format, group.isTrackSelected(trackIndex), group.isTrackSupported(trackIndex)))
            }
        }
        return items
    }

    private fun selectedTrackId(trackType: Int): String {
        var hasTrackOfType = false
        for ((groupIndex, group) in player.currentTracks.groups.withIndex()) {
            if (group.type != trackType) continue
            hasTrackOfType = true
            for (trackIndex in 0 until group.length) {
                if (group.isTrackSelected(trackIndex)) return "${trackTypeLabel(trackType)}:$groupIndex:$trackIndex"
            }
        }
        return if (trackType == C.TRACK_TYPE_TEXT || !hasTrackOfType) "no" else "auto"
    }

    private fun trackPayload(
        trackType: Int,
        groupIndex: Int,
        trackIndex: Int,
        format: Format,
        selected: Boolean,
        supported: Boolean,
    ): Map<String, Any?> {
        val fallbackTitle = if (trackType == C.TRACK_TYPE_AUDIO) "Audio ${trackIndex + 1}" else "Subtitle ${trackIndex + 1}"
        return mapOf(
            "id" to "${trackTypeLabel(trackType)}:$groupIndex:$trackIndex",
            "title" to (format.label ?: format.language ?: fallbackTitle),
            "language" to format.language,
            "codec" to format.codecs,
            "mimeType" to format.sampleMimeType,
            "channelCount" to format.channelCount.takeIf { it > 0 },
            "sampleRate" to format.sampleRate.takeIf { it > 0 },
            "selected" to selected,
            "supported" to supported,
        )
    }

    private fun trackTypeLabel(trackType: Int): String = if (trackType == C.TRACK_TYPE_AUDIO) "audio" else "text"

    private fun readHeaders(value: Any?): Map<String, String> {
        val map = value as? Map<*, *> ?: return emptyMap()
        return map.entries.associate { (key, entryValue) -> key.toString() to entryValue.toString() }
    }

    private fun safePositionMs(): Long = player.currentPosition.coerceAtLeast(0L)

    private fun safeDurationMs(): Long {
        val duration = player.duration
        return if (duration == C.TIME_UNSET || duration < 0L) 0L else duration
    }

    private fun playbackStateLabel(): String = when (player.playbackState) {
        Player.STATE_IDLE -> "idle"
        Player.STATE_BUFFERING -> "buffering"
        Player.STATE_READY -> "ready"
        Player.STATE_ENDED -> "ended"
        else -> "unknown"
    }

    private fun statusPayload(reason: String): Map<String, Any?> = mapOf(
        "type" to "status",
        "reason" to reason,
        "state" to playbackStateLabel(),
        "playing" to player.isPlaying,
        "playWhenReady" to player.playWhenReady,
        "positionMs" to safePositionMs(),
        "durationMs" to safeDurationMs(),
        "bufferedPositionMs" to player.bufferedPosition.coerceAtLeast(0L),
        "volume" to player.volume.toDouble(),
        "audioBoostDb" to (audioBoostMb / 1000),
        "subtitleDelayMs" to subtitleDelayMs,
    )

    private fun emitStatus(reason: String) {
        emitEvent(statusPayload(reason))
    }

    private fun emitEvent(payload: Map<String, Any?>) {
        handler.post {
            if (!disposed) eventSink?.success(payload)
        }
    }
}

@OptIn(UnstableApi::class)
private data class ExternalSubtitle(
    val uri: String,
    val title: String?,
    val language: String?,
) {
    fun toMedia3Configuration(): MediaItem.SubtitleConfiguration {
        val builder = MediaItem.SubtitleConfiguration.Builder(Uri.parse(uri))
            .setMimeType(detectMimeType(uri))
            .setSelectionFlags(C.SELECTION_FLAG_DEFAULT)
        if (!title.isNullOrBlank()) builder.setLabel(title)
        if (!language.isNullOrBlank()) builder.setLanguage(language)
        return builder.build()
    }

    private fun detectMimeType(value: String): String {
        val path = Uri.parse(value).path?.lowercase() ?: value.lowercase()
        return when {
            path.endsWith(".vtt") || path.endsWith(".webvtt") -> MimeTypes.TEXT_VTT
            path.endsWith(".ttml") || path.endsWith(".dfxp") || path.endsWith(".xml") -> MimeTypes.APPLICATION_TTML
            path.endsWith(".ssa") || path.endsWith(".ass") -> MimeTypes.TEXT_SSA
            else -> MimeTypes.APPLICATION_SUBRIP
        }
    }
}

@OptIn(UnstableApi::class)
private class YouTubeTrailerDataSourceFactory(
    private val upstreamFactory: DataSource.Factory,
    private val headers: Map<String, String>,
) : DataSource.Factory {
    private var requestNumber = 0L

    override fun createDataSource(): DataSource = YouTubeTrailerDataSource(
        upstreamFactory.createDataSource(),
        headers,
    ) { requestNumber++ }
}

@OptIn(UnstableApi::class)
private class YouTubeTrailerDataSource(
    private val upstream: DataSource,
    private val headers: Map<String, String>,
    private val nextRequestNumber: () -> Long,
) : BaseDataSource(true) {
    private var connection: HttpURLConnection? = null
    private var inputStream: InputStream? = null
    private var opened = false
    private var currentDataSpec: DataSpec? = null
    private var responseCode = -1
    private var responseHeaders: Map<String, List<String>> = emptyMap()
    private var bytesToRead = C.LENGTH_UNSET.toLong()
    private var bytesRead = 0L

    @Throws(IOException::class)
    override fun open(dataSpec: DataSpec): Long {
        if (!isYouTubeVideoPlayback(dataSpec.uri) || dataSpec.httpMethod != DataSpec.HTTP_METHOD_GET) {
            return upstream.open(dataSpec)
        }

        currentDataSpec = dataSpec
        bytesRead = 0L
        transferInitializing(dataSpec)

        val url = URL(buildYouTubeRequestUrl(dataSpec))
        val conn = (url.openConnection() as HttpURLConnection).also {
            it.connectTimeout = 8000
            it.readTimeout = 8000
            it.instanceFollowRedirects = true
            it.requestMethod = "POST"
            it.doOutput = true
            it.setFixedLengthStreamingMode(POST_BODY.size)
            for ((key, value) in headers) {
                if (!key.equals("Range", ignoreCase = true)) {
                    it.setRequestProperty(key, value)
                }
            }
            it.setRequestProperty("Origin", YOUTUBE_BASE_URL)
            it.setRequestProperty("Referer", YOUTUBE_BASE_URL)
            it.setRequestProperty("Sec-Fetch-Dest", "empty")
            it.setRequestProperty("Sec-Fetch-Mode", "cors")
            it.setRequestProperty("Sec-Fetch-Site", "cross-site")
            it.setRequestProperty("TE", "trailers")
            it.setRequestProperty("Accept-Encoding", "identity")
            it.setRequestProperty("User-Agent", YOUTUBE_USER_AGENT)
        }

        conn.connect()
        conn.outputStream.use { output: OutputStream -> output.write(POST_BODY) }

        responseCode = conn.responseCode
        responseHeaders = conn.headerFields
            ?.filterKeys { it != null }
            ?.mapKeys { it.key ?: "" }
            ?: emptyMap()

        if (responseCode !in 200..299) {
            val message = conn.responseMessage ?: "HTTP $responseCode"
            conn.disconnect()
            throw IOException("YouTube trailer request failed: $responseCode $message")
        }

        connection = conn
        inputStream = conn.inputStream
        bytesToRead = if (dataSpec.length != C.LENGTH_UNSET.toLong()) {
            dataSpec.length
        } else {
            conn.contentLengthLong.takeIf { it >= 0L } ?: C.LENGTH_UNSET.toLong()
        }
        opened = true
        transferStarted(dataSpec)
        return bytesToRead
    }

    override fun read(buffer: ByteArray, offset: Int, length: Int): Int {
        if (!opened) return upstream.read(buffer, offset, length)
        if (length == 0) return 0
        val stream = inputStream ?: return C.RESULT_END_OF_INPUT
        val readLength = if (bytesToRead != C.LENGTH_UNSET.toLong()) {
            val remaining = bytesToRead - bytesRead
            if (remaining <= 0L) return C.RESULT_END_OF_INPUT
            min(length.toLong(), remaining).toInt()
        } else {
            length
        }
        val read = stream.read(buffer, offset, readLength)
        if (read == -1) return C.RESULT_END_OF_INPUT
        bytesRead += read.toLong()
        bytesTransferred(read)
        return read
    }

    override fun getUri(): Uri? = connection?.url?.toString()?.let(Uri::parse) ?: upstream.uri

    override fun getResponseHeaders(): Map<String, List<String>> = if (opened) responseHeaders else upstream.responseHeaders

    @Throws(IOException::class)
    override fun close() {
        if (!opened) {
            upstream.close()
            return
        }
        try {
            inputStream?.close()
        } finally {
            inputStream = null
            connection?.disconnect()
            connection = null
            if (opened) {
                opened = false
                transferEnded()
            }
        }
    }

    private fun isYouTubeVideoPlayback(uri: Uri): Boolean {
        val host = uri.host ?: return false
        return uri.path?.contains("/videoplayback") == true && host.contains("googlevideo.com")
    }

    private fun buildYouTubeRequestUrl(dataSpec: DataSpec): String {
        val rangeValue = if (dataSpec.length != C.LENGTH_UNSET.toLong() && dataSpec.length > 0L) {
            "${dataSpec.position}-${dataSpec.position + dataSpec.length - 1}"
        } else {
            "${dataSpec.position}-"
        }
        return dataSpec.uri
            .buildUpon()
            .clearQuery()
            .encodedQuery(
                rewriteQuery(dataSpec.uri, mapOf(
                    "range" to rangeValue,
                    "rn" to nextRequestNumber().toString(),
                )),
            )
            .build()
            .toString()
    }

    private fun rewriteQuery(uri: Uri, replacements: Map<String, String>): String {
        val keys = replacements.keys.map { it.lowercase() }.toSet()
        val encodedPairs = uri.encodedQuery
            ?.split('&')
            ?.filter { it.isNotEmpty() && it.substringBefore('=').lowercase() !in keys }
            ?: emptyList()
        val rewritten = encodedPairs.toMutableList()
        for ((key, value) in replacements) {
            rewritten.add("$key=${Uri.encode(value)}")
        }
        return rewritten.joinToString("&")
    }

    companion object {
        private const val YOUTUBE_BASE_URL = "https://www.youtube.com"
        private const val YOUTUBE_USER_AGENT =
            "Mozilla/5.0 (Linux; Android 12; Android TV) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Mobile Safari/537.36"
        private val POST_BODY = byteArrayOf(0x78, 0)
    }
}
