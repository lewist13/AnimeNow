//
//  Anime.swift
//  Anime Now! (macOS)
//
//  Created by Erik Bautista on 9/4/22.
//

import Foundation

struct Anime: Hashable, Identifiable {
    let id: AnimeListID
    let title: String
    let description: String
    let posterImage: [ImageSize]
    let coverImage: [ImageSize]
    let categories: [String]
    let status: Status
    let format: Format
    let studios: [String]

    enum AnimeListID: Hashable {
        case kitsu(String)
        case anilist(String)
        case myanimelist(String)

        var value: String {
            switch self {
            case .kitsu(let id):
                return id
            case .anilist(let id):
                return id
            case .myanimelist(let id):
                return id
            }
        }
    }

    enum Format {
        case tv
        case movie
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
        format: .tv,
        studios: "TV Tokyo, Aniplex, KSS, Rakuonsha, TV Tokyo Music, Shueisha, TV Tokyo, Aniplex, KSS, Rakuonsha, TV Tokyo Music, Shueisha"
            .split(separator: ",").map({ String($0).trimmingCharacters(in: .whitespacesAndNewlines) })
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
        format: .tv,
        studios: ["Wit Studio", "MAPPA"]
    )

    static let empty = Anime(
        id: .kitsu(""),
        title: "",
        description: "",
        posterImage: [],
        coverImage: [],
        categories: [],
        status: .tba,
        format: .tv,
        studios: []
    )
}
