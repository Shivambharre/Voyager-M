package com.voyager.voyager_learning

import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
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

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)
		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
			.setMethodCallHandler { call, result ->
				if (call.method != "resolveVideo" && call.method != "resolvePlaylist") {
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
							else -> resolvePlaylist(sourceUrl)
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
		super.onDestroy()
	}

	companion object {
		private const val CHANNEL = "com.voyager/newpipe"
		private const val MAX_PLAYLIST_ENTRIES = 500
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
