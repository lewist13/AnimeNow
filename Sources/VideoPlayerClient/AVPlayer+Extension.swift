//  AVPlayer+Extension.swift
//  
//
//  Created by ErrorErrorError on 12/24/22.
//  
//

import Foundation
import AVFoundation

// MARK: AVPlayerItem + Extension

public extension AVPlayerItem {
    var bufferProgress: Double {
        guard totalDuration > 0 else { return 0}
        return currentBufferDuration / totalDuration
    }
    
    var currentBufferDuration: Double {
        guard let range = loadedTimeRanges.first else { return 0 }
        return range.timeRangeValue.end.seconds
    }
    
    var currentDuration: Double {
        currentTime().seconds
    }
    
    var playProgress: Double {
        guard totalDuration > 0 else { return 0 }
        return currentDuration / totalDuration
    }

    var totalDuration: Double {
        asset.duration.seconds
    }
}

// MARK: AVPlayer + Extension

public extension AVPlayer {
    var bufferProgress: Double {
        return currentItem?.bufferProgress ?? 0
    }
    
    var currentBufferDuration: Double {
        return currentItem?.currentBufferDuration ?? 0
    }
    
    var currentDuration: Double {
        return currentItem?.currentDuration ?? 0
    }

    var playProgress: Double {
        return currentItem?.playProgress ?? 0
    }
    
    var totalDuration: Double {
        return currentItem?.totalDuration ?? 0
    }
    
    convenience init(asset: AVURLAsset) {
        self.init(playerItem: AVPlayerItem(asset: asset))
    }
}

extension AVPlayerItem.Status: CustomStringConvertible, CustomDebugStringConvertible {
    public var debugDescription: String {
        description
    }

    public var description: String {
        switch self {
        case .unknown:
            return "unknown"
        case .readyToPlay:
            return "readyToPlay"
        case .failed:
            return "failed"
        @unknown default:
            return "default-unknown"
        }
    }
}

extension AVPlayer.Status: CustomStringConvertible, CustomDebugStringConvertible {
    public var debugDescription: String {
        description
    }

    public var description: String {
        switch self {
        case .unknown:
            return "unknown"
        case .readyToPlay:
            return "readyToPlay"
        case .failed:
            return "failed"
        @unknown default:
            return "default-unknown"
        }
    }
}

extension AVPlayer.TimeControlStatus: CustomStringConvertible, CustomDebugStringConvertible {
    public var debugDescription: String {
        description
    }

    public var description: String {
        switch self {
        case .paused:
            return "paused"
        case .waitingToPlayAtSpecifiedRate:
            return "waitingToPlayAtSpecifiedRate"
        case .playing:
            return "playing"
        @unknown default:
            return "default-unknown"
        }
    }
}
