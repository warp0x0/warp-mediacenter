package com.warp.warp_mediacenter_client.player

import android.content.Context
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.SurfaceHolder
import androidx.media3.common.C
import androidx.media3.common.MediaItem
import androidx.media3.common.MimeTypes
import androidx.media3.common.PlaybackException
import androidx.media3.common.Player
import androidx.media3.common.TrackSelectionOverride
import androidx.media3.common.Tracks
import androidx.media3.common.VideoSize
import androidx.media3.common.text.CueGroup
import androidx.media3.datasource.DefaultDataSource
import androidx.media3.datasource.DefaultHttpDataSource
import androidx.media3.exoplayer.DefaultLoadControl
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.analytics.AnalyticsListener
import androidx.media3.exoplayer.source.DefaultMediaSourceFactory
import androidx.media3.exoplayer.source.LoadEventInfo
import androidx.media3.exoplayer.source.MediaLoadData
import androidx.media3.exoplayer.source.MediaSource
import androidx.media3.exoplayer.source.MergingMediaSource
import androidx.media3.exoplayer.source.SingleSampleMediaSource
import androidx.media3.ui.CaptionStyleCompat
import androidx.media3.ui.SubtitleView
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.IOException

private const val TAG = "WarpExoPlayerController"
private const val POSITION_UPDATE_INTERVAL_MS = 250L

/**
 * Owns the ExoPlayer instance for one native player surface.
 *
 * Full playback contract (play/pause/seek/volume/speed/audio tracks) plus
 * position/video-size/error/completed/tracksChanged events (M2). Demuxed
 * video+audio pairing via MergingMediaSource (M4) — used only by the
 * YouTube/trailer path; movies/episodes from the backend are always a
 * single muxed URL. Subtitles (M5) render natively via [subtitleView] —
 * ExoPlayer's onCues callback feeds it directly, composited by Android's
 * HWC in the same pass as the video SurfaceView, immune to Flutter-side
 * jank (see the native player implementation plan's Context section for
 * why this was chosen over a Flutter-rendered subtitle overlay).
 */
class WarpExoPlayerController(
    private val context: Context,
    private val methodChannel: MethodChannel,
    private val subtitleView: SubtitleView,
) : MethodChannel.MethodCallHandler {

    private var exoPlayer: ExoPlayer? = null
    private var surfaceHolder: SurfaceHolder? = null
    private var eventSink: EventChannel.EventSink? = null

    private val mainHandler = Handler(Looper.getMainLooper())
    private var tickerRunning = false
    private val positionTicker = object : Runnable {
        override fun run() {
            emitPositionUpdate()
            if (tickerRunning) mainHandler.postDelayed(this, POSITION_UPDATE_INTERVAL_MS)
        }
    }

    // Positive values (subtitles appear later) are implemented exactly via
    // a post-delayed relay of onCues. Negative values (subtitles appear
    // earlier / "hastened") would need look-ahead cue timing that the
    // push-based onCues callback doesn't provide, so they're approximated
    // as zero delay rather than guessed at — flagged here rather than
    // silently wrong. Revisit if this proves to matter in practice.
    private var subtitleDelayMs: Long = 0

    init {
        methodChannel.setMethodCallHandler(this)
        applyDefaultSubtitleStyle()
    }

    fun attachEventSink(sink: EventChannel.EventSink?) {
        eventSink = sink
    }

    fun onSurfaceCreated(holder: SurfaceHolder) {
        surfaceHolder = holder
        exoPlayer?.setVideoSurfaceHolder(holder)
    }

    fun onSurfaceDestroyed() {
        val destroyedHolder = surfaceHolder
        surfaceHolder = null
        exoPlayer?.clearVideoSurfaceHolder(destroyedHolder)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        Log.d(TAG, "onMethodCall: ${call.method} args=${call.arguments}")
        when (call.method) {
            "setDataSource" -> handleSetDataSource(call, result)
            "play" -> {
                ensurePlayer().play()
                result.success(null)
            }
            "pause" -> {
                exoPlayer?.pause()
                result.success(null)
            }
            "seekTo" -> {
                val positionMs = call.argument<Number>("positionMs")?.toLong()
                if (positionMs == null) {
                    result.error("invalid_args", "positionMs is required", null)
                    return
                }
                exoPlayer?.seekTo(positionMs)
                result.success(null)
            }
            "setVolume" -> {
                val volume = call.argument<Number>("volume")?.toFloat()
                if (volume == null) {
                    result.error("invalid_args", "volume is required", null)
                    return
                }
                exoPlayer?.volume = volume.coerceIn(0f, 1f)
                result.success(null)
            }
            "setPlaybackSpeed" -> {
                val speed = call.argument<Number>("speed")?.toFloat()
                if (speed == null) {
                    result.error("invalid_args", "speed is required", null)
                    return
                }
                exoPlayer?.setPlaybackSpeed(speed)
                result.success(null)
            }
            "getTracks" -> result.success(currentTracksMap())
            "selectAudioTrack" -> {
                val trackId = call.argument<String>("trackId")
                if (trackId == null) {
                    result.error("invalid_args", "trackId is required", null)
                    return
                }
                selectAudioTrack(trackId)
                result.success(null)
            }
            "addExternalSubtitle" -> handleAddExternalSubtitle(call, result)
            "selectSubtitleTrack" -> {
                selectSubtitleTrack(call.argument<String>("trackId"))
                result.success(null)
            }
            "setSubtitleDelayMs" -> {
                subtitleDelayMs = call.argument<Number>("delayMs")?.toLong() ?: 0L
                result.success(null)
            }
            "configureSubtitleStyle" -> {
                applySubtitleStyle(call)
                result.success(null)
            }
            "dispose" -> {
                release()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    // DefaultMediaSourceFactory auto-detects container (progressive MP4,
    // HLS, DASH) per URL via Util.inferContentType — no manual
    // ProgressiveMediaSource wiring needed for either the muxed or demuxed
    // path.
    //
    // Two separate factories, deliberately not unified: youtubeMediaSourceFactory
    // wraps the HTTP data source with YoutubeRangeParamDataSource (rewrites
    // "/videoplayback" requests to avoid YouTube's Range-header-triggered CDN
    // throttling — see that class's doc comment), while mediaSourceFactory
    // stays exactly as it was before that wrapper existed. Routing every
    // request through the wrapped factory (tried and reverted 2026-07-18)
    // broke the local backend's movie streams entirely — every bundled
    // extractor failed to sniff the container even though the wrapper's
    // open() override should have passed non-videoplayback URLs straight
    // through to the delegate unchanged. Root cause not fully isolated;
    // confining the wrapper to confirmed-YouTube URLs sidesteps it rather
    // than risk further backend regressions chasing it down.
    private val dataSourceFactory by lazy { DefaultDataSource.Factory(context) }
    private val mediaSourceFactory by lazy { DefaultMediaSourceFactory(dataSourceFactory) }
    private val youtubeDataSourceFactory by lazy {
        DefaultDataSource.Factory(
            context,
            YoutubeRangeParamDataSource.Factory(DefaultHttpDataSource.Factory()),
        )
    }
    private val youtubeMediaSourceFactory by lazy {
        DefaultMediaSourceFactory(youtubeDataSourceFactory)
    }

    private fun mediaSourceFactoryFor(url: String): DefaultMediaSourceFactory =
        if (url.contains("videoplayback")) youtubeMediaSourceFactory else mediaSourceFactory

    // The video+audio source, without subtitles — kept so addExternalSubtitle
    // can rebuild the merged source (base + all external subtitle sources
    // added so far) without needing a fresh setDataSource call.
    private var baseMediaSource: MediaSource? = null
    private val externalSubtitleSources = mutableListOf<MediaSource>()

    private fun handleSetDataSource(call: MethodCall, result: MethodChannel.Result) {
        val muxedUrl = call.argument<String>("muxedUrl")
        val videoUrl = call.argument<String>("videoUrl")
        val audioUrl = call.argument<String>("audioUrl")
        val startPositionMs = call.argument<Number>("startPositionMs")?.toLong()

        externalSubtitleSources.clear()

        if (!muxedUrl.isNullOrEmpty()) {
            val source = mediaSourceFactoryFor(muxedUrl).createMediaSource(MediaItem.fromUri(muxedUrl))
            baseMediaSource = source
            setDataSource(source, startPositionMs)
            result.success(null)
            return
        }
        if (!videoUrl.isNullOrEmpty() && !audioUrl.isNullOrEmpty()) {
            // MergingMediaSource synchronizes the two by period/duration
            // automatically — no manual PTS alignment needed. Used only by
            // the YouTube/trailer path (movies/episodes from the backend are
            // always a single muxed URL); see youtube_stream_selector.dart.
            val videoSource = mediaSourceFactoryFor(videoUrl).createMediaSource(MediaItem.fromUri(videoUrl))
            val audioSource = mediaSourceFactoryFor(audioUrl).createMediaSource(MediaItem.fromUri(audioUrl))
            val merged: MediaSource = MergingMediaSource(videoSource, audioSource)
            baseMediaSource = merged
            setDataSource(merged, startPositionMs)
            result.success(null)
            return
        }
        result.error(
            "invalid_args",
            "muxedUrl or videoUrl+audioUrl is required",
            null,
        )
    }

    private fun ensurePlayer(): ExoPlayer {
        var player = exoPlayer
        if (player == null) {
            Log.d(TAG, "ensurePlayer: building new ExoPlayer, surfaceHolder=$surfaceHolder")
            // Media3's DefaultLoadControl default of 5000ms for
            // bufferForPlaybackAfterRebufferMs means every seek (treated as
            // a rebuffer) waits a full 5s of freshly-buffered media before
            // resuming, regardless of how fast the range request itself
            // completes. Lowered here for a snappier seek/rebuffer resume;
            // min/max buffer stay at defaults (steady-state playback is
            // unaffected, only the post-seek/rebuffer resume threshold).
            //
            // (A much larger min/max buffer target was tried here first as a
            // workaround for the YouTube trailer freeze, but made no
            // difference — root cause was CDN-side rate pacing keyed off
            // ExoPlayer's HTTP Range header, fixed properly in
            // YoutubeRangeParamDataSource.kt instead. Reverted to defaults
            // to avoid needlessly buffering tens/hundreds of MB ahead on
            // this 2GB-RAM device, especially for high-bitrate 4K streams.)
            val loadControl = DefaultLoadControl.Builder()
                .setBufferDurationsMs(
                    DefaultLoadControl.DEFAULT_MIN_BUFFER_MS,
                    DefaultLoadControl.DEFAULT_MAX_BUFFER_MS,
                    1000,
                    1500,
                )
                .build()
            player = ExoPlayer.Builder(context)
                .setLoadControl(loadControl)
                .build()
            player.addListener(playerListener)
            player.addAnalyticsListener(loadDiagnosticsListener)
            surfaceHolder?.let { player.setVideoSurfaceHolder(it) }
            exoPlayer = player
        }
        return player
    }

    private fun setDataSource(source: MediaSource, startPositionMs: Long?) {
        Log.d(TAG, "setDataSource: startPositionMs=$startPositionMs")
        val player = ensurePlayer()
        player.setMediaSource(source)
        if (startPositionMs != null && startPositionMs > 0) {
            player.seekTo(startPositionMs)
        }
        player.prepare()
        Log.d(TAG, "setDataSource: prepare() called")
    }

    // Audio track ids are derived, not persistent — stable only for the
    // lifetime of one prepared MediaItem, which matches how they're used
    // (fetched via getTracks/tracksChanged, then immediately passed back to
    // selectAudioTrack within the same session).
    private fun audioTrackId(group: Tracks.Group, index: Int): String {
        val format = group.getTrackFormat(index)
        return "audio-${System.identityHashCode(group.mediaTrackGroup)}-$index-${format.id ?: index}"
    }

    private fun textTrackId(group: Tracks.Group, index: Int): String {
        val format = group.getTrackFormat(index)
        return "text-${System.identityHashCode(group.mediaTrackGroup)}-$index-${format.id ?: index}"
    }

    private fun selectAudioTrack(trackId: String) {
        val player = exoPlayer ?: return
        for (group in player.currentTracks.groups) {
            if (group.type != C.TRACK_TYPE_AUDIO) continue
            for (i in 0 until group.length) {
                if (audioTrackId(group, i) != trackId) continue
                val override = TrackSelectionOverride(group.mediaTrackGroup, i)
                player.trackSelectionParameters = player.trackSelectionParameters
                    .buildUpon()
                    .setOverrideForType(override)
                    .build()
                return
            }
        }
    }

    private fun selectSubtitleTrack(trackId: String?) {
        val player = exoPlayer ?: return
        if (trackId == null) {
            player.trackSelectionParameters = player.trackSelectionParameters
                .buildUpon()
                .setTrackTypeDisabled(C.TRACK_TYPE_TEXT, true)
                .build()
            return
        }
        for (group in player.currentTracks.groups) {
            if (group.type != C.TRACK_TYPE_TEXT) continue
            for (i in 0 until group.length) {
                if (textTrackId(group, i) != trackId) continue
                val override = TrackSelectionOverride(group.mediaTrackGroup, i)
                player.trackSelectionParameters = player.trackSelectionParameters
                    .buildUpon()
                    .setTrackTypeDisabled(C.TRACK_TYPE_TEXT, false)
                    .setOverrideForType(override)
                    .build()
                return
            }
        }
    }

    private fun subtitleMimeType(uri: String): String {
        return when {
            uri.endsWith(".vtt", ignoreCase = true) -> MimeTypes.TEXT_VTT
            uri.endsWith(".ass", ignoreCase = true) ||
                uri.endsWith(".ssa", ignoreCase = true) -> MimeTypes.TEXT_SSA
            // SRT is the common case for backend-downloaded subtitle files;
            // also the safe default for an unrecognized extension.
            else -> MimeTypes.APPLICATION_SUBRIP
        }
    }

    private fun handleAddExternalSubtitle(call: MethodCall, result: MethodChannel.Result) {
        val player = exoPlayer
        val base = baseMediaSource
        val uri = call.argument<String>("uri")
        if (player == null || base == null || uri.isNullOrEmpty()) {
            result.error("invalid_state", "setDataSource must be called before addExternalSubtitle", null)
            return
        }
        val title = call.argument<String>("title")
        val language = call.argument<String>("language")

        val subtitleConfig = MediaItem.SubtitleConfiguration.Builder(Uri.parse(uri))
            .setMimeType(subtitleMimeType(uri))
            .apply {
                if (!language.isNullOrEmpty()) setLanguage(language)
                if (!title.isNullOrEmpty()) setLabel(title)
            }
            .build()
        val durationUs = player.duration.let { if (it == C.TIME_UNSET) C.TIME_UNSET else it * 1000 }
        val subtitleSource = SingleSampleMediaSource.Factory(dataSourceFactory)
            .createMediaSource(subtitleConfig, durationUs)

        externalSubtitleSources.add(subtitleSource)
        val merged: MediaSource = MergingMediaSource(
            base,
            *externalSubtitleSources.toTypedArray(),
        )
        val resumePositionMs = player.currentPosition
        val expectedTextGroupCount = externalSubtitleSources.size

        // Resolve only once the new track is actually selectable (matches
        // the same "don't hand back a track that isn't ready yet" contract
        // subtitle_dialog.dart currently has to poll for with mpv) — the
        // newly-added source is always the LAST text track group after
        // rebuild, since MergingMediaSource preserves source order.
        var pendingListener: Player.Listener? = null
        pendingListener = object : Player.Listener {
            override fun onTracksChanged(tracks: Tracks) {
                val textGroups = tracks.groups.filter { it.type == C.TRACK_TYPE_TEXT }
                if (textGroups.size < expectedTextGroupCount) return
                val newGroup = textGroups.last()
                val newTrackId = textTrackId(newGroup, 0)
                player.removeListener(pendingListener!!)
                result.success(mapOf("trackId" to newTrackId))
            }
        }
        player.addListener(pendingListener)
        player.setMediaSource(merged, resumePositionMs)
        player.prepare()
    }

    private fun applyDefaultSubtitleStyle() {
        // Matches today's fixed Dart TextStyle in playback_page.dart
        // (SubtitleViewConfiguration: white text, black drop shadow,
        // bottom-anchored, no background box) so the native path looks the
        // same as the media_kit path by default, before SubtitleDialog
        // (M6/M7) ever calls configureSubtitleStyle explicitly.
        subtitleView.setStyle(
            CaptionStyleCompat(
                android.graphics.Color.WHITE,
                android.graphics.Color.TRANSPARENT,
                android.graphics.Color.TRANSPARENT,
                CaptionStyleCompat.EDGE_TYPE_DROP_SHADOW,
                android.graphics.Color.argb(221, 0, 0, 0),
                null,
            ),
        )
        subtitleView.setFractionalTextSize(SubtitleView.DEFAULT_TEXT_SIZE_FRACTION * 1.3f)
        subtitleView.setBottomPaddingFraction(0.08f)
    }

    private fun applySubtitleStyle(call: MethodCall) {
        val fontSizeFraction = call.argument<Number>("fontSizeFraction")?.toFloat()
        val textColor = call.argument<Number>("textColor")?.toInt()
        val edgeColor = call.argument<Number>("edgeColor")?.toInt()
        val bottomPaddingFraction = call.argument<Number>("bottomPaddingFraction")?.toFloat()

        if (fontSizeFraction != null) subtitleView.setFractionalTextSize(fontSizeFraction)
        if (bottomPaddingFraction != null) subtitleView.setBottomPaddingFraction(bottomPaddingFraction)
        if (textColor != null || edgeColor != null) {
            subtitleView.setStyle(
                CaptionStyleCompat(
                    textColor ?: android.graphics.Color.WHITE,
                    android.graphics.Color.TRANSPARENT,
                    android.graphics.Color.TRANSPARENT,
                    CaptionStyleCompat.EDGE_TYPE_DROP_SHADOW,
                    edgeColor ?: android.graphics.Color.argb(221, 0, 0, 0),
                    null,
                ),
            )
        }
    }

    private fun currentTracksMap(): Map<String, Any> {
        val audio = mutableListOf<Map<String, Any?>>()
        val textGroups = mutableListOf<Tracks.Group>()
        exoPlayer?.currentTracks?.groups?.forEach { group ->
            when (group.type) {
                C.TRACK_TYPE_AUDIO -> for (i in 0 until group.length) {
                    val format = group.getTrackFormat(i)
                    audio.add(
                        mapOf(
                            "id" to audioTrackId(group, i),
                            "language" to format.language,
                            "label" to format.label,
                            "codec" to format.sampleMimeType,
                            "channels" to format.channelCount,
                            "bitrate" to format.bitrate,
                            "selected" to group.isTrackSelected(i),
                        ),
                    )
                }
                C.TRACK_TYPE_TEXT -> textGroups.add(group)
                else -> {}
            }
        }
        // MergingMediaSource preserves source order (base first, then each
        // external subtitle source appended in the order added), so the
        // last externalSubtitleSources.size text groups are always the
        // externally-added ones — any earlier text groups are embedded in
        // the container itself.
        val externalStartIndex = (textGroups.size - externalSubtitleSources.size).coerceAtLeast(0)
        val text = textGroups.flatMapIndexed { groupIndex, group ->
            (0 until group.length).map { i ->
                val format = group.getTrackFormat(i)
                mapOf(
                    "id" to textTrackId(group, i),
                    "language" to format.language,
                    "label" to format.label,
                    "isExternal" to (groupIndex >= externalStartIndex),
                    "selected" to group.isTrackSelected(i),
                )
            }
        }
        return mapOf("audio" to audio, "text" to text)
    }

    private fun startPositionTicker() {
        if (tickerRunning) return
        tickerRunning = true
        mainHandler.post(positionTicker)
    }

    private fun stopPositionTicker() {
        tickerRunning = false
        mainHandler.removeCallbacks(positionTicker)
    }

    private fun emitPositionUpdate() {
        val player = exoPlayer ?: return
        val duration = player.duration
        Log.d(
            TAG,
            "position=${player.currentPosition} buffered=${player.bufferedPosition} " +
                "playbackState=${player.playbackState} isLoading=${player.isLoading} " +
                "isPlaying=${player.isPlaying}",
        )
        eventSink?.success(
            mapOf(
                "event" to "positionUpdate",
                "positionMs" to player.currentPosition,
                "bufferedPositionMs" to player.bufferedPosition,
                "durationMs" to (if (duration == C.TIME_UNSET) 0L else duration),
            ),
        )
    }

    // Temporary diagnostics (2026-07-18) for the on-device trailer-freeze
    // investigation — confirms whether HTTP loads are actually erroring/
    // stalling vs. something else (decoder/renderer-side) causing the
    // reported freeze. Remove once root cause is confirmed and fixed.
    private val loadDiagnosticsListener = object : AnalyticsListener {
        override fun onLoadStarted(
            eventTime: AnalyticsListener.EventTime,
            loadEventInfo: LoadEventInfo,
            mediaLoadData: MediaLoadData,
        ) {
            Log.d(TAG, "onLoadStarted: dataType=${mediaLoadData.dataType} uri=${loadEventInfo.uri}")
        }

        override fun onLoadCompleted(
            eventTime: AnalyticsListener.EventTime,
            loadEventInfo: LoadEventInfo,
            mediaLoadData: MediaLoadData,
        ) {
            Log.d(
                TAG,
                "onLoadCompleted: dataType=${mediaLoadData.dataType} " +
                    "bytesLoaded=${loadEventInfo.bytesLoaded} loadDurationMs=${loadEventInfo.loadDurationMs}",
            )
        }

        override fun onLoadCanceled(
            eventTime: AnalyticsListener.EventTime,
            loadEventInfo: LoadEventInfo,
            mediaLoadData: MediaLoadData,
        ) {
            Log.d(
                TAG,
                "onLoadCanceled: dataType=${mediaLoadData.dataType} bytesLoaded=${loadEventInfo.bytesLoaded}",
            )
        }

        override fun onLoadError(
            eventTime: AnalyticsListener.EventTime,
            loadEventInfo: LoadEventInfo,
            mediaLoadData: MediaLoadData,
            error: IOException,
            wasCanceled: Boolean,
        ) {
            Log.w(
                TAG,
                "onLoadError: dataType=${mediaLoadData.dataType} wasCanceled=$wasCanceled error=$error",
                error,
            )
        }

        override fun onBandwidthEstimate(
            eventTime: AnalyticsListener.EventTime,
            totalLoadTimeMs: Int,
            totalBytesLoaded: Long,
            bitrateEstimate: Long,
        ) {
            Log.d(TAG, "bandwidthEstimate: ${bitrateEstimate / 1000} kbps")
        }
    }

    private val playerListener = object : Player.Listener {
        override fun onPlaybackStateChanged(playbackState: Int) {
            val state = when (playbackState) {
                Player.STATE_IDLE -> "idle"
                Player.STATE_BUFFERING -> "buffering"
                Player.STATE_READY -> "ready"
                Player.STATE_ENDED -> "ended"
                else -> "idle"
            }
            Log.d(TAG, "state -> $state")
            eventSink?.success(mapOf("event" to "stateChanged", "state" to state))
            if (playbackState == Player.STATE_ENDED) {
                stopPositionTicker()
                eventSink?.success(mapOf("event" to "completed"))
            }
        }

        override fun onIsPlayingChanged(isPlaying: Boolean) {
            if (isPlaying) startPositionTicker() else stopPositionTicker()
            eventSink?.success(mapOf("event" to "playingChanged", "playing" to isPlaying))
        }

        override fun onVideoSizeChanged(videoSize: VideoSize) {
            Log.d(TAG, "videoSizeChanged: ${videoSize.width}x${videoSize.height}")
            eventSink?.success(
                mapOf(
                    "event" to "videoSizeChanged",
                    "width" to videoSize.width,
                    "height" to videoSize.height,
                    "rotationDegrees" to videoSize.unappliedRotationDegrees,
                ),
            )
        }

        override fun onTracksChanged(tracks: Tracks) {
            val payload = HashMap<String, Any>(currentTracksMap())
            payload["event"] = "tracksChanged"
            eventSink?.success(payload)
        }

        override fun onCues(cueGroup: CueGroup) {
            // Native rendering, composited by Android's HWC in the same
            // pass as the video SurfaceView — never touches Flutter's
            // frame pipeline. See the class doc comment for why.
            if (subtitleDelayMs > 0) {
                mainHandler.postDelayed({ subtitleView.setCues(cueGroup.cues) }, subtitleDelayMs)
            } else {
                subtitleView.setCues(cueGroup.cues)
            }
        }

        override fun onPlayerError(error: PlaybackException) {
            Log.e(TAG, "player error", error)
            stopPositionTicker()
            eventSink?.success(
                mapOf(
                    "event" to "error",
                    "code" to error.errorCode.toString(),
                    "message" to (error.message ?: "unknown"),
                    "isRecoverable" to false,
                ),
            )
        }
    }

    fun release() {
        stopPositionTicker()
        exoPlayer?.removeListener(playerListener)
        exoPlayer?.release()
        exoPlayer = null
        surfaceHolder = null
        baseMediaSource = null
        externalSubtitleSources.clear()
        methodChannel.setMethodCallHandler(null)
    }
}
