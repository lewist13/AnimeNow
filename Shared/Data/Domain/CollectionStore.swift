////  CollectionStore.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 10/28/22.
//  
//

import Foundation
import OrderedCollections

struct CollectionStore: Hashable, Identifiable {
    var id: Title { self.title }
    var title: Title = .custom("")
    var lastUpdated = Date()
    var animes = OrderedSet<AnimeStore>()
}

extension CollectionStore {
    enum Title: Hashable, Codable, CaseIterable {
        static var allCases: [CollectionStore.Title] {
            [.planning, .watching, .completed]
        }
        
        case planning
        case watching
        case completed
        case custom(String)

        var value: String {
            switch self {
            case .planning:
                return "Plan to Watch"
            case .watching:
                return "Watching"
            case .completed:
                return "Completed"
            case .custom(let name):
                return name
            }
        }

        var canDelete: Bool {
            switch self {
            case .custom:
                return true
            default:
                return false
            }
        }
    }
}
