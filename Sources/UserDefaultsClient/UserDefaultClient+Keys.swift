//
//  UserDefaultClient+Keys.swift
//
//  Created by ErrorErrorError on 12/22/22.
//
//

import Foundation
import SharedModels

extension UserDefaultsClient.Key {
    public static var hasShownOnboarding: UserDefaultsClient.Key<Bool> { .init("hasShownOnboarding") }
    public static var hasClearedAllVideos: UserDefaultsClient.Key<Bool> { .init("hasClearedAllVideos") }

    public static var searchedItems: UserDefaultsClient.Key<[String]> { .init("searchedItems", defaultValue: []) }

    public static var compactEpisodes: UserDefaultsClient.Key<Bool> { .init("compactEpisodes") }
    public static var episodesDescendingOrder: UserDefaultsClient.Key<Bool> { .init("episodesDescendingOrder") }

    public static var videoPlayerAudio: UserDefaultsClient.Key<EpisodeLink.Audio> { .init("videoPlayerAudio", defaultValue: .sub) }
    public static var videoPlayerSubtitle: UserDefaultsClient.Key<String?> { .init("videoPlayerSubtitle", defaultValue: nil) }
    public static var videoPlayerQuality: UserDefaultsClient.Key<Source.Quality?> { .init("videoPlayerQuality", defaultValue: .auto) }
    
}
