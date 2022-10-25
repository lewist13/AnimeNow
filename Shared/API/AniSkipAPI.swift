//
//  AniSkipAPI.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 10/11/22.
//

import Foundation
import URLRouting

class AniSkipAPI: APIRoutable {

    // MARK: Enime Route Endpoints

    enum Endpoint {
        case skipTime(
            (Int, Int),
            [String] = ["ed", "op", "recap", "mixed-ed", "mixed-op"],
            String = ""
        )

        struct Info: Decodable {
            let malId: Int
            let number: Int
        }
    }

    let router: AnyParserPrinter<URLRequestData, Endpoint> = {
        OneOf {
            Route(.case(Endpoint.skipTime)) {
                Path {
                    "skip-times"
                    Int.parser()
                    Int.parser()
                }

                AnyParserPrinter<URLRequestData, [String]>.init { request in
                    request.query.fields["types"]?.compactMap { $0 == nil ? nil : String($0!) } ?? []
                } print: { types, request in
                    let substrings = types.map({ string -> Substring? in Substring(string) })
                    request.query["types"] = ArraySlice(substrings)
                }

                AnyParserPrinter<URLRequestData, String>.init { request in
                    request.query.fields["episodeLength"]?.compactMap({ $0 == nil ? nil : String($0!) }).first ?? ""
                } print: { value, request in
                    let substrings = Substring(value)
                    request.query["episodeLength"] = ArraySlice([substrings])
                }
            }
        }
        .eraseToAnyParserPrinter()
    }()

    let baseURL = URL(string: "https://api.aniskip.com/v2")!

    func configureRequest(request: inout URLRequest) {}
}

extension AniSkipAPI {
    struct Response: Decodable {
        let found: Bool
        let results: [SkipItem]
        let statusCode: Int
    }

    struct SkipItem: Decodable {
        let interval: Interval
        let episodeLength: Double
        let skipType: SkipType

        enum SkipType: String, Decodable {
            case ed = "ed"
            case op = "op"
            case mixedEd = "mixed-ed"
            case mixedOp = "mixed-op"
            case recap = "recap"
        }
    }

    struct Interval: Decodable {
        let startTime: Double
        let endTime: Double
    }
}

extension AniSkipAPI {
    static func convert(from items: [SkipItem]) -> [SkipTime] {
        items.map { item -> SkipTime in
            let option: SkipTime.Option

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

            return SkipTime(
                startTime: item.interval.startTime / item.episodeLength,
                endTime: item.interval.endTime / item.episodeLength,
                type: option
            )
        }
    }
}
