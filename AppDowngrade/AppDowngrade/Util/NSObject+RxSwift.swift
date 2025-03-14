//
//  Login.swift
//  AppDowngrade
//
//  Created by dev on 3/5/25.
//

import UIKit
import RxSwift

fileprivate let disposeBagAssociatedKey = UnsafeRawPointer(bitPattern: "_rx_dispose_bag".hash)!

extension Reactive where Base: NSObject {
    
    /// NSObject默认创建的`dispose bag`
    var disposeBag: DisposeBag {
        if let disposeBag = objc_getAssociatedObject(base, disposeBagAssociatedKey) as? DisposeBag {
            return disposeBag
        } else {
            let disposeBag = DisposeBag()
            objc_setAssociatedObject(base,
                                     disposeBagAssociatedKey,
                                     disposeBag,
                                    .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return disposeBag
        }
    }
}

