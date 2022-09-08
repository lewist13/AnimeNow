//
//  ListClient+Mock.swift
//  Anime Now!
//
//  Created by Erik Bautista on 9/4/22.
//

import Foundation

extension ListClient {
    static let mock: Self = {
        return Self(
            name: { .mock },
            authenticate: { .none },
            trendingAnime: {
                .init(
                    value: [
                        .narutoShippuden,
                        .attackOnTitan
                    ]
                )
            },
            recentlyReleasedAnime: { .none }
        )
    }()
}
