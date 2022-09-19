//
//  OrientationClient.swift
//  Anime Now!
//
//  Created by Erik Bautista on 9/18/22.
//

import Foundation
import ComposableArchitecture
import UIKit

struct OrientationClient {
    let setOrientation: (UIInterfaceOrientation) -> Effect<Void, Never>
}
