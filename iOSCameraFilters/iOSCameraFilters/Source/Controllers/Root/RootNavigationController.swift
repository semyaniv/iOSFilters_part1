//
//  RootNavigationController.swift
//  iOSCameraFilters
//
//  Created by Dmytriy Semyaniv on 27.08.2019.
//  Copyright © 2019 semyaniv. All rights reserved.
//

import UIKit

class RootNavigationController: UINavigationController {
    
    private var statusBarStyle: UIStatusBarStyle = .default
    open override var preferredStatusBarStyle: UIStatusBarStyle {
        return statusBarStyle
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func updateStatusBarStyle(_ style: UIStatusBarStyle) {
        statusBarStyle = style
        UIView.animate(withDuration: 0.2) { [weak self] in
            self?.setNeedsStatusBarAppearanceUpdate()
        }
    }
}

