//
//  String+Time.swift
//  Anime Now!
//
//  Created by Erik Bautista on 9/18/22.
//

import Foundation

extension Double {
    var hmsPrettifyString: String {
        let length = self
        let hours = length / 3600
        let minutes = (length.truncatingRemainder(dividingBy: 3600)) / 60
        let seconds = length.truncatingRemainder(dividingBy: 3600).truncatingRemainder(dividingBy: 60)

        var retVal: [String] = []

        if hours > 0 {
            retVal += ["\(hours) h"]
        }

        if minutes > 0 {
            retVal += ["\(minutes) m"]
        }

        if seconds > 0 && minutes == 0 {
            retVal += ["\(seconds) s"]
        }

        return retVal.joined(separator: " ")
    }

    var timeFormatted: String {
        let length = Int(self.rounded())
        let hours = length / 3600
        let minutes = (length % 3600) / 60
        let seconds = (length % 3600) % 60

        var array: [String] = []

        if hours > 0 {
            array.append(.init(format: "%02d", hours))
        }

        array.append(.init(format: "%02d", minutes))
        array.append(.init(format: "%02d", seconds))
        return array.joined(separator: ":")
    }
}
