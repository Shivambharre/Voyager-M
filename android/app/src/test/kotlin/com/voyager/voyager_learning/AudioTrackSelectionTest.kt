package com.voyager.voyager_learning

import org.junit.Assert.assertEquals
import org.junit.Test
import org.schabi.newpipe.extractor.stream.AudioTrackType

class AudioTrackSelectionTest {
	@Test
	fun `original audio wins over higher bitrate dubbed audio`() {
		val selected = selectOriginalAudioTrackIndex(
			listOf(
				AudioTrackPreference(AudioTrackType.ORIGINAL, 128_000),
				AudioTrackPreference(AudioTrackType.DUBBED, 320_000),
			),
		)

		assertEquals(0, selected)
	}

	@Test
	fun `highest bitrate original track is selected`() {
		val selected = selectOriginalAudioTrackIndex(
			listOf(
				AudioTrackPreference(AudioTrackType.ORIGINAL, 128_000),
				AudioTrackPreference(AudioTrackType.ORIGINAL, 256_000),
			),
		)

		assertEquals(1, selected)
	}

	@Test
	fun `unclassified original track outranks dubbed tracks`() {
		val selected = selectOriginalAudioTrackIndex(
			listOf(
				AudioTrackPreference(null, 128_000),
				AudioTrackPreference(AudioTrackType.DUBBED, 320_000),
			),
		)

		assertEquals(0, selected)
	}
}
