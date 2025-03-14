//
//  Device+Add.swift
//  AppDowngrade
//
//  Created by dev on 3/5/25.
//

import UIKit

struct ScreenWrapper {
    /// 获取 keyWindow
    private static var keyWindow: UIWindow? {
        // 首先尝试通过 Scene 方式获取 (iOS 13+)
        if let window = UIApplication.shared.connectedScenes
            .filter({ $0.activationState == .foregroundActive })
            .first(where: { $0 is UIWindowScene })
            .flatMap({ $0 as? UIWindowScene })?.windows
            .first(where: { $0.isKeyWindow }) {
            return window
        }
        
        // 备用方案1: 尝试获取所有 Scene 的所有窗口
        if let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow }) {
            return window
        }
        
        // 备用方案2: 传统方式 (iOS 13 之前或备用)
        return UIApplication.shared.windows.first(where: { $0.isKeyWindow }) ?? UIApplication.shared.keyWindow
    }
    
    /// 状态栏高度
    static var statusBarHeight: CGFloat {
        return keyWindow?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0
    }
    
    /// 导航栏高度
    static var navigationBarHeight: CGFloat {
        return 44.0
    }
    
    /// 状态栏+导航栏的高度
    static var navigationFullHeight: CGFloat {
        return statusBarHeight + navigationBarHeight
    }
    
    static var tabbarFullHeight: CGFloat {
        return tabBarHeight + safeAreaBottom
    }
    
    /// 底部标签栏高度
    static var tabBarHeight: CGFloat {
        return 49.0
    }
    
    /// 底部安全区域高度
    static var safeAreaBottom: CGFloat {
        return keyWindow?.safeAreaInsets.bottom ?? 0
    }
    
    /// 顶部安全区域高度
    static var safeAreaTop: CGFloat {
        return keyWindow?.safeAreaInsets.top ?? statusBarHeight
    }
    
    /// 屏幕总高度
    static var screenHeight: CGFloat {
        return UIScreen.main.bounds.height
    }
    
    /// 屏幕总宽度
    static var screenWidth: CGFloat {
        return UIScreen.main.bounds.width
    }
}

extension UIScreen {
    static var kk: ScreenWrapper.Type {
        return ScreenWrapper.self
    }
}
