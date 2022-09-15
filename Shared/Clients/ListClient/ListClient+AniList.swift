//
//  ListClient+AniList.swift
//  Anime Now!
//
//  Created by Erik Bautista on 9/14/22.
//

import Foundation
import ComposableArchitecture

extension ListClient {
    static let anilist: Self = {
        return Self(
            topTrendingAnime: {
                .none
            }, topUpcomingAnime: {
                .none
            }, topAiringAnime: {
                .none
            }, highestRatedAnime: {
                .none
            }, mostPopularAnime: {
                .none
            }, search: { _ in
                .none
            })
    }()
}
