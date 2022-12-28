//
//  AniSkipAPI.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 10/11/22.
//

import Utilities
import Foundation
import SharedModels

public final class AniSkipAPI: APIBase {
    public static var shared: AniSkipAPI = .init()
    public let base = URL(string: "https://api.aniskip.com/v2")!

    private init() { }
}

extension Request where Route == AniSkipAPI {
    public static func skipTime(
        malId: Int,
        episode: Int,
        types: [AniSkipAPI.SkipItem.SkipType] = .allCases,
        episodeLength: Int = 0
    ) -> Request<Route, AniSkipAPI.Response> {
        .init(
            path: ["skip-times", "\(malId)", "\(episode)"],
            query: types.map { Query(name: "types", value: $0.rawValue) } + [
                Query(name: "episodeLength", value: episodeLength)
            ]
        )
    }
}

extension AniSkipAPI {
    public struct Response: Decodable {
        public let found: Bool
        public let results: [SkipItem]
        public let statusCode: Int
    }

    public struct SkipItem: Decodable {
        let interval: Interval
        let episodeLength: Double
        let skipType: SkipType

        public enum SkipType: String, Decodable, CaseIterable {
            case ed = "ed"
            case op = "op"
            case mixedEd = "mixed-ed"
            case mixedOp = "mixed-op"
            case recap = "recap"
        }

        public struct Interval: Decodable {
            let startTime: Double
            let endTime: Double
        }
    }
}

extension AniSkipAPI {
    public static func convert(from items: [SkipItem]) -> [SharedModels.SkipTime] {
        items.map { item -> SharedModels.SkipTime in
            let option: SharedModels.SkipTime.Option

            switch item.skipType {
            case .ed:
                option = .ending
            case .op:
                option = .opening
            case .mixedEd:
                option = .mixedEnding
            case .mixedOp:
                option = .mixedOpening
            case .recap:
                option = .recap
            }

            return .init(
                startTime: item.interval.startTime / item.episodeLength,
                endTime: item.interval.endTime / item.episodeLength,
                type: option
            )
        }
    }
}
