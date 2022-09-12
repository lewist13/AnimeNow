//
//  Anime.swift
//  Anime Now! (macOS)
//
//  Created by Erik Bautista on 9/4/22.
//

import Foundation
import NonEmpty

struct Anime: Hashable, Identifiable {
    let id: AnimeListID
    let title: String
    let description: String
    let posterImage: [Image]
    let coverImage: [Image]
    let categories: [String]
    let status: Status
    let format: Format

    enum AnimeListID: Hashable {
        case kitsu(String)
        case myanimelist(String)
        case enime(String)
    }

    enum Format {
        case show
        case movie
    }

    enum Status: String, Hashable {
        case tba
        case finished
        case current
        case upcoming
        case unreleased
    }

    enum Image: Hashable, Comparable {
        case tiny(URL)
        case small(URL)
        case medium(URL)
        case large(URL)
        case original(URL)

        var link: URL {
            switch self {
            case .tiny(let url):
                return url
            case .small(let url):
                return url
            case .medium(let url):
                return url
            case .large(let url):
                return url
            case .original(let url):
                return url
            }
        }

        static func < (lhs: Anime.Image, rhs: Anime.Image) -> Bool {
            if case .tiny = lhs {
                return true
            } else if case .small = lhs {
                if case .tiny = rhs {
                    return false
                } else {
                    return true
                }
            } else if case .medium = lhs {
                if case .tiny = rhs {
                    return false
                } else if case .small = rhs {
                    return false
                } else {
                    return true
                }
            } else if case .large = lhs {
                if case .original = rhs {
                    return true
                } else {
                    return false
                }
            } else {
                return false
            }
        }

        var description: String {
            switch self {
            case .tiny:
                return "tiny"
            case .small:
                return "small"
            case .medium:
                return "medium"
            case .large:
                return "large"
            case .original:
                return "original"
            }
        }
    }
}

extension Array where Element == Anime.Image {
    var largest: Anime.Image? {
        return self.sorted(by: { $0 > $1 }).first
    }
}

extension Anime {
    static let narutoShippuden = Anime(
        id: .kitsu("0"),
        title: "Naruto Shippuden",
        description: "It has been two and a half years since Naruto Uzumaki left Konohagakure, the Hidden Leaf Village, for intense training following events which fueled his desire to be stronger. Now Akatsuki, the mysterious organization of elite rogue ninja, is closing in on their grand plan which may threaten the safety of the entire shinobi world.\n\nAlthough Naruto is older and sinister events loom on the horizon, he has changed little in personality—still rambunctious and childish—though he is now far more confident and possesses an even greater determination to protect his friends and home. Come whatever may, Naruto will carry on with the fight for what is important to him, even at the expense of his own body, in the continuation of the saga about the boy who wishes to become Hokage.\n\n(Source: MAL Rewrite)",
        posterImage: .init(arrayLiteral: .large(URL(string: "https://media.kitsu.io/anime/poster_images/1555/large.jpg")!)),
        coverImage: .init(arrayLiteral: .large(URL(string: "https://media.kitsu.io/anime/cover_images/1555/large.jpg")!)),
        categories: [
            "Ninja",
            "Fantasy World",
            "Action"
        ],
        status: .finished,
        format: .show
    )

    static let attackOnTitan = Anime(
        id: .kitsu("1"),
        title: "Attack on Titan",
        description: "Centuries ago, mankind was slaughtered to near extinction by monstrous humanoid creatures called titans, forcing humans to hide in fear behind enormous concentric walls. What makes these giants truly terrifying is that their taste for human flesh is not born out of hunger but what appears to be out of pleasure. To ensure their survival, the remnants of humanity began living within defensive barriers, resulting in one hundred years without a single titan encounter. However, that fragile calm is soon shattered when a colossal titan manages to breach the supposedly impregnable outer wall, reigniting the fight for survival against the man-eating abominations.\n\nAfter witnessing a horrific personal loss at the hands of the invading creatures, Eren Yeager dedicates his life to their eradication by enlisting into the Survey Corps, an elite military unit that combats the merciless humanoids outside the protection of the walls. Based on Hajime Isayama's award-winning manga, Shingeki no Kyojin follows Eren, along with his adopted sister Mikasa Ackerman and his childhood friend Armin Arlert, as they join the brutal war against the titans and race to discover a way of defeating them before the last walls are breached.\n\n(Source: MAL Rewrite)",
        posterImage: .init(arrayLiteral: .large(URL(string: "https://media.kitsu.io/anime/poster_images/42422/large.jpg")!)),
        coverImage: .init(arrayLiteral: .large(URL(string: "https://media.kitsu.io/anime/cover_images/42422/large.jpg")!)),
        categories: [
            "Post Apocalypse",
            "Violence",
            "Action"
        ],
        status: .current,
        format: .show
    )

    static let empty = Anime(
        id: .kitsu(""),
        title: "",
        description: "",
        posterImage: [],
        coverImage: [],
        categories: [],
        status: .tba,
        format: .show
    )
}
