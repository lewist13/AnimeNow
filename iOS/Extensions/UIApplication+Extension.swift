////  UIApplication+Extension.swift
//  Anime Now! (iOS)
//
//  Created by ErrorErrorError on 11/3/22.
//  
//

import SwiftUI
import Foundation

extension UIApplication {
    func endEditing(_ force: Bool) {
        self.windows
            .filter{ $0.isKeyWindow }
            .first?
            .endEditing(force)
    }
}
