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
            name: { "Mock" },
            authenticate: {},
            trendingAnime: {
                .init(
                    value: [
                        .init(
                            id: "0",
                            title: "Naruto Shippuden",
                            description: "ffeesfeffsefesfesfesfesfes sefse fsef se fsefsefsefsef sfse fsefsefes",
                            posterImage: URL(string: "https://media.kitsu.io/anime/poster_images/1555/large.jpg")!,
                            coverImage: URL(string: "https://media.kitsu.io/anime/cover_images/1555/large.jpg")!
                        ),
                        .init(
                            id: "1",
                            title: "Attack on Titan",
                            description: "ffeesfeffsefesfesfesfesfes sefse fsef se fsefsefsefsef sfse fsefsefes",
                            posterImage: URL(string: "https://media.kitsu.io/anime/poster_images/42422/large.jpg")!,
                            coverImage: URL(string: "https://media.kitsu.io/anime/cover_images/42422/large.jpg")!
                        )
                    ]
                )
            }
        )
    }()
}
