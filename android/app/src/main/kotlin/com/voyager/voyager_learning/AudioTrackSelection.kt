package com.voyager.voyager_learning

import org.schabi.newpipe.extractor.stream.AudioTrackType

internal data class AudioTrackPreference(
	val type: AudioTrackType?,
	val bitrate: Int,
)

internal fun selectOriginalAudioTrackIndex(
	tracks: List<AudioTrackPreference>,
): Int? {
	fun priority(type: AudioTrackType?): Int = when (type) {
		AudioTrackType.ORIGINAL -> 4
		null -> 3
		AudioTrackType.SECONDARY -> 2
		AudioTrackType.DESCRIPTIVE -> 1
		AudioTrackType.DUBBED -> 0
	}

	return tracks.indices.maxWithOrNull(
		compareBy<Int>({ priority(tracks[it].type) }, { tracks[it].bitrate }),
	)
}
