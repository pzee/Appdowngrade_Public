//
//  ADSettingsItem.swift
//  AppDowngrade
//
//  Created by dev on 3/14/25.
//

import UIKit

// 模型类定义
class ADSettingsSection:NSObject {
    var title: String = ""
    var items: [ADSettingsItem] = []
    override init() {
        super.init()
    }
    convenience init(title: String, items: [ADSettingsItem]) {
        self.init()
        self.title = title
        self.items = items
    }
}

class ADSettingsItem:NSObject  {
    var title: String = ""
    var icon: UIImage? = nil
    var link:String = ""
    
    override init() {
        super.init()
    }
    
    convenience init(title: String, icon: UIImage?, link: String) {
        self.init()
        self.title = title
        self.icon = icon
        self.link = link
    }
}
