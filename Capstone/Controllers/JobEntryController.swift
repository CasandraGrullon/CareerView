//
//  JobEntryController.swift
//  Capstone
//
//  Created by Amy Alsaydi on 5/26/20.
//  Copyright © 2020 Amy Alsaydi. All rights reserved.
//

import UIKit
import Firebase
import Contacts
import ContactsUI

class JobEntryController: UIViewController {
    
    @IBOutlet var tableView: UITableView!
    
    //MARK:- Cells
    @IBOutlet var jobTitleCell: UITableViewCell!
    @IBOutlet var companyTitleCell: UITableViewCell!
    @IBOutlet var currentEmployerCell: UITableViewCell!
    @IBOutlet var beginEmploymentDateCell: UITableViewCell!
    @IBOutlet var endEmploymentCell: UITableViewCell!
    @IBOutlet var locationCell: UITableViewCell!
    @IBOutlet var descriptionCell: UITableViewCell!
    @IBOutlet var mainResponsiblityCell: UITableViewCell!
    @IBOutlet var responsiblity2Cell: UITableViewCell!
    @IBOutlet var responsiblity3Cell: UITableViewCell!
    @IBOutlet var addStarSituationCell: UITableViewCell!
    @IBOutlet var userContactsCVCell: UITableViewCell!
    //MARK:- Buttons
    @IBOutlet weak var currentlyEmployedButton: UIButton!
    @IBOutlet weak var addResponsibilityButton: UIButton!
    @IBOutlet weak var addStarSituationButton: UIButton!
    @IBOutlet weak var deleteResponsibiltyButton1: UIButton!
    @IBOutlet weak var deleteResponsibiltyButton2: UIButton!
    //MARK:- TextFields
    @IBOutlet weak var jobTitleTextField: UITextField!
    @IBOutlet weak var companyNameTextField: UITextField!
    @IBOutlet weak var beginDateMonthTextField: UITextField!
    @IBOutlet weak var beginDateYearTextField: UITextField!
    @IBOutlet weak var locationTextField: UITextField!
    @IBOutlet weak var descriptionTextField: UITextField!
    @IBOutlet weak var endDateMonthTextField: UITextField!
    @IBOutlet weak var endDateYearTextField: UITextField!
    @IBOutlet weak var responsibility1TextField: UITextField!
    @IBOutlet weak var responsibility2TextField: UITextField!
    @IBOutlet weak var responsibility3TextField: UITextField!
    
    @IBOutlet weak var userContactsCollectionView: UICollectionView!
    
    //MARK:- Variables
    public var userJob: UserJob?
    private var testUserJob = UserJob(title: "Retail Employee", companyName: "Sonos", beginDate: Timestamp(date: Date(timeIntervalSince1970: 1464783949)), endDate: Timestamp(date: Date(timeIntervalSince1970: 1509539149)), currentEmployer: true, description: "Assisted customers with making purchase decisions", responsibilities: ["Operated POS for transactions","Helped customers troubleshoot products"], starSituationIDs: [], interviewQuestionIDs: [], contactIDs: [], contacts: [])
    
    public var editingJob = true
    
    private var currentlyEmployed: Bool = false {
        didSet {
            configureCurrentlyEmployedButton(currentlyEmployed)
        }
    }
    private var userJobResponsibilities = [String]() {
        didSet {
            // Disable add responsibility button
            if userJobResponsibilities.count == 3 {
                addResponsibilityButton.isEnabled = false
            } else {
                addResponsibilityButton.isEnabled = true
            }
        }
    }
    
    //TODO: Change this variable
    private var numberOfResponsibilityCells = 2 {
        didSet {
            if numberOfResponsibilityCells == 4 {
                addResponsibilityButton.isEnabled = false
            } else {
                addResponsibilityButton.isEnabled = true
            }
        }
    }
    private var contacts = [CNContact]()
    private var userContacts = [Contact]() {
        didSet {
            self.tableView.reloadData()
            self.userContactsCollectionView.reloadData()
        }
    }

    //MARK:- ViewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        setupTextFields()
        setupNavigationBar()
        listenForKeyboardEvents()
        loadUserJob()
    }
    private func configureView() {
        view.backgroundColor = #colorLiteral(red: 0.921431005, green: 0.9214526415, blue: 0.9214410186, alpha: 1)
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.keyboardDismissMode = .onDrag
        self.userContactsCollectionView.delegate = self
        self.userContactsCollectionView.dataSource = self
        self.userContactsCollectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        self.userContactsCollectionView.register(UINib(nibName: "UserContactCVCell", bundle: nil), forCellWithReuseIdentifier: "userContactCell")
    }
    private func loadUserJob() {
        if editingJob {
            jobTitleTextField.text = testUserJob.title
            companyNameTextField.text = testUserJob.companyName
            //TODO: Make decision about how to present date. Date picker or formate date with/to textFields?
            currentlyEmployed = testUserJob.currentEmployer
            beginDateMonthTextField.text = testUserJob.beginDate.dateValue().description
            beginDateYearTextField.text = testUserJob.beginDate.dateValue().description
            endDateMonthTextField.text = testUserJob.endDate.dateValue().description
            endDateYearTextField.text = testUserJob.endDate.dateValue().description
            //TODO: Update userJob model to contain location
//            locationTextField.text = userJob?.location
            descriptionTextField.text = testUserJob.description
            userJobResponsibilities = testUserJob.responsibilities
            //TODO: Add star situations, add contacts
        }
    }
    private func setupNavigationBar() {
        navigationItem.title = "Create new Job"
        let rightBarButton = UIBarButtonItem(title: "Save", style: .plain, target: self, action: #selector(saveButtonPressed(_:)))
        navigationItem.rightBarButtonItem = rightBarButton
    }
    private func setupTextFields() {
        let toolbar = UIToolbar(frame: CGRect(origin: .zero,
                                              size: .init(width: view.frame.size.width, height: 30)))
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace,
                                        target: nil, action: nil)
        let doneButton = UIBarButtonItem(title: "Done",
                                         style: .done,
                                         target: self,
                                         action: #selector(doneButtonAction))
        toolbar.setItems([flexSpace, doneButton], animated: false)
        toolbar.sizeToFit()
        
        let textFields = [jobTitleTextField, companyNameTextField, beginDateYearTextField, beginDateMonthTextField, endDateYearTextField, endDateMonthTextField, locationTextField, descriptionTextField, responsibility1TextField, responsibility2TextField, responsibility3TextField]
        for field in textFields {
            field?.delegate = self
            field?.inputAccessoryView = toolbar
            field?.setPadding()
            field?.setBottomBorder()
        }
    }
    
    private func addRows(numOfRows: Int, section: Int) {
        let indexPath = IndexPath(row: numOfRows - 1, section: section)
        tableView.beginUpdates()
        tableView.insertRows(at: [indexPath], with: .right)
        tableView.endUpdates()
    }
    private func deleteRows(row: Int, section: Int) {
        //        let indexPath = userJob?.responsibilities.firstIndex(of: String)
        let indexPath = IndexPath(row: row, section: section)
        tableView.beginUpdates()
        tableView.reloadRows(at: [indexPath], with: .top)
        tableView.endUpdates()
        tableView.reloadData()
    }
    @IBAction func deleteResponsibiltyCellButtonPressed(_ sender: UIButton) {
        
        deleteRows(row: 2, section: 1)
        
        numberOfResponsibilityCells -= 1
        
    }
    @IBAction func addResponsibilityButtonPressed(_ sender: UIButton) {
        
        numberOfResponsibilityCells += 1
        
        addRows(numOfRows: numberOfResponsibilityCells, section: 1)
    }
    
    @IBAction func addContactButtonPressed(_ sender: UIButton) {
        let contactPicker = CNContactPickerViewController()
        contactPicker.delegate = self
        //        contactPicker.predicateForEnablingContact = NSPredicate(format: "emailAddresses.@count > 0")
        present(contactPicker, animated: true)
    }
    private func listenForKeyboardEvents() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange(notification:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }
    
    @objc func doneButtonAction() {
        self.view.endEditing(true)
    }
    private func configureCurrentlyEmployedButton(_ currentlyEmployed: Bool) {
        if let job = userJob {
            self.currentlyEmployed = job.currentEmployer
        }
        if currentlyEmployed {
            currentlyEmployedButton.setImage(UIImage(systemName: "checkmark.square"), for: .normal)
        } else {
            currentlyEmployedButton.setImage(UIImage(systemName: "square"), for: .normal)
        }
    }
    @objc private func saveButtonPressed(_ sender: UIBarButtonItem) {
        print("save pressed")
    }
    @IBAction func currentlyEmployedButtonPressed(_ sender: UIButton) {
        currentlyEmployed.toggle()
    }
    @objc func keyboardWillChange(notification: Notification) {
        guard let keyboardRect = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue else {
            return
        }
        //         Move entire view by height of the keyboard and reset
        if notification.name == UIResponder.keyboardWillShowNotification || notification.name == UIResponder.keyboardWillChangeFrameNotification {
            view.frame.origin.y = -keyboardRect.height
        } else {
            view.frame.origin.y = 0
        }
    }
    private func scrollToRow(row: Int, section: Int) {
            let indexPath = IndexPath(row: row, section: section)
            self.tableView.scrollToRow(at: indexPath, at: .middle, animated: true)
        }
}
//MARK:- TableViewController Datasource/Delegate
extension JobEntryController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Details"
        case 1:
            return "Description"
        case 2:
            return "Responsibilities"
        case 3:
            return "STAR Situations: \(userJob?.starSituationIDs.count ?? 0)"
        case 4:
            return "Contacts/Co-workers: \(userContacts.count)"
        default:
            return "What?"
        }
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return 5
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 6
        case 1:
            return 1
        case 2:
            if userJobResponsibilities.count == 0 {
                return 1
            } else {
            return userJobResponsibilities.count
            }
        case 3:
            return 1
        case 4:
            return 1
        default:
            return 1
        }
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0:
                return jobTitleCell
            case 1:
                return companyTitleCell
            case 2:
                configureCurrentlyEmployedButton(currentlyEmployed)
                return currentEmployerCell
            case 3:
                return beginEmploymentDateCell
            case 4:
                return endEmploymentCell
            case 5:
                return locationCell
            default:
                return jobTitleCell
            }
        case 1:
            return descriptionCell
        case 2:
            switch indexPath.row {
            case 0:
                if editingJob {
                responsibility1TextField.text = userJobResponsibilities[indexPath.row]
                }
                return mainResponsiblityCell
            case 1:
                if editingJob {
                responsibility2TextField.text = userJobResponsibilities[indexPath.row]
                }
                return responsiblity2Cell
            case 2:
                if editingJob {
                responsibility3TextField.text = userJobResponsibilities[indexPath.row]
                }
                return responsiblity3Cell
            default:
                if editingJob {
                responsibility1TextField.text = userJobResponsibilities[indexPath.row]
                }
                return mainResponsiblityCell
            }
        case 3:
            switch indexPath.row {
            case 0:
                return addStarSituationCell
            default:
                return addStarSituationCell
            }
        case 4:
            switch indexPath.row {
            case 0:
                return userContactsCVCell
            default:
                return userContactsCVCell
            }
        default:
            break
        }
        return jobTitleCell
    }
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        if indexPath.section == 2 {
            if indexPath.row > 0 {
                return .delete
            } else {
                return .none
            }
        } else {
            return .none
        }
    }
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if indexPath.section == 2 {
            if indexPath.row > 0 {
            if editingStyle == UITableViewCell.EditingStyle.delete {
                userJobResponsibilities.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: UITableView.RowAnimation.automatic)
                }
            }
        }
    }
}
extension JobEntryController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 2 {
            currentlyEmployed.toggle()
        }
    }
}

//MARK:- UITextField Delegate
extension JobEntryController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        let row = textField.tag
        //TODO: How to get section?
        // Keyboard handling: Is scrolling the view what we want here?
//        scrollToRow(row: row, section: ?)
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

//MARK:- UITextField Extension
extension UITextField {
    func setPadding() {
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: self.frame.height))
        self.leftView = paddingView
        self.leftViewMode = .always
        self.layer.backgroundColor = UIColor.white.cgColor
    }
    func setBottomBorder() {
        self.layer.shadowColor = UIColor.systemGray.cgColor
        self.layer.shadowOffset = CGSize(width: 0.0, height: 1.0)
        self.layer.shadowOpacity = 1.0
        self.layer.shadowRadius = 0.0
        self.layer.backgroundColor = UIColor.white.cgColor
    }
}
//MARK:- CollectionView Extension
extension JobEntryController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
    }
    
}
extension JobEntryController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let contact = userContacts[indexPath.row]
        let contactViewController = CNContactViewController(forUnknownContact: contact.contactValue)
        navigationController?.pushViewController(contactViewController, animated: true)
    }
}
extension JobEntryController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return userContacts.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "userContactCell", for: indexPath) as? UserContactCVCell else {
            fatalError("failed to dequeue userContactCell")
        }
        let contact = userContacts[indexPath.row]
        cell.configureCell(contact: contact)
        return cell
    }
    
    
}
//MARK:- CNContactPickerDelegate
extension JobEntryController: CNContactPickerDelegate {
    func contactPicker(_ picker: CNContactPickerViewController, didSelect contacts: [CNContact]) {
        let newContacts = contacts.compactMap { Contact(contact: $0) }
        for contact in newContacts {
            if !userContacts.contains(contact) {
                self.userContacts.append(contact)
            }
        }
    }
}
