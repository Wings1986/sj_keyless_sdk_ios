//
//  SJResult.swift
//  sj_keyless_sdk_ios
//
//  Created by Ivan Astafiev on 07.06.2023.
//

import Foundation

public struct SJResult {
    var isSuccess: Bool
    var data: Any?
    let code: Int
    var error: String?
    
    init(isSuccess: Bool, data: Any? = nil, code: Int = 0, error: String? = nil) {
        self.isSuccess = isSuccess
        self.data = data
        self.code = code
        self.error = error
    }
    
    init(error: SJError, data: Any? = nil) {
        self.init(isSuccess: false, data: data, code: error.code, error: error.message)
    }
}
