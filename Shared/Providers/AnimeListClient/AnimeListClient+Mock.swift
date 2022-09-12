//
//  AnimeListClient+Mock.swift
//  Anime Now!
//
//  Created by Erik Bautista on 9/4/22.
//

import Foundation

extension AnimeListClient {
    static let mock: Self = {
        return Self(
            authenticate: { .none },
            topTrendingAnime: {
                .init(
                    value: [
                        .narutoShippuden,
                        .attackOnTitan
                    ]
                )
            },
            topUpcomingAnime: { .none },
            topAiringAnime: { .none },
            highestRatedAnime: { .none },
            mostPopularAnime: { .none },
            episodes: { _ in .none }
        )
    }()
}
