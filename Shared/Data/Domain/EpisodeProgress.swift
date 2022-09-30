//
//  Progress.swift
//  Anime Now! (iOS)
//
//  Created by Erik Bautista on 9/29/22.
//

import Foundation
import CoreData

struct EpisodeProgress: Codable, Identifiable {
    var id: ProgressInfoId
    var animeTitle: String
    var episodeTitle: String
    var episodeThumbnailUrl: URL?
    var episodeNumber: Int64
    var lastUpdated: Date
    var progress: Double

    var objectURL: URL?
}

//struct ProgressInfoId: Codable, Hashable {
//    let animeId: Anime.ID
//    let episodeId: Episode.ID
//
//    init?(data: Data) {
//        guard let decoded = try? JSONDecoder().decode(Self.self, from: data) else {
//            return nil
//        }
//
//        self.animeId = decoded.animeId
//        self.episodeId = decoded.episodeId
//    }
//
//    init(animeId: Anime.ID, episodeId: Episode.ID) {
//        self.animeId = animeId
//        self.episodeId = episodeId
//    }
//
//    func asData() -> Data? {
//        return try? JSONEncoder().encode(self)
//    }
//}

@objcMembers
class ProgressInfoId: NSObject, NSSecureCoding, Codable {
    static var supportsSecureCoding: Bool {
        true
    }
    
    let animeId: Anime.ID
    let episodeId: Episode.ID

    enum Key: String {
        case animeId = "animeId"
        case episodeId = "episodeId"
    }

    init(animeId: Anime.ID = 0, episodeId: Episode.ID = "") {
        self.animeId = animeId
        self.episodeId = episodeId
        super.init()
    }

    required init?(coder: NSCoder) {
        let animeId = coder.decodeInteger(forKey: Key.animeId.rawValue)
        let episodeId = coder.decodeObject(forKey: Key.episodeId.rawValue) as? String
        guard let episodeId = episodeId else {
            return nil
        }
        self.animeId = animeId
        self.episodeId = episodeId
        super.init()
    }

    func encode(with coder: NSCoder) {
        coder.encode(animeId, forKey: Key.animeId.rawValue)
        coder.encode(episodeId, forKey: Key.episodeId.rawValue)
    }

}

@objc(ProgressInfoIdTransformer)
class ProgressInfoIdTransformer: ValueTransformer {
    override class func transformedValueClass() -> AnyClass {
        ProgressInfoId.self
    }

    override class func allowsReverseTransformation() -> Bool {
        return true
    }

    override class func setValueTransformer(_ transformer: ValueTransformer?, forName name: NSValueTransformerName) {
        super.setValueTransformer(transformer, forName: name)
    }

    override class func valueTransformerNames() -> [NSValueTransformerName] {
        let registered = super.valueTransformerNames()
        return registered
    }
    
    override func transformedValue(_ value: Any?) -> Any? {
        guard let progressInfoId = value as? ProgressInfoId else {
            return nil
        }

        do {
            let keyed = try NSKeyedArchiver.archivedData(withRootObject: progressInfoId, requiringSecureCoding: true)
            return keyed
        } catch {
            print(error)
            return nil
        }
    }

    override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let data = value as? Data else { return nil }
        do {
            let unkeyed = try NSKeyedUnarchiver.unarchivedObject(ofClasses: [ProgressInfoId.self, NSString.self], from: data)
            return unkeyed
        } catch {
            print(error)
            return nil
        }
    }

    static let name = NSValueTransformerName(rawValue: String(describing: ProgressInfoIdTransformer.self))

    static func register() {
        let transformer = ProgressInfoIdTransformer()
        ValueTransformer.setValueTransformer(transformer, forName: name)
    }
}

extension EpisodeProgress: DomainModel {
    func asManagedObject(
        in context: NSManagedObjectContext
    ) -> CDEpisodeProgress {
        let object = CDEpisodeProgress(context: context)
        object.id = id
        object.animeTitle = animeTitle
        object.episodeTitle = episodeTitle
        object.episodeThumbnailUrl = episodeThumbnailUrl
        object.episodeNumber = (episodeNumber) as NSNumber
        object.lastUpdated = lastUpdated
        object.progress = (progress) as NSNumber
        return object
    }
}

extension EpisodeProgress: Hashable {}

extension EpisodeProgress {
    var asEpisode: Episode {
        .init(
            id: id.episodeId,
            name: episodeTitle,
            number: Int(episodeNumber),
            description: "",
            thumbnail: episodeThumbnailUrl != nil ? [.original(episodeThumbnailUrl!)] : [],
            length: nil
        )
    }
}
