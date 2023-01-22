import XCTest

@testable import VideoPlayerClient

final class VideoPlayerClientTests: XCTestCase {
    let videoPlayer = VideoPlayerClient.liveValue

    func testHLSVideoPlayer() async throws {
        let loadExpectation = expectation(description: "Video can load.")
        let playExpectation = expectation(description: "Video can play.")

        let stream = videoPlayer.status()

        await videoPlayer.execute(
            .play(
                .init(
                    source: .init(
                        url: .init(
                            string: "https://demo.unified-streaming.com/k8s/features/stable/video/tears-of-steel/tears-of-steel.ism/.m3u8"
                        )!,
                        quality: .auto
                    ),
                    metadata: .init(videoTitle: "", videoAuthor: "")
                )
            )
        )

        let observePlayerStatus = Task {
            for await status in stream {
                print("\(status)")

                if case .loaded = status {
                    loadExpectation.fulfill()
                    await videoPlayer.execute(.resume)
                } else if status == .playback(.playing) {
                    playExpectation.fulfill()
                } else if status == .playback(.paused) {
                } else if status == .finished {
                }
            }
        }

        await waitForExpectations(timeout: 30)

        observePlayerStatus.cancel()
    }

    func testMPDVideoPlayer() async throws {
        let loadExpectation = expectation(description: "Video can load.")
        let playExpectation = expectation(description: "Video can play.")

        let stream = videoPlayer.status()

        await videoPlayer.execute(
            .play(
                .init(
                    source: .init(
                        url: .init(
                            string: "https://dash.akamaized.net/dash264/TestCases/1a/sony/SNE_DASH_SD_CASE1A_REVISED.mpd"
                        )!,
                        quality: .auto,
                        format: .mpd
                    ),
                    metadata: .init(videoTitle: "", videoAuthor: "")
                )
            )
        )

        let observePlayerStatus = Task {
            for await status in stream {
                print("\(status)")

                if case .loaded = status {
                    loadExpectation.fulfill()
                    await videoPlayer.execute(.resume)
                } else if status == .playback(.playing) {
                    playExpectation.fulfill()
                } else if status == .playback(.paused) {
                } else if status == .finished {
                }
            }
        }

        await waitForExpectations(timeout: 3 * 60)

        observePlayerStatus.cancel()
    }
}
