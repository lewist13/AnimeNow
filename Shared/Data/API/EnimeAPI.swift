//
//  EnimeAPI.swift
//  Anime Now! (iOS)
//
//  Created by Erik Bautista on 9/29/22.
//

import Foundation
import URLRouting

class EnimeAPI: APIRoute {

    // MARK: Enime Route Endpoints

    enum Endpoint: Equatable {
        case mapping(ExternalProvider)
        case fetchEpisodes(animeId: String)
        case episode(String)
        case source(id: String)

        struct ExternalProvider: Equatable, Decodable {
            var provider: Provider
            var id: String
            
            enum Provider: String, CaseIterable, Equatable, Decodable {
                case kitsu
                case mal
                case anilist
            }
        }
        
        struct PageSize: Equatable {
            var page = 1
            var perPage = 10
        }
    }

    let router: AnyParserPrinter<URLRequestData, Endpoint> = {
        OneOf {
            Route(.case(Endpoint.source(id:))) {
                Path { "source"; Parse(.string) }
            }
            Route(.case(Endpoint.episode)) {
                Path { "episode"; Parse(.string) }
            }
            Route(.case(Endpoint.mapping)) {
                Path { "mapping" }
                Parse(.memberwise(Endpoint.ExternalProvider.init)) {
                    Path { Endpoint.ExternalProvider.Provider.parser(); Parse(.string) }
                }
            }
            Route(.case(Endpoint.fetchEpisodes(animeId:))) {
                Path { "anime"; Parse(.string); "episodes" }
            }
        }
        .eraseToAnyParserPrinter()
    }()
    
    let baseURL = URL(string: "https://api.enime.moe")!
    
    func applyHeaders(request: inout URLRequest) {}
}

fileprivate extension EnimeAPI {

    // MARK: - DataResponse
    struct DataResponse<T: Decodable>: Decodable {
        let data: [T]
        let meta: Meta
    }

    // MARK: - Meta
    struct Meta: Decodable {
        let total: Int
        let lastPage: Int
        let currentPage: Int
        let perPage: Int
        let next: Int
    }

    // MARK: - Episode
    struct Episode: Decodable {
        let id: String
        let number: Int
        let title: String?
        let titleVariations: Title?
        let description: String?
        let image: String?
        let airedAt: String?
        let sources: [Source]
    }

    // MARK: - Source
    struct Source: Decodable {
        let id: String
        let url: String
        let target: String
        let priority: Int
        let website: String?
        let subtitle: Bool?
        let browser: Bool?
    }

    struct Anime: Decodable {
        let id: String
        let anilistId: Int
    }

    // MARK: - Title
    struct Title: Decodable {
        let native: String?
        let romaji: String?
        let english: String?
    }
}
