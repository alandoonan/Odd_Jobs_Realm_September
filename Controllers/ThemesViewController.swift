//
//  ItemsViewController.swift
//  Odd_Jobs_Realm
//
//  Created by Alan Doonan on 07/07/2019.
//  Copyright © 2019 Alan Doonan. All rights reserved.
//

import UIKit
import RealmSwift
class ThemesViewController: UIViewController, UITableViewDelegate, UITableViewDataSource
{
    let realm: Realm
    let themes: Results<ThemeItem>
    let scoreItem: Results<ScoreItem>
    let tableView = UITableView()
    let personalVC = PersonalViewController()
    var notificationToken: NotificationToken?
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        let config = SyncUser.current?.configuration(realmURL: Constants.ODDJOBS_REALM_URL, fullSynchronization: true)
        self.realm = try! Realm(configuration: config!)
        self.themes = realm.objects(ThemeItem.self).filter("Category contains[c] %@", "Theme")
        self.scoreItem = realm.objects(ScoreItem.self).filter("Category contains[c] %@", "Personal")
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        notificationToken?.invalidate()
    }
    
    fileprivate func applyTheme() {
        view.backgroundColor = Themes.current.background
        tableView.backgroundColor = Themes.current.background
        navigationController?.navigationBar.backgroundColor = Themes.current.background
        let textAttributes = [NSAttributedString.Key.foregroundColor:Themes.current.accent]
        navigationController?.navigationBar.titleTextAttributes = textAttributes
    }
    
    fileprivate func addTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.frame = self.view.frame
        tableView.separatorStyle = UITableViewCell.SeparatorStyle.none
        tableView.allowsSelection = false
        view.addSubview(tableView)
    }
    
    fileprivate func addNotificationToken() {
        notificationToken = themes.observe { [weak self] (changes) in
            guard let tableView = self?.tableView else { return }
            switch changes {
            case .initial:
                tableView.reloadData()
            case .update(_, let deletions, let insertions, let modifications):
                tableView.beginUpdates()
                tableView.insertRows(at: insertions.map({ IndexPath(row: $0, section: 0) }),
                                     with: .automatic)
                tableView.deleteRows(at: deletions.map({ IndexPath(row: $0, section: 0)}),
                                     with: .automatic)
                tableView.reloadRows(at: modifications.map({ IndexPath(row: $0, section: 0) }),
                                     with: .automatic)
                tableView.endUpdates()
            case .error(let error):
                fatalError("\(error)")
            }
        }
    }
    
    fileprivate func addNavBar(_ sideBar: UIBarButtonItem,_ logout: UIBarButtonItem, title: String) {
        navigationItem.leftBarButtonItems = [sideBar] //, add ,search
        navigationItem.rightBarButtonItems = [logout] //,sort
        navigationItem.title = title
    }
    
    @objc func rightBarButtonDidClick() {
        let alertController = UIAlertController(title: "Logout", message: "", preferredStyle: .alert);
        alertController.addAction(UIAlertAction(title: "Yes, Logout", style: .destructive, handler: {
            alert -> Void in
            SyncUser.current?.logOut()
            self.view.window?.rootViewController?.dismiss(animated: true, completion: nil)
        }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Themes"
        let logout = UIBarButtonItem(title: "Logout", style: .plain, target: self, action: #selector(rightBarButtonDidClick))
        let sideBar = UIBarButtonItem(image: #imageLiteral(resourceName: "ic_menu_white_3x").withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(handleDismiss))
        addNavBar(sideBar, logout, title: "Themes")
        applyTheme()
        addThemes()
        addTableView()
        addNotificationToken()
    }
    
    @objc func switchStateDidChange(_ sender:UISwitch){
        if (sender.isOn == true){
            for colour1 in Constants.themeColours {
                if Int(colour1.value[2]) == sender.tag {
                    print(colour1.value[3])
                    for colour2 in Constants.themeLevels {
                        if colour2.key == colour1.key {
                            print("Changing colour")
                            //Change colours here
                            //Themes.current = colour2.value as! ThemeProtocol
                        }
                    }
                }
            }
        }
        else{
            print("UISwitch state is now Off")
            Themes.current = BlueTheme()
        }
        applyTheme()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return themes.count
    }
    
    fileprivate func addTableCell(_ tableView: UITableView, _ indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") ?? UITableViewCell(style: .subtitle, reuseIdentifier: "Cell")
        let switchView = UISwitch(frame: .zero)
        let item = themes[indexPath.row]
        cell.textLabel?.text = item.name
        cell.textLabel?.textColor = .white
        cell.backgroundColor = UIColor().hexColor(item.hexColour)
        cell.textLabel!.font = UIFont(name: Themes.mainFontName,size: 18)
        switchView.setOn(false, animated: true)
        switchView.tag = indexPath.row
        cell.accessoryView = switchView
        switchView.tintColor = Themes.current.background
        switchView.tag = item.tag
        switchView.addTarget(self, action: #selector(ThemesViewController.switchStateDidChange(_:)), for: .valueChanged)
        return cell
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return addTableCell(tableView, indexPath)
    }
    
    fileprivate func addThemes() {
        if themes.count <= Constants.themeColours.count
        {
            for colour in Constants.themeColours {
                let found = findObjectsByName(colour.key)
                if found .isEmpty {
                    for score in scoreItem {
                        if score.TotalScore > Int(colour.value[1])!
                        {
                            let themeItem = ThemeItem()
                            themeItem.Category = "Theme"
                            themeItem.name = colour.key
                            themeItem.hexColour = colour.value[0]
                            themeItem.UnlockLevel = Int(colour.value[1])!
                            themeItem.tag = Int(colour.value[2])!
                            try! self.realm.write {
                                self.realm.add(themeItem)
                            }
                        }
                    }
                }
            }
        }
    }
    
    public func findObjectsByName(_ Name: String) -> Results<ThemeItem>
    {
        let predicate = NSPredicate(format: "name = %@", Name)
        return realm.objects(ThemeItem.self).filter(predicate)
    }
}

