//
//  SettingsController.swift
//  Capstone
//
//  Created by Amy Alsaydi on 5/27/20.
//  Copyright © 2020 Amy Alsaydi. All rights reserved.
//

import UIKit
import FirebaseAuth
import MessageUI

class ProfileViewController: UIViewController {
    //MARK:- IBOutlets
    @IBOutlet weak var settingsTableView: UITableView!
    @IBOutlet weak var appLabel: UILabel!
    //MARK:- Variables
    private var allSettings = [ProfileCells]()
    private var appName = ApplicationInfo.getAppName()
    private var appVersion = ApplicationInfo.getVersionBuildNumber()
    //MARK:- ViewLifeCycles
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    override func viewWillAppear(_ animated: Bool) {
        configureTableView()
        allSettings = ProfileCells.loadProfileCells()
        navigationItem.title = "Profile"
        appLabel.text = "\(appName) \(appVersion)"
        navigationController?.navigationBar.prefersLargeTitles = true
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    //MARK:- Functions
    private func configureTableView() {
        settingsTableView.dataSource = self
        settingsTableView.delegate = self
        settingsTableView.register(UINib(nibName: "ProfileCell", bundle: nil), forCellReuseIdentifier: "profileCell")
        settingsTableView.tintColor = .systemPurple
    }
    private func canSendMail() -> Bool {
        return MFMailComposeViewController.canSendMail()
    }
}
//MARK:- Extensions
extension ProfileViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return allSettings.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "profileCell", for: indexPath) as? ProfileCell else {
            fatalError()
        }
        let aSetting = allSettings[indexPath.row]
        cell.configureCell(setting: aSetting)
        cell.settingsImage.tintColor = AppColors.primaryPurpleColor
        cell.settingsName.font = AppFonts.primaryFont
        cell.selectionStyle = .none
        return cell
    }
}
extension ProfileViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 40
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let profileCellSelected = allSettings[indexPath.row]
        let destinationViewController = allSettings[indexPath.row].viewController
        if profileCellSelected.title != ProfileCells.profileCellType.contact.rawValue {
            navigationController?.pushViewController(destinationViewController, animated: true)
        } else {
            if canSendMail() {
                let composeVC = MFMailComposeViewController()
                composeVC.mailComposeDelegate = self
                composeVC.setToRecipients(["CareerViewAppTeam@gmail.com"])
                composeVC.setSubject("Greetings!")
                self.present(composeVC, animated: true, completion: nil)
            } else {
                showAlert(title: "Something went wrong", message: "Please check you have configured your mail app and try again")
            }
        }
    }
}
extension ProfileViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
}
