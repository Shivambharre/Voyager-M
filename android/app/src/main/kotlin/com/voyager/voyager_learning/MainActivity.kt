package com.voyager.voyager_learning

import android.content.Intent
import android.net.Uri
import android.os.Handler
import android.os.Looper
import androidx.media3.common.MediaItem
import androidx.media3.common.PlaybackParameters
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.source.DefaultMediaSourceFactory
import androidx.media3.exoplayer.source.MergingMediaSource
import androidx.media3.exoplayer.source.MediaSource
import androidx.media3.ui.PlayerView
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import org.schabi.newpipe.extractor.NewPipe
import org.schabi.newpipe.extractor.downloader.Downloader
import org.schabi.newpipe.extractor.downloader.Request
import org.schabi.newpipe.extractor.downloader.Response
import org.schabi.newpipe.extractor.playlist.PlaylistInfo
import java.io.IOException
import java.net.HttpURLConnection
import java.net.URL
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
	private val extractionExecutor = Executors.newSingleThreadExecutor()
	private val mainHandler = Handler(Looper.getMainLooper())
	private lateinit var mediaPlayer: ExoPlayer
	private var shareEventSink: EventChannel.EventSink? = null
	private var pendingSharedText: String? = null

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)
		EventChannel(flutterEngine.dartExecutor.binaryMessenger, SHARE_CHANNEL)
			.setStreamHandler(object : EventChannel.StreamHandler {
				override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
					shareEventSink = events
					val sharedText = pendingSharedText ?: sharedTextFrom(intent)
					pendingSharedText = null
					if (sharedText != null) {
						events.success(sharedText)
						clearSharedText(intent)
					}
				}

				override fun onCancel(arguments: Any?) {
					shareEventSink = null
				}
			})
		mediaPlayer = ExoPlayer.Builder(this).build()
		flutterEngine.platformViewsController.registry.registerViewFactory(
			PLAYER_VIEW_TYPE,
			NativePlayerViewFactory(mediaPlayer),
		)
		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PLAYER_CHANNEL)
			.setMethodCallHandler { call, result ->
				try {
					when (call.method) {
						"load" -> {
							val videoUrl = call.argument<String>("videoUrl")
							if (videoUrl.isNullOrBlank()) {
								result.error("invalid_url", "A video URL is required.", null)
								return@setMethodCallHandler
							}
							val videoSource = mediaSource(videoUrl)
							val audioUrl = call.argument<String>("audioUrl")
							val source = if (audioUrl.isNullOrBlank()) {
								videoSource
							} else {
								MergingMediaSource(videoSource, mediaSource(audioUrl))
							}
							mediaPlayer.setMediaSource(source)
							mediaPlayer.prepare()
							result.success(null)
						}
						"play" -> {
							mediaPlayer.play()
							result.success(null)
						}
						"pause" -> {
							mediaPlayer.pause()
							result.success(null)
						}
						"seekTo" -> {
							mediaPlayer.seekTo(call.argument<Number>("positionMs")?.toLong() ?: 0L)
							result.success(null)
						}
						"setPlaybackSpeed" -> {
							val speed = call.argument<Number>("speed")?.toFloat()
								?: throw IllegalArgumentException("Playback speed is required.")
							mediaPlayer.playbackParameters = PlaybackParameters(speed)
							result.success(null)
						}
						"getState" -> result.success(playerState())
						else -> result.notImplemented()
					}
				} catch (error: Exception) {
					result.error("player_error", error.message, null)
				}
			}
		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SHARE_ACTION_CHANNEL)
			.setMethodCallHandler { call, result ->
				if (call.method != "shareUrl") {
					result.notImplemented()
					return@setMethodCallHandler
				}
				val url = call.argument<String>("url")
				val title = call.argument<String>("title") ?: "Share learning link"
				val uri = url?.let(Uri::parse)
				if (uri == null ||
					(uri.scheme != "http" && uri.scheme != "https") ||
					uri.host.isNullOrBlank()
				) {
					result.error("invalid_url", "A valid HTTP(S) link is required.", null)
					return@setMethodCallHandler
				}
				val shareIntent = Intent(Intent.ACTION_SEND).apply {
					type = "text/plain"
					putExtra(Intent.EXTRA_TEXT, uri.toString())
					putExtra(Intent.EXTRA_TITLE, title)
				}
				try {
					startActivity(Intent.createChooser(shareIntent, title))
					result.success(null)
				} catch (error: Exception) {
					result.error("share_failed", error.message, null)
				}
			}
		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
			.setMethodCallHandler { call, result ->
				if (call.method != "resolveVideo" &&
					call.method != "resolvePlaylist" &&
					call.method != "resolveStreams"
				) {
					result.notImplemented()
					return@setMethodCallHandler
				}

				val sourceUrl = call.argument<String>("url")
				if (sourceUrl.isNullOrBlank()) {
					result.error("invalid_url", "A video URL is required.", null)
					return@setMethodCallHandler
				}

				extractionExecutor.execute {
					try {
						val info = when (call.method) {
							"resolveVideo" -> resolveVideo(sourceUrl)
							"resolvePlaylist" -> resolvePlaylist(sourceUrl)
							else -> resolveStreams(sourceUrl)
						}
						mainHandler.post { result.success(info) }
					} catch (error: Exception) {
						mainHandler.post {
							result.error("extraction_failed", error.message, null)
						}
					}
				}
			}
	}

	override fun onNewIntent(intent: Intent) {
		super.onNewIntent(intent)
		setIntent(intent)
		val sharedText = sharedTextFrom(intent) ?: return
		val sink = shareEventSink
		if (sink == null) {
			pendingSharedText = sharedText
		} else {
			sink.success(sharedText)
		}
		clearSharedText(intent)
	}

	private fun sharedTextFrom(intent: Intent?): String? {
		if (intent?.action != Intent.ACTION_SEND ||
			intent.type != "text/plain"
		) {
			return null
		}
		return intent.getCharSequenceExtra(Intent.EXTRA_TEXT)
			?.toString()
			?.takeIf { it.isNotBlank() }
	}

	private fun clearSharedText(intent: Intent?) {
		if (intent?.action != Intent.ACTION_SEND) return
		intent.removeExtra(Intent.EXTRA_TEXT)
	}

	private fun resolveVideo(sourceUrl: String): Map<String, Any?> {
		NewPipeExtractorRuntime.initialize()
		val extractor = NewPipe.getServiceByUrl(sourceUrl).getStreamExtractor(sourceUrl)
		extractor.fetchPage()
		return mapOf(
			"id" to extractor.id,
			"title" to extractor.name,
			"durationSeconds" to extractor.length,
			"author" to extractor.uploaderName,
			"thumbnailUrl" to extractor.thumbnails.firstOrNull()?.url,
			"streams" to mapVideoStreams(extractor),
		)
	}

	private fun resolveStreams(sourceUrl: String): List<Map<String, Any?>> {
		NewPipeExtractorRuntime.initialize()
		val extractor = NewPipe.getServiceByUrl(sourceUrl).getStreamExtractor(sourceUrl)
		extractor.fetchPage()
		return mapVideoStreams(extractor)
	}

	private fun mapVideoStreams(
		extractor: org.schabi.newpipe.extractor.stream.StreamExtractor,
	): List<Map<String, Any?>> {
		val audioStreams = extractor.audioStreams
			.filter { it.isUrl && !it.content.isNullOrBlank() }
		val selectedAudio = selectOriginalAudioTrackIndex(
			audioStreams.map { AudioTrackPreference(it.audioTrackType, it.bitrate) },
		)?.let(audioStreams::get)
		val audioUrl = selectedAudio?.content
		return extractor.videoStreams.mapNotNull { mapVideoStream(it, null) } +
			extractor.videoOnlyStreams.mapNotNull { mapVideoStream(it, audioUrl) }
	}

	private fun mapVideoStream(
		stream: org.schabi.newpipe.extractor.stream.VideoStream,
		audioUrl: String?,
	): Map<String, Any?>? {
		val format = stream.format ?: return null
		val url = stream.content
		if (!stream.isUrl || url.isNullOrBlank()) return null
		if (stream.isVideoOnly && audioUrl.isNullOrBlank()) return null
		return mapOf(
			"url" to url,
			"audioUrl" to audioUrl.takeIf { stream.isVideoOnly },
			"mimeType" to format.mimeType,
			"container" to format.suffix,
			"resolutionHeight" to stream.height.takeIf { it > 0 },
			"bitrateBitsPerSecond" to stream.bitrate.takeIf { it > 0 },
			"hasAudio" to true,
			"hasVideo" to true,
		)
	}

	private fun mediaSource(url: String): MediaSource =
		DefaultMediaSourceFactory(this).createMediaSource(
			MediaItem.fromUri(android.net.Uri.parse(url)),
		)

	private fun playerState(): Map<String, Any?> {
		val status = when {
			mediaPlayer.playerError != null -> "error"
			mediaPlayer.playbackState == ExoPlayer.STATE_BUFFERING -> "loading"
			mediaPlayer.playbackState == ExoPlayer.STATE_ENDED -> "completed"
			mediaPlayer.playWhenReady && mediaPlayer.isPlaying -> "playing"
			mediaPlayer.playbackState == ExoPlayer.STATE_READY -> "paused"
			else -> "idle"
		}
		return mapOf(
			"status" to status,
			"positionMs" to mediaPlayer.currentPosition,
			"durationMs" to (mediaPlayer.duration.takeIf { it >= 0 } ?: 0L),
			"playbackSpeed" to mediaPlayer.playbackParameters.speed,
			"errorMessage" to mediaPlayer.playerError?.message,
		)
	}

	private fun resolvePlaylist(sourceUrl: String): Map<String, Any?> {
		NewPipeExtractorRuntime.initialize()
		val service = NewPipe.getServiceByUrl(sourceUrl)
		val extractor = service.getPlaylistExtractor(sourceUrl)
		extractor.fetchPage()
		val info = PlaylistInfo.getInfo(extractor)
		val entries = mutableListOf<Map<String, Any?>>()

		fun appendItems(items: List<org.schabi.newpipe.extractor.stream.StreamInfoItem>) {
			for (item in items) {
				if (entries.size >= MAX_PLAYLIST_ENTRIES) break
				entries.add(
					mapOf<String, Any?>(
						"title" to item.name,
						"url" to item.url,
						"durationSeconds" to item.duration.takeIf { it > 0 },
						"thumbnailUrl" to item.thumbnails.firstOrNull()?.url,
					)
				)
			}
		}

		appendItems(info.relatedItems)
		var nextPage = info.nextPage
		while (nextPage != null && entries.size < MAX_PLAYLIST_ENTRIES) {
			val page = extractor.getPage(nextPage)
			appendItems(page.items)
			nextPage = page.nextPage
		}

		return mapOf<String, Any?>(
			"id" to info.id,
			"url" to info.url,
			"title" to info.name,
			"author" to info.uploaderName.takeIf { it.isNotBlank() },
			"description" to info.description?.getContent(),
			"thumbnailUrl" to (
				info.thumbnails.firstOrNull()?.url
					?: entries.firstOrNull()?.get("thumbnailUrl")
			),
			"entries" to entries,
		)
	}

	override fun onDestroy() {
		extractionExecutor.shutdownNow()
		if (::mediaPlayer.isInitialized) mediaPlayer.release()
		super.onDestroy()
	}

	companion object {
		private const val CHANNEL = "com.voyager/newpipe"
		private const val PLAYER_CHANNEL = "com.voyager/player"
		private const val SHARE_ACTION_CHANNEL = "com.voyager/share_action"
		private const val PLAYER_VIEW_TYPE = "com.voyager/player_view"
		private const val SHARE_CHANNEL = "com.voyager/share"
		private const val MAX_PLAYLIST_ENTRIES = 500
	}
}

private class NativePlayerViewFactory(
	private val player: ExoPlayer,
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
	override fun create(context: android.content.Context, viewId: Int, args: Any?): PlatformView =
		NativePlayerView(context, player)
}

private class NativePlayerView(
	context: android.content.Context,
	player: ExoPlayer,
) : PlatformView {
	private val view = PlayerView(context).apply {
		this.player = player
		useController = false
	}

	override fun getView() = view

	override fun dispose() {
		view.player = null
	}
}

private object NewPipeExtractorRuntime {
	@Volatile
	private var initialized = false

	fun initialize() {
		if (initialized) return
		synchronized(this) {
			if (!initialized) {
				org.schabi.newpipe.extractor.NewPipe.init(HttpUrlConnectionDownloader())
				initialized = true
			}
		}
	}
}

private class HttpUrlConnectionDownloader : Downloader() {
	override fun execute(request: Request): Response {
		val connection = URL(request.url()).openConnection() as HttpURLConnection
		connection.requestMethod = request.httpMethod()
		connection.connectTimeout = 15_000
		connection.readTimeout = 30_000
		connection.instanceFollowRedirects = true
		request.headers().forEach { (name, values) ->
			connection.setRequestProperty(name, values.joinToString(", "))
		}

		try {
			request.dataToSend()?.let { body ->
				connection.doOutput = true
				connection.outputStream.use { it.write(body) }
			}
			val status = connection.responseCode
			val body = (if (status < 400) connection.inputStream else connection.errorStream)
				?.bufferedReader()
				?.use { it.readText() }
				.orEmpty()
			val headers = connection.headerFields
				.filterKeys { it != null }
				.mapKeys { it.key!! }
				.mapValues { it.value ?: emptyList() }
			return Response(status, connection.responseMessage, headers, body, connection.url.toString())
		} catch (error: IOException) {
			throw error
		} finally {
			connection.disconnect()
		}
	}
}
