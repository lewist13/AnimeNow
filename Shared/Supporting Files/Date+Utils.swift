//
//  Date+Utils.swift
//  Anime Now! (iOS)
//
//  Created by Erik Bautista on 9/27/22.
//

import Foundation

extension Date {
    func getYear() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy"
        return dateFormatter.string(from: self)
    }
}
