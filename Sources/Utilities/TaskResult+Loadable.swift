//
//  File.swift
//  
//
//  Created by ErrorErrorError on 1/18/23.
//  
//

import Foundation
import ComposableArchitecture

extension TaskResult {
    public var loadable: Loadable<Success> {
        switch self {
        case .success(let success):
            return .success(success)
        case .failure(let error):
            return .failed(error)
        }
    }
}
