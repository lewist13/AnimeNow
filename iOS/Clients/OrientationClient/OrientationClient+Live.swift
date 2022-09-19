//
//  OrientationClient+Live.swift
//  Anime Now!
//
//  Created by Erik Bautista on 9/18/22.
//

import Foundation
import UIKit

extension OrientationClient {
    static let live = Self { orientation in
        .fireAndForget {
            UIDevice.current.setValue(orientation.rawValue, forKey: "orientation")
        }
    }
}
