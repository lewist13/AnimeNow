//
//  DASHResourceLoader.swift
//  
//
//  Created by ErrorErrorError on 1/9/23.
//  
//

import Foundation

struct MPD {
    var period: Period
    var mediaPresentationDuration: TimeInterval

    init?(attributeDict: [String: String]) {
        guard let duration = attributeDict["mediaPresentationDuration"],
              let mediaPresentationDuration = duration.toMPDDuration else { return nil }
        self.period = Period()
        self.mediaPresentationDuration = mediaPresentationDuration
    }

    func hlsAttributes(audio: Bool) -> [String] {
        period.adaptationset
            .flatMap {
                $0.representation
                    .filter({ $0.mimeType.contains(audio ? "audio" : "video") })
                    .filter { Int($0.bandwidth) ?? .zero < 14_000_000 }
                    .map { $0.hlsAttribute }
            }
    }
}

extension MPD {
    struct Period {
        var adaptationset: [AdaptationSet] = []
    }
}

extension MPD.Period {
    struct AdaptationSet {
        let id: String
        let group: String
        let subsegmentAlignment: String
        let subsegmentStartsWithSAP: String
        var representation: [Representation]

        init?(attributeDict: [String: String]) {
            guard let id = attributeDict["id"],
                  let group = attributeDict["group"],
                  let subsegmentAlignment = attributeDict["subsegmentAlignment"],
                  let subsegmentStartsWithSAP = attributeDict["subsegmentStartsWithSAP"] else { return nil }

            self.id = id
            self.group = group
            self.subsegmentAlignment = subsegmentAlignment
            self.subsegmentStartsWithSAP = subsegmentStartsWithSAP
            self.representation = []
        }
    }
}

extension MPD.Period.AdaptationSet {
    struct Representation {
        var BaseURL: String = ""
        let id: String
        let mimeType: String
        let codecs: String
        let bandwidth: String
        let width: String?
        let height: String?
        let frameRate: String?
        let sar: String?
        var segmentBase: SegmentBase?

        init?(attributeDict: [String: String]) {
            guard let id = attributeDict["id"],
                  let mimetype = attributeDict["mimeType"],
                  let codecs = attributeDict["codecs"],
                  let bandwidth = attributeDict["bandwidth"] else { return nil }

            self.id = id
            self.codecs = codecs
            self.mimeType = mimetype
            self.bandwidth = bandwidth
            self.width = attributeDict["width"]
            self.height = attributeDict["height"]
            self.frameRate = attributeDict["frameRate"]
            self.sar = attributeDict["sar"]
        }

        var hlsAttribute: String {
            if mimeType.contains("audio") {
                return [
                    "#EXT-X-MEDIA:TYPE=AUDIO",
                    "GROUP-ID=\"audio\"",
                    "NAME=\"merge\"",
                    "DEFAULT=YES",
                    "AUTOSELECT=YES",
                    "URI=\"\(id).m3u8\""
                ]
                    .joined(separator: ",")
            } else {
                return [
                    "#EXT-X-STREAM-INF:PROGRAM-ID=1",
                    "BANDWIDTH=\(bandwidth)",
                    self.width != nil && self.height != nil ? "RESOLUTION=\(width!)x\(height!)" : "",
                    "CODECS=\"\(codecs)\"",
                    "AUDIO=\"audio\""
                ]
                    .filter({ !$0.isEmpty })
                    .joined(separator: ",")
                    .appending("\n\(id).m3u8")
            }
        }
    }
}

extension MPD.Period.AdaptationSet.Representation {
    struct SegmentBase {
        let indexRangeExact: String
        let indexRange: String
        var initialization: Initialization?

        init?(attributeDict: [String: String]) {
            guard let indexRangeExact = attributeDict["indexRangeExact"],
                  let indexRange = attributeDict["indexRange"] else { return nil }
            self.indexRangeExact = indexRangeExact
            self.indexRange = indexRange
        }

        struct Initialization {
            let range: String

            init?(attributeDict: [String: String]) {
                guard let range = attributeDict["range"] else { return nil }
                self.range = range
            }
        }
    }
}

private extension String {
    var toMPDDuration: TimeInterval? {
        guard var timeValue = self.components(separatedBy: "PT").last,
              !timeValue.isEmpty else { return nil }

        var duration: TimeInterval = .zero
        if timeValue.contains("H"),
           let value = timeValue.components(separatedBy: "H").first,
           let integer = Int(value) {
            duration += TimeInterval(integer * 3600)
            timeValue = timeValue.components(separatedBy: "H").last ?? ""
        }

        if timeValue.contains("M"),
           let value = timeValue.components(separatedBy: "M").first,
           let integer = Int(value) {
            duration += TimeInterval(integer * 60)
            timeValue = timeValue.components(separatedBy: "M").last ?? ""
        }

        if timeValue.contains("S"),
           let value = timeValue.components(separatedBy: "S").first,
           let time = TimeInterval(value) {
            duration += time
        }

        return duration
    }
}

final class DASHResourceLoader: NSObject, Loader {
    enum Error: Swift.Error {
        case responseError
        case emptyData
        case failedToCreateM3U8
    }

    var mpd: MPD?

    var handleMPDCompletion: ((Result<Data, Swift.Error>) -> Void)?

    func loadResource(
        url: URL,
        completion: @escaping (Result<Data, Swift.Error>) -> Void
    ) {
        if url.absoluteString.contains("m3u8") {
            makeMediaM3U8(url: url, completion: completion)
        } else if url.absoluteString.contains(Self.customPlaylistScheme) {
            URLSession.shared.dataTask(with: url.recoveryScheme) { [weak self] (data, response, error) in
                if let error {
                    completion(.failure(error))
                    return
                }

                guard (response as? HTTPURLResponse)?.statusCode != nil,
                      let data = data else {
                    completion(.failure(Error.emptyData))
                    return
                }

                self?.parseXML(data: data, completion: completion)
            }
            .resume()
        }
    }

    func parseXML(
        data: Data,
        completion: @escaping(Result<Data, Swift.Error>) -> Void
    ) {
        self.handleMPDCompletion = completion
        let xml = XMLParser(data: data)
        xml.delegate = self
        xml.parse()
    }

    func makeMasterM3U8() {
        guard let mpd = self.mpd else {
            handleMPDCompletion?(.failure(Error.failedToCreateM3U8))
            return
        }

        var lines: [String] = ["#EXTM3U"]
        lines.append(contentsOf: mpd.hlsAttributes(audio: true))
        lines.append(contentsOf: mpd.hlsAttributes(audio: false))

        if let data = lines
            .joined(separator: "\n")
            .data(using: .utf8) {
            print("\n" + String(decoding: data, as: UTF8.self) + "\n")
            handleMPDCompletion?(.success(data))
        } else {
            handleMPDCompletion?(.failure(Error.failedToCreateM3U8))
        }
    }

    func makeMediaM3U8(
        url: URL,
        completion: @escaping(Result<Data, Swift.Error>) -> Void
    ) {
        guard let mpd = self.mpd,
              let id = url.lastPathComponent.components(separatedBy: ".").first,
              let representation = mpd.period.adaptationset
                    .flatMap(\.representation)
                    .first(where: { $0.id == id }) else { return }

        var lines: [String] = ["#EXTM3U"]
        let mediaDuration = mpd.mediaPresentationDuration

        lines.append(contentsOf: [
            "#EXT-X-TARGETDURATION:\(mediaDuration)",
            "#EXT-X-VERSION:6",
            "#EXT-X-MEDIA-SEQUENCE:0",
            "#EXT-X-PLAYLIST-TYPE:VOD"
        ])

        lines.append("#EXTINF:\(String(format: "%.3f", mediaDuration)),\(representation.mimeType.contains("video") ? "video" : "audio"),")
        lines.append(representation.BaseURL)
        lines.append("#EXT-X-ENDLIST")

        if let data = lines.joined(separator: "\n").data(using: .utf8) {
            print("\n" + String(decoding: data, as: UTF8.self) + "\n")
            completion(.success(data))
        } else {
            completion(.failure(Error.failedToCreateM3U8))
        }
    }
}

extension DASHResourceLoader: XMLParserDelegate {
    private static var textBuffer = ""

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String : String] = [:]
    ) {
        Self.textBuffer = ""
        switch elementName.lowercased() {
        case "mpd":
            if let mpd = MPD(attributeDict: attributeDict) {
                self.mpd = mpd
            }
        case "adaptationset":
            if let adaptationset = MPD.Period.AdaptationSet(attributeDict: attributeDict) {
                mpd?.period.adaptationset.append(adaptationset)
            }
        case "representation":
            if let representation = MPD.Period.AdaptationSet.Representation(
                attributeDict: attributeDict
            ) {
                if let lastAdaptationIndex = mpd?.period.adaptationset.count, lastAdaptationIndex > 0 {
                    mpd?.period.adaptationset[lastAdaptationIndex - 1].representation.append(representation)
                }
            }

        case "segmentbase":
            if let segmentbase = MPD.Period.AdaptationSet.Representation.SegmentBase(
                attributeDict: attributeDict
            ) {
                if let lastAdaptionIndex = mpd?.period.adaptationset.count, lastAdaptionIndex > 0,
                   let lastRepresentationIndex = mpd?.period.adaptationset[lastAdaptionIndex - 1].representation.count, lastRepresentationIndex > 0 {
                    mpd?.period.adaptationset[lastAdaptionIndex - 1].representation[lastRepresentationIndex - 1].segmentBase = segmentbase
                }
            }

        case "initialization":
            if let initialization = MPD.Period.AdaptationSet.Representation.SegmentBase.Initialization(
                attributeDict: attributeDict
            ) {
                if let lastAdaptionIndex = mpd?.period.adaptationset.count, lastAdaptionIndex > 0,
                   let lastRepresentationIndex = mpd?.period.adaptationset[lastAdaptionIndex - 1].representation.count, lastRepresentationIndex > 0 {
                    mpd?.period.adaptationset[lastAdaptionIndex - 1].representation[lastRepresentationIndex - 1].segmentBase?.initialization = initialization
                }
            }

        default: break
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        Self.textBuffer += string
    }

    func parser(_ parser: XMLParser, foundCDATA CDATABlock: Data) {
        guard let string = String(data: CDATABlock, encoding: .utf8) else {
            return
        }
        Self.textBuffer += string
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName.lowercased() == "BaseURL".lowercased() {
            if let lastAdaptionIndex = mpd?.period.adaptationset.count, lastAdaptionIndex > 0,
               let lastRepresentationIndex = mpd?.period.adaptationset[lastAdaptionIndex - 1].representation.count, lastRepresentationIndex > 0 {
                mpd?.period.adaptationset[lastAdaptionIndex - 1].representation[lastRepresentationIndex - 1].BaseURL = Self.textBuffer
            }
        }
    }

    func parserDidEndDocument(_ parser: XMLParser) {
        makeMasterM3U8()
    }
}

extension DASHResourceLoader {
    static var customPlaylistScheme: String { "animenow-mpd" }
    static let dashExt = "mpd"
    static let hlsExt = "m3u8"
}
