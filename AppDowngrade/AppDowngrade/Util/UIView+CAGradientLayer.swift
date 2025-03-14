//
//  Untitled.swift
//  AppDowngrade
//
//  Created by dev on 3/6/25.
//

import UIKit

extension UIView {
    // 渐变层属性
    private var gradientLayer: CAGradientLayer? {
        return layer.sublayers?.compactMap { $0 as? CAGradientLayer }.first
    }
    
    // 添加渐变色图层
    /// 添加渐变色图层
    /// - Parameters:
    ///   - colors: 颜色数组
    ///   - startPoint: 开始点 (0,0)为左上角，(1,1)为右下角
    ///   - endPoint: 结束点 (0,0)为左上角，(1,1)为右下角
    func kk_addGradient(colors: [UIColor], startPoint: CGPoint = CGPoint(x: 0, y: 0.5), endPoint: CGPoint = CGPoint(x: 1, y: 0.5)) {
        // 移除已有的渐变层
        kk_removeGradient()
        
        // 创建新的渐变层
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = bounds
        gradientLayer.colors = colors.map { $0.cgColor }
        gradientLayer.startPoint = startPoint
        gradientLayer.endPoint = endPoint
        
        // 插入到最底层，避免遮挡其他内容
        layer.insertSublayer(gradientLayer, at: 0)
        
        // 确保渐变层随视图大小变化
        self.layer.masksToBounds = true
    }
    
    // 移除渐变层
    func kk_removeGradient() {
        gradientLayer?.removeFromSuperlayer()
    }
    
    // 更新渐变层大小
    func kk_updateGradientFrame(cornerRadius: CGFloat = 0) {
        gradientLayer?.frame = bounds
        if cornerRadius > 0 {
            gradientLayer?.cornerRadius = cornerRadius
        }
        
    }
}

