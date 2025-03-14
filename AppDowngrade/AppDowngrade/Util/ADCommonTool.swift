//
//  ADCommonTool.swift
//  AppDowngrade
//
//  Created by dev on 3/7/25.
//

import UIKit

func kk_print<T>(_ message: T, file: String = #file, method: String = #function, line: Int = #line) {
    #if DEBUG
//    print("\((file as NSString).lastPathComponent)[\(line)] \n\(method): \(message) \n")
    print("\((file as NSString).lastPathComponent)[\(line)]: \(message)")

    #endif
}

class ADCommonTool: NSObject {

}
