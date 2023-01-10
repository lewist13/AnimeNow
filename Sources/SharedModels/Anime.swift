//
//  Anime.swift
//  Anime Now! (macOS)
//
//  Created by ErrorErrorError on 9/4/22.
//

import Foundation

public protocol AnimeRepresentable: Hashable, Identifiable {
    var id: Int { get }
    var malId: Int? { get }
    var title: String { get }
    var format: Anime.Format { get }
    var posterImage: [ImageSize] { get }

    func isEqualTo(_ item: some AnimeRepresentable) -> Bool
    func eraseAsRepresentable() -> AnyAnimeRepresentable
}

public extension AnimeRepresentable where Self: Equatable {
    func isEqualTo(_ item: some AnimeRepresentable) -> Bool {
        guard let item = item as? Self else { return false }
        return self == item
    }
}

public extension AnimeRepresentable {
    func eraseAsRepresentable() -> AnyAnimeRepresentable {
        .init(self)
    }
}

public struct AnyAnimeRepresentable: AnimeRepresentable {
    private let anime: any AnimeRepresentable

    public var id: Int {
        anime.id
    }

    public var malId: Int? {
        anime.malId
    }

    public var title: String {
        anime.title
    }

    public var format: Anime.Format {
        anime.format
    }

    public var posterImage: [ImageSize] {
        anime.posterImage
    }

    init(_ anime: some AnimeRepresentable) {
        self.anime = anime
    }
}

extension AnyAnimeRepresentable: Hashable {
    public static func == (lhs: AnyAnimeRepresentable, rhs: AnyAnimeRepresentable) -> Bool {
        lhs.anime.isEqualTo(rhs.anime)
    }

    public func hash(into hasher: inout Hasher) {
        self.anime.hash(into: &hasher)
    }
}

public struct Anime: AnimeRepresentable {
    public let id: Int
    public let malId: Int?
    public let title: String
    public let description: String
    public let posterImage: [ImageSize]
    public let coverImage: [ImageSize]
    public let categories: [String]
    public let status: Status
    public let format: Format
    public let releaseYear: Int?
    public let avgRating: Double?  /// 0...1

    public enum Format: String, Codable {
        case tv = "TV"
        case tvShort = "TV Short"
        case special = "Special"
        case ova = "OVA"
        case ona = "ONA"
        case movie = "Movie"
    }

    public enum Status: String, Hashable {
        case tba
        case finished
        case current
        case upcoming
        case unreleased
    }

    public init(
        id: Int,
        malId: Int? = nil,
        title: String,
        description: String,
        posterImage: [ImageSize],
        coverImage: [ImageSize],
        categories: [String],
        status: Anime.Status,
        format: Anime.Format,
        releaseYear: Int? = nil,
        avgRating: Double? = nil
    ) {
        self.id = id
        self.malId = malId
        self.title = title
        self.description = description
        self.posterImage = posterImage
        self.coverImage = coverImage
        self.categories = categories
        self.status = status
        self.format = format
        self.releaseYear = releaseYear
        self.avgRating = avgRating
    }
    
}

public extension Anime {
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
        id: 16498,
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
            description: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.",
            posterImage: [],
            coverImage: [],
            categories: ["One", "Two", "Three"],
            status: .tba,
            format: .tv,
            releaseYear: 2020,
            avgRating: 0.5
        )
    }

    static func placeholders(_ count: Int) -> [Anime] {
        (0..<count).map(createPlaceholder(_:))
    }
}
