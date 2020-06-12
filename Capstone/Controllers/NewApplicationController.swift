//
//  NewApplicationController.swift
//  Capstone
//
//  Created by Amy Alsaydi on 5/26/20.
//  Copyright © 2020 Amy Alsaydi. All rights reserved.
//

import UIKit

class NewApplicationController: UIViewController {
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var companyNameTextField: FloatingLabelInput!
    @IBOutlet weak var jobTitleTextField: FloatingLabelInput!
    @IBOutlet weak var linkTextField: FloatingLabelInput!
    @IBOutlet weak var locationTextField: FloatingLabelInput!
    @IBOutlet weak var notesLabel: FloatingLabelInput!
    @IBOutlet weak var deteTextField: FloatingLabelInput!
    
    // InterviewEntryViews + height constraints
    
    @IBOutlet weak var InterviewEntryView1: InterviewEntryView!
    @IBOutlet weak var InterviewEntryView1Height: NSLayoutConstraint!
    
    @IBOutlet weak var InterviewEntryView2: InterviewEntryView!
    @IBOutlet weak var InterviewEntryView2Height: NSLayoutConstraint!
    
    @IBOutlet weak var InterviewEntryView3: InterviewEntryView!
    @IBOutlet weak var InterviewEntryView3Height: NSLayoutConstraint!
    
    
    @IBOutlet weak var addInterviewStack: UIStackView!
    
    
    private var interviewViewHeight: NSLayoutConstraint!
    
    private var interviewCount = 0
   
    let datePicker = UIDatePicker()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        styleAllTextFields()
        configureNavBar()
        createDatePicker()
    }
    
    private func configureNavBar() {
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "checkmark"), style: .plain, target: self, action: #selector(saveJobApplicationButtonPressed(_:)))
    }
    
    func createDatePicker() {
        // toolbar
        let toolbar = UIToolbar()
        
        toolbar.sizeToFit()
        
        // bar button
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: nil, action: #selector(doneButtonPressed))
        toolbar.setItems([doneButton], animated: true)
        
        // assign toolbar
        deteTextField.inputAccessoryView = toolbar
        
        // assign date picker to text feild
        deteTextField.inputView = datePicker
        
        // date picker mode
        datePicker.datePickerMode = .date
    }
    
    @objc func doneButtonPressed() {
        deteTextField.text = "\(datePicker.date.dateString("MM/dd/yyyy"))"
        self.view.endEditing(true)
    }
    
    private func styleAllTextFields() {

        let textFields = [companyNameTextField, jobTitleTextField, linkTextField, locationTextField, notesLabel, deteTextField]

        for field in textFields {
            field?.styleTextField()
        }
    }
    
    @objc private func saveJobApplicationButtonPressed(_ sender: UIBarButtonItem) {
        // create new application and add to datebase
        // add the interview (if there is any as a collection to that application 
        
    }
    
    @IBAction func hasAppliedButtonChecked(_ sender: UIButton) {
        
        // animate and display the date applied stack
        
        
    }
    
    
    @IBAction func addInterviewButtonPressed(_ sender: UIButton) {
        // i have to also consider if they change their mind on the addition of an interview and would like delete
        
        // TODO:
        // create the interview view
        // have it require an initializer that takes in a number that will be assigned to the label on the view that tells them which interview theyre entering
 
        interviewCount += 1
        
        switch interviewCount {
        case 1:
            interviewViewHeight = InterviewEntryView1Height
        case 2:
            interviewViewHeight = InterviewEntryView2Height
        case 3:
            interviewViewHeight = InterviewEntryView3Height
        default:
            print("sorry no more than 3 interviews: this should be an alert controller -> suggest for user to get rid of old interviews")
        }
        
       
        view.layoutIfNeeded() // force any pending operations to finish

        UIView.animate(withDuration: 0.3, animations: { () -> Void in
            self.interviewViewHeight.constant = 150
            self.view.layoutIfNeeded()
        })
        
        
        if interviewCount == 3 {
            addInterviewStack.isHidden = true
            // hide button maybe ?
        }
        
    }
    
    

}


/*
 key board handling:
 - manipulate scroll view frame - height constraint
 - maniplute scroll view to move to current text field
 */
