//
//  HomeViewControllerTest.swift
//  Odd_Jobs_Realm
//
//  Created by Alan Doonan on 13/08/2019.
//  Copyright © 2019 Alan Doonan. All rights reserved.
//

import UIKit
import RealmSwift

class HomeControllerTest: UIViewController {
    
    var realm: Realm
    var notificationToken: NotificationToken?
    var delegate: HomeControllerDelegate?
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        let config = SyncUser.current?.configuration(realmURL: Constants.ODDJOBS_REALM_URL, fullSynchronization: true)
        self.realm = try! Realm(configuration: config!)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        notificationToken?.invalidate()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print(SyncUser.current?.identity!)
        view.backgroundColor = Themes.current.background
        configureNavigationBar()
    }
        
    @objc func handleMenuToggle() {
        delegate?.handleMenuToggle(forMenuOption: nil)
    }
    
    fileprivate func createHomeBackGround() {
        UIGraphicsBeginImageContext(self.view.frame.size)
        UIImage(named: "Launchscreen_NO_CR.png")?.draw(in: self.view.bounds)
        let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        self.view.backgroundColor = UIColor(patternImage: image)
    }
    
    func configureNavigationBar() {
        navigationController?.navigationBar.barTintColor = Themes.current.background
        navigationController?.navigationBar.barStyle = .black
        navigationController?.view.backgroundColor = Themes.current.background
        navigationItem.title = "Odd Jobs"
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "ic_menu_white_3x").withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(handleMenuToggle))
        createHomeBackGround()
    }
}