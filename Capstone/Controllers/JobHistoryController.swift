//
//  JobHistoryController.swift
//  Capstone
//
//  Created by Amy Alsaydi on 5/26/20.
//  Copyright © 2020 Amy Alsaydi. All rights reserved.
//

import UIKit

class JobHistoryController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    private var userData: User?
    
    private var displayContactCollectionView = false
    
    var userJobHistory = [UserJob]() {
        didSet {
            self.tableView.reloadData()
            self.setup()
        }
    }
    
    enum Const {
        static let closeCellHeight: CGFloat = 180
        static let openCellHeight: CGFloat = 620
    }
    
    var cellHeights = [CGFloat]()
        
    override func viewDidLoad() {
        super.viewDidLoad()
        configureTableView()
        configureNavBar()
        
        getUserData()
        checkFirstTimeLogin()
        
        loadUserJobs()
        setup()
        
        
    }
    override func viewDidAppear(_ animated: Bool) {
        loadUserJobs()
//        tableView.reloadData()
    }
    private func configureTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "UserJobFoldingCellXib", bundle: nil), forCellReuseIdentifier: "foldingCell")
    }
    
    private func setup() {
        cellHeights = Array(repeating: Const.closeCellHeight, count: userJobHistory.count)
    }
    
    private func configureNavBar() {

        navigationItem.title = "CareerView"

        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "plus"), style: .plain, target: self, action: #selector(segueToJobEntryVC(_:)))
    }
    @objc private func segueToJobEntryVC(_ sender: UIBarButtonItem) {
//        let jobEntryController = JobEntryController(nibName: "JobEntryXib", bundle: nil)
//        show(jobEntryController, sender: nil)
        
        let jobEntryController = NewJobEntryController(nibName: "NewJobEntryXib", bundle: nil)
        show(jobEntryController, sender: nil)
        
    }

    private func getUserData() {
        DatabaseService.shared.fetchUserData { [weak self] (result) in
            switch result {
            case .failure(let error):
                DispatchQueue.main.async {
                    print("Error fetching user Data: \(error.localizedDescription)")
                }
            case .success(let userData):
                DispatchQueue.main.async {
                    self?.userData = userData
                    self?.checkFirstTimeLogin()
                }
            }
        }
    }
    private func checkFirstTimeLogin() {
        guard let user = userData else { return }
        if user.firstTimeLogin {
            print("First time logging in")
            //Eventually move this to the viewcontroller file once the user has completed the on boarding experience
            let firstTimeUserExperienceViewController = FirstTimeUserExperienceViewController(nibName: "FirstTimeUserExperienceViewControllerXib", bundle: nil)
            show(firstTimeUserExperienceViewController, sender: nil)
        } else {
            print("User has logged in before")
        }
    }
    //TODO:- Add database function to grab user jobs data from firebase
    private func loadUserJobs() {
        self.showIndicator()
        DatabaseService.shared.fetchUserJobs { [weak self] (result) in
            switch result {
            case .failure(let error):
                self?.removeIndicator()
                print("error fetching user jobs\(error.localizedDescription)")
            case .success(let userJobHistory):
                DispatchQueue.main.async {
                    self?.removeIndicator()
                    self?.userJobHistory = userJobHistory
                }
            }
        }
    }
}

extension JobHistoryController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // TODO:- add data count
        return userJobHistory.count
    }
        
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //TODO:- Update this function to take in foldable cell
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "foldingCell", for: indexPath) as? JobHistoryExpandableCell else {
            fatalError("could not cast to jobHistoryBasicCell")
        }
        let durations: [TimeInterval] = [0.26, 0.3, 0.3]
        cell.delegate = self
        cell.durationsForExpandedState = durations
        cell.durationsForCollapsedState = durations
        return cell
    }
}
extension JobHistoryController: JobHistoryExpandableCellDelegate {
    func starSituationsButtonPressed(userJob: UserJob) {
        let destinationViewController = StarStoryMainController(nibName: "StarStoryMainXib", bundle: nil)
        destinationViewController.filterByJob = true
        destinationViewController.userJob = userJob
        navigationController?.pushViewController(destinationViewController, animated: true)
    }
    func contextButtonPressed(userJob: UserJob) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { alertaction in self.deleteUserJob(userJob: userJob) }
        let editAction = UIAlertAction(title: "Edit", style: .default) {
            alertAction in self.editUserJob(userJob: userJob)
        }
        alertController.addAction(editAction)
        alertController.addAction(cancelAction)
        alertController.addAction(deleteAction)
        present(alertController, animated: true, completion: nil)
    }
    private func editUserJob(userJob: UserJob) {
        
        let destinationViewController = NewJobEntryController(nibName: "NewJobEntryXib", bundle: nil)
        destinationViewController.userJob = userJob
        destinationViewController.editingJob = true
        navigationController?.pushViewController(destinationViewController, animated: true)
    }
    private func deleteUserJob(userJob: UserJob) {
        self.showIndicator()
        guard let index = userJobHistory.firstIndex(of: userJob) else {
            return }
        DispatchQueue.main.async {
            DatabaseService.shared.removeUserJob(userJobId: userJob.id) {
               [weak self] (result) in
                switch result {
                case .failure(let error):
                    self?.removeIndicator()
                    self?.showAlert(title: "Failed to delete job", message: error.localizedDescription)
                case .success:
                    self?.removeIndicator()
                    self?.showAlert(title: "Success", message: "User job deleted")
                    self?.userJobHistory.remove(at: index)
                }
            }
        }
    }
}
extension JobHistoryController: UITableViewDelegate {
    func tableView(_: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeights[indexPath.row]
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as! JobHistoryExpandableCell
        displayContactCollectionView.toggle()
        let aUserJobHistory = userJobHistory[indexPath.row]
        if displayContactCollectionView == true {
            cell.loadUserContacts(userJob: aUserJobHistory)
        }
        if cell.isAnimating() {
            return
        }
        var duration = 0.0
        let cellIsCollapsed = cellHeights[indexPath.row] == Const.closeCellHeight
        if cellIsCollapsed {
            cellHeights[indexPath.row] = Const.openCellHeight
            cell.unfold(true, animated: true, completion: nil)
            duration = 0.5
        } else {
            cellHeights[indexPath.row] = Const.closeCellHeight
            cell.unfold(false, animated: true, completion: nil)
            duration = 0.8
        }
        
        UIView.animate(withDuration: duration, delay: 0, options: .curveEaseOut, animations: { () -> Void in
            tableView.beginUpdates()
            tableView.endUpdates()
            
            if cell.frame.maxY > tableView.frame.maxY {
                tableView.scrollToRow(at: indexPath, at: UITableView.ScrollPosition.bottom, animated: true)
            }
        }, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard case let cell as JobHistoryExpandableCell = cell else {
            return
        }
        
        cell.backgroundColor = .clear
        
        if cellHeights[indexPath.row] == Const.closeCellHeight {
            cell.unfold(false, animated: false, completion: nil)
        } else {
            cell.unfold(true, animated: false, completion: nil)
        }
        
        let aUserJobHistory = userJobHistory[indexPath.row]
        cell.updateGeneralInfo(userJob: aUserJobHistory)
    }
}

