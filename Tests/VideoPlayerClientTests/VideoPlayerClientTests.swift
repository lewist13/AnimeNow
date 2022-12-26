import SharedDependencies
import XCTest

@testable import VideoPlayerClient

final class VideoPlayerClientTests: XCTestCase {
    func testVideoPlayer() async throws {
        let videoPlayer = VideoPlayerClient.liveValue

        let stream = videoPlayer.status()

        let playsExpectation = self.expectation(description: "Video Player Plays")
        let pauseExpectation = self.expectation(description: "Video Player Pauses")

        for await status in stream {
            print("\(status)")

            if status == .loaded {
                await videoPlayer.execute(.resume)
            } else if status == .playing {
                playsExpectation.fulfill()
            } else if status == .paused {
                pauseExpectation.fulfill()
            }
        }

        await videoPlayer.execute(
            .play(
                URL(string: "http://sample.vodobox.net/skate_phantom_flex_4k/skate_phantom_flex_4k.m3u8")!
            )
        )

        await self.waitForExpectations(timeout: 20)
    }
}
