//
//  Sequence+CaseIterable.swift
//  
//
//  Created by ErrorErrorError on 12/27/22.
//  
//

import Foundation

extension Collection where Element: CaseIterable {
    public static var allCases: Element.AllCases { Element.allCases }
}
