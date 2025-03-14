//
//  RootViewController.swift
//  AppDowngrade
//
//  Created by dev on 3/5/25.
//

import UIKit
import ESTabBarController_swift
import Localize_Swift

class RootViewController: ESTabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setupViewControllers()
    }
    
    private func setupViewControllers() {
        let item = ESTabBarItem(title: kAD_Home.localized(), image: UIImage(systemName: "house.circle"), selectedImage: UIImage(systemName: "house.circle.fill"))
        
        let vc1 = HomeViewController()
        let homeNC = BaseNC(rootViewController: vc1)
        vc1.tabBarItem = item
        
        let item1 =  ESTabBarItem(title: kAD_Apps.localized(), image: UIImage(systemName: "chevron.down.circle"), selectedImage: UIImage(systemName: "chevron.down.circle.fill"))
        let vc2 = ADDownloadViewController()
        let downloadNC = BaseNC(rootViewController: vc2)
        vc2.tabBarItem = item1
        
        let item2 = ESTabBarItem(title: kAD_Settings.localized(), image: UIImage(systemName: "gearshape.circle"), selectedImage: UIImage(systemName: "gearshape.circle.fill"))
        let vc3 = ADSettingsViewController()
        let settingsNC = BaseNC(rootViewController: vc3)
        vc3.tabBarItem = item2

        self.tabBar.backgroundColor = .white
        
        self.viewControllers = [homeNC, downloadNC, settingsNC]
        
    }
    

}
