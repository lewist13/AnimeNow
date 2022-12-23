////  UserDefaultClient+Keys.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 12/22/22.
//  
//

import Foundation

extension UserDefaultsClient.Key {
    static var hasShownOnboarding: UserDefaultsClient.Key<Bool> { .init("hasShownOnboarding") }
    static var compactEpisodes: UserDefaultsClient.Key<Bool> { .init("compactEpisodes") }
    static var videoPlayerAudioIsDub: UserDefaultsClient.Key<Bool> { .init("videoPlayerAudioIsDub") }

    static var videoPlayerProvider: UserDefaultsClient.Key<String> { .init("videoPlayerProvider", defaultValue: "") }
    static var videoPlayerSubtitle: UserDefaultsClient.Key<String> { .init("videoPlayerSubtitle", defaultValue: "") }
    static var videoPlayerQuality: UserDefaultsClient.Key<Source.Quality?> { .init("videoPlayerQuality", defaultValue: nil) }
    static var searchedItems: UserDefaultsClient.Key<[String]> { .init("searchedItems", defaultValue: []) }

    static var hasClearedAllVideos: UserDefaultsClient.Key<Bool> { .init("hasClearedAllVideos") }
}
