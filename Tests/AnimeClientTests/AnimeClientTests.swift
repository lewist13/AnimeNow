import XCTest

@testable import AnimeClient

final class AnimeClientTests: XCTestCase {
    func testFetchingAllEpisodeProviders() async throws {
        let animeClient = AnimeClient.liveValue

        let providers = try await animeClient.getAnimeProviders()

        for provider in providers {
            let episodes = await animeClient.getEpisodes(127230, provider)
            print(episodes.name)
        }
    }
}
