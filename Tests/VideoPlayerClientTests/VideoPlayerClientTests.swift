import XCTest

@testable import VideoPlayerClient

final class VideoPlayerClientTests: XCTestCase {
    func testVideoPlayer() async throws {
        let videoPlayer = VideoPlayerClient.liveValue

        let stream = videoPlayer.status()

        await videoPlayer.execute(
            .play(
                URL(string: "http://sample.vodobox.net/skate_phantom_flex_4k/skate_phantom_flex_4k.m3u8")!,
                    .init(
                    videoTitle: "Test Title",
                    videoAuthor: "Test Author"
                )
            )
        )

        for await status in stream {
            print("\(status)")

            if case .loaded = status {
                await videoPlayer.execute(.resume)
            } else if status == .playback(.playing) {
            } else if status == .playback(.paused) {
            } else if status == .finished {
                await videoPlayer.execute(.seekTo(0))
            }
        }
    }
}
