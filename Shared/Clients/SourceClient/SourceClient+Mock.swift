//
//  SourceClient+Mock.swift
//  Anime Now!
//
//  Created by Erik Bautista on 9/13/22.
//

import Foundation
import ComposableArchitecture

extension SourceClient {
    static let mock: Self = {
        Self { _ in
            .none
        } sources: { _ in .none }
    }()
}
