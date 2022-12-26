//
//  CMTime+String.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 9/18/22.
//

import Foundation
import CoreMedia

extension CMTime {
    var formattedTime: String {
        let roundedSeconds = seconds.rounded()
        let hours = Int(roundedSeconds / 3600)
        let minutes = Int(roundedSeconds.truncatingRemainder(dividingBy: 3600) / 60)
        let seconds = Int(roundedSeconds.truncatingRemainder(dividingBy: 60))

        return hours > 0 ?
            String(format: "%d:%02d:%02d",
                   hours, minutes, seconds) :
            String(format: "%02d:%02d",
                   minutes, seconds)
    }
}
