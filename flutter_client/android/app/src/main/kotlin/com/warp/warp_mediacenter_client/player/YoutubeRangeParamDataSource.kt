package com.warp.warp_mediacenter_client.player

import androidx.media3.common.C
import androidx.media3.datasource.DataSpec
import androidx.media3.datasource.DefaultHttpDataSource
import androidx.media3.datasource.HttpDataSource

/**
 * Works around YouTube's CDN server-side rate-pacing of "/videoplayback"
 * requests that use the standard HTTP `Range` header. YouTube instead
 * expects the byte range as a `range=<start>-<end>` URL QUERY PARAMETER,
 * serving those at full speed — documented in yt-dlp issue #6369 and fixed
 * the same way by NewPipe's YoutubeHttpDataSource. ExoPlayer's
 * DefaultHttpDataSource always sends a real `Range` header for any partial
 * read, which is exactly what on-device diagnostics traced our trailer
 * freeze to: buffered-position margin collapsing to near-zero a fixed
 * ~10-15s into every YouTube trailer, deterministically, with no load
 * error ever raised (ratebypass=yes and larger ExoPlayer buffer targets
 * made no difference — this is a server-side pacing schedule keyed off the
 * Range header's presence, not something client-side buffering can outrun).
 *
 * Only rewrites requests whose path contains "videoplayback" — the local
 * backend's preload-session stream URLs are untouched and behave exactly
 * as before.
 */
class YoutubeRangeParamDataSource private constructor(
    private val upstream: DefaultHttpDataSource,
) : HttpDataSource by upstream {

    class Factory(
        private val upstreamFactory: DefaultHttpDataSource.Factory,
    ) : HttpDataSource.Factory {
        override fun createDataSource(): HttpDataSource =
            YoutubeRangeParamDataSource(upstreamFactory.createDataSource())

        override fun setDefaultRequestProperties(
            defaultRequestProperties: MutableMap<String, String>,
        ): HttpDataSource.Factory {
            upstreamFactory.setDefaultRequestProperties(defaultRequestProperties)
            return this
        }
    }

    override fun open(dataSpec: DataSpec): Long {
        val path = dataSpec.uri.path
        if (path == null || !path.contains("videoplayback") || dataSpec.position < 0) {
            return upstream.open(dataSpec)
        }

        val endInclusive = if (dataSpec.length != C.LENGTH_UNSET.toLong()) {
            dataSpec.position + dataSpec.length - 1
        } else {
            null
        }
        val rangeParam = "range=${dataSpec.position}-${endInclusive ?: ""}"
        val existingQuery = dataSpec.uri.encodedQuery
        val newQuery = if (existingQuery.isNullOrEmpty()) rangeParam else "$existingQuery&$rangeParam"
        val newUri = dataSpec.uri.buildUpon().encodedQuery(newQuery).build()

        // Position/length reset to 0/UNSET — the range is now fully described
        // by the URL query param, so this becomes a plain (non-partial)
        // request from the underlying DefaultHttpDataSource's perspective;
        // the server responds with exactly the requested span starting at
        // byte 0 of this response, which ExoPlayer reads sequentially same
        // as any genuine 206 Partial Content response.
        val rewritten = dataSpec.buildUpon()
            .setUri(newUri)
            .setPosition(0)
            .setLength(C.LENGTH_UNSET.toLong())
            .build()
        return upstream.open(rewritten)
    }
}
