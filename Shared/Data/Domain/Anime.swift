//
//  Anime.swift
//  Anime Now! (macOS)
//
//  Created by ErrorErrorError on 9/4/22.
//

import Foundation

protocol AnimeRepresentable {
    var id: Int { get }
    var malId: Int? { get }
    var title: String { get }
    var format: Anime.Format { get }
    var posterImage: [ImageSize] { get }

    func isEqualTo(_ item: AnimeRepresentable) -> Bool
    func asRepresentable() -> AnyAnimeRepresentable
}

extension AnimeRepresentable where Self: Equatable {
    func isEqualTo(_ item: AnimeRepresentable) -> Bool {
        guard let item = item as? Self else { return false }
        return self == item
    }
}

extension AnimeRepresentable {
    func asRepresentable() -> AnyAnimeRepresentable {
        .init(self)
    }
}

struct AnyAnimeRepresentable: AnimeRepresentable, Identifiable {
    private let anime: AnimeRepresentable

    var id: Int {
        anime.id
    }

    var malId: Int? {
        anime.malId
    }

    var title: String {
        anime.title
    }

    var format: Anime.Format {
        anime.format
    }

    var posterImage: [ImageSize] {
        anime.posterImage
    }

    init(_ anime: AnimeRepresentable) {
        self.anime = anime
    }
}

extension AnyAnimeRepresentable: Equatable {
    static func == (lhs: AnyAnimeRepresentable, rhs: AnyAnimeRepresentable) -> Bool {
        lhs.anime.isEqualTo(rhs.anime)
    }
}

struct Anime: AnimeRepresentable, Equatable, Identifiable {
    let id: Int
    let malId: Int?
    let title: String
    let description: String
    let posterImage: [ImageSize]
    let coverImage: [ImageSize]
    let categories: [String]
    let status: Status
    let format: Format
    let releaseYear: Int?
    let avgRating: Double?  /// 0...1

    enum Format: String, Codable {
        case tv = "TV"
        case tvShort = "TV Short"
        case special = "Special"
        case ova = "OVA"
        case ona = "ONA"
        case movie = "Movie"
    }

    enum Status: String, Hashable {
        case tba
        case finished
        case current
        case upcoming
        case unreleased
    }
}

extension Anime {
    static let narutoShippuden = Anime(
        id: 0,
        malId: 0,
        title: "Naruto Shippuden",
        description: "It has been two and a half years since Naruto Uzumaki left Konohagakure, the Hidden Leaf Village, for intense training following events which fueled his desire to be stronger. Now Akatsuki, the mysterious organization of elite rogue ninja, is closing in on their grand plan which may threaten the safety of the entire shinobi world.\n\nAlthough Naruto is older and sinister events loom on the horizon, he has changed little in personality—still rambunctious and childish—though he is now far more confident and possesses an even greater determination to protect his friends and home. Come whatever may, Naruto will carry on with the fight for what is important to him, even at the expense of his own body, in the continuation of the saga about the boy who wishes to become Hokage.\n\n(Source: MAL Rewrite)",
        posterImage: [.large(URL(string: "https://media.kitsu.io/anime/poster_images/1555/large.jpg")!)],
        coverImage: [.large(URL(string: "https://media.kitsu.io/anime/cover_images/1555/large.jpg")!)],
        categories: [
            "Ninja",
            "Fantasy World",
            "Action"
        ],
        status: .finished,
        format: .tv,
        releaseYear: 2009,
        avgRating: nil
    )

    static let attackOnTitan = Anime(
        id: 1,
        malId: 0,
        title: "Attack on Titan",
        description: "Centuries ago, mankind was slaughtered to near extinction by monstrous humanoid creatures called titans.",
        posterImage: [.large(URL(string: "https://media.kitsu.io/anime/poster_images/42422/large.jpg")!)],
        coverImage: [.large(URL(string: "https://media.kitsu.io/anime/cover_images/42422/large.jpg")!)],
        categories: [
            "Post Apocalypse",
            "Violence",
            "Action"
        ],
        status: .current,
        format: .tv,
        releaseYear: 2013,
        avgRating: nil
    )

    static let empty = Anime(
        id: 0,
        malId: 0,
        title: "",
        description: "",
        posterImage: [],
        coverImage: [],
        categories: [],
        status: .tba,
        format: .tv,
        releaseYear: nil,
        avgRating: nil
    )

    static let placeholder = createPlaceholder(0)

    private static func createPlaceholder(_ id: Int) -> Anime {
        Anime(
            id: id,
            malId: 0,
            title: "Placeholder",
            description: "Placeholder",
            posterImage: [],
            coverImage: [],
            categories: [],
            status: .tba,
            format: .tv,
            releaseYear: nil,
            avgRating: nil
        )
    }

    static func placeholders(_ count: Int) -> [Anime] {
        (0..<count).map(createPlaceholder(_:))
    }
}
