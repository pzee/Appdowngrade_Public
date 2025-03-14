//
//  UIColor+Add.swift
//  AppDowngrade
//
//  Created by dev on 3/5/25.
//

import UIKit

extension UIColor {
    /// 通过十六进制字符串创建颜色
    /// - Parameters:
    ///   - hexString: 十六进制颜色字符串，例如 "#FF0000" 或 "FF0000"
    ///   - alpha: 透明度，默认为 1.0
    /// - Returns: 对应的 UIColor 对象
    static func kk_hex(_ hexString: String, alpha: CGFloat = 1.0) -> UIColor {
        var colorString = hexString.trimmingCharacters(in: .whitespacesAndNewlines)
        colorString = colorString.replacingOccurrences(of: "#", with: "")
        
        // 确保字符串长度正确
        guard colorString.count == 6 else {
            return .clear
        }
        
        var rgbValue: UInt64 = 0
        Scanner(string: colorString).scanHexInt64(&rgbValue)
        
        let red = CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgbValue & 0x0000FF) / 255.0
        
        return UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }
    
    /// 便利初始化方法，通过十六进制字符串创建颜色
    /// - Parameters:
    ///   - hexString: 十六进制颜色字符串，例如 "#FF0000" 或 "FF0000"
    ///   - alpha: 透明度，默认为 1.0
    convenience init(hexString: String, alpha: CGFloat = 1.0) {
        self.init(cgColor: UIColor.kk_hex(hexString, alpha: alpha).cgColor)
    }
}
