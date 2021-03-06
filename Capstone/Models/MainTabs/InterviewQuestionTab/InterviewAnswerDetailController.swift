//
//  InterviewAnswerDetailController.swift
//  Capstone
//
//  Created by Amy Alsaydi on 5/26/20.
//  Copyright © 2020 Amy Alsaydi. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class InterviewAnswerDetailController: UIViewController {
    //MARK:- IBOutlets
    @IBOutlet weak var questionLabel: UILabel!
    @IBOutlet weak var answersCollectionView: UICollectionView!
    @IBOutlet weak var starStoriesCollectionView: UICollectionView!
    @IBOutlet weak var addAnswerButton: UIButton!
    @IBOutlet weak var enterAnswerTextfield: UITextField!
    @IBOutlet weak var confirmAddAnswerButton: UIButton!
    @IBOutlet weak var cancelAnswerButton: UIButton!
    @IBOutlet weak var addStarButton: UIButton!
    @IBOutlet weak var promptLabel: UILabel!
    @IBOutlet weak var answersLabel: UILabel!
    @IBOutlet weak var starstoriesLabel: UILabel!
    @IBOutlet weak var scrollView: UIScrollView!
    //MARK:- Variables
    private var listener: ListenerRegistration?
    public var question: InterviewQuestion?
    private var isBookmarked = false {
        didSet {
            if isBookmarked {
                navigationItem.rightBarButtonItem?.image = AppButtonIcons.bookmarkFillIcon
            } else {
                navigationItem.rightBarButtonItem?.image = AppButtonIcons.bookmarkIcon
            }
        }
    }
    private var isEditingAnswer = false
    private var answerBeingEdited: AnsweredQuestion?
    public var answers = [AnsweredQuestion]() {
        didSet {
            answersCollectionView.reloadData()
            if answers.isEmpty {
                answersCollectionView.backgroundView = EmptyView.init(title: "No Answers", message: "Add your answers by pressing the add button", imageName: "pencil")
            } else {
                answersCollectionView.reloadData()
                answersCollectionView.backgroundView = nil
                answerStrings = answers.first?.answers ?? []
                print("This is the number of answers \(answers.count)")
            }
        }
    }
    public var answerStrings = [String]()
    private var newAnswers = [String]()
    private var newStarStoryIDs = [String]()
    public var starStories = [StarSituation]() {
        didSet {
            starStoriesCollectionView.reloadData()
            if starStories.isEmpty {
                starStoriesCollectionView.backgroundView = EmptyView.init(title: "No STAR Stories", message: "Add your story by pressing the add button", imageName: "star.fill")
            } else {
                starStoriesCollectionView.reloadData()
                starStoriesCollectionView.backgroundView = nil
            }
        }
    }
    //MARK:- ViewLifeCycles
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        guard let user = Auth.auth().currentUser else {return}
        listener = Firestore.firestore().collection(DatabaseService.userCollection).document(user.uid).collection(DatabaseService.answeredQuestionsCollection).addSnapshotListener({ [weak self] (snapshot, error) in
            if let error = error {
                print("listener could not recieve changes for user answers error: \(error.localizedDescription)")
            } else if let snapshot = snapshot {
                let userAnswers = snapshot.documents.map { AnsweredQuestion($0.data()) }
                self?.answers = userAnswers.filter {$0.question == self?.question?.question}
                self?.getUserSTARS()
            }
        })
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        getUserSTARS()
        getUserAnswers()
        updateUI()
        enterAnswerTextfield.delegate = self
    }
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(true)
        listener?.remove()
    }
    //MARK:- Functions
    private func appFonts() {
        questionLabel.font = AppFonts.semiBoldLarge
        promptLabel.font = AppFonts.secondaryFont
        answersLabel.font = AppFonts.secondaryFont
        starstoriesLabel.font = AppFonts.secondaryFont
    }
    private func appColors() {
        promptLabel.textColor = AppColors.primaryBlackColor
        answersLabel.textColor = AppColors.darkGrayHighlightColor
        starstoriesLabel.textColor = AppColors.darkGrayHighlightColor
        answersCollectionView.backgroundColor = AppColors.complimentaryBackgroundColor
        starStoriesCollectionView.backgroundColor = AppColors.complimentaryBackgroundColor
        addStarButton.tintColor = AppColors.secondaryPurpleColor
        addAnswerButton.tintColor = AppColors.secondaryPurpleColor
        cancelAnswerButton.tintColor = AppColors.secondaryPurpleColor
        confirmAddAnswerButton.tintColor = AppColors.secondaryPurpleColor
    }
    private func updateUI() {
        appFonts()
        appColors()
        hideAddAnswerElements()
        configureNavBar()
        configureCollectionViews()
        isQuestionBookmarked(question: question)
        questionLabel.text = question?.question
        scrollView.keyboardDismissMode = .onDrag
    }
    //MARK:- Collection View Config
    private func configureCollectionViews() {
        answersCollectionView.keyboardDismissMode = .onDrag
        answersCollectionView.delegate = self
        answersCollectionView.dataSource = self
        answersCollectionView.register(UINib(nibName: "QuestionAnswerDetailCellXib", bundle: nil), forCellWithReuseIdentifier: "interviewAnswerCell")
        starStoriesCollectionView.keyboardDismissMode = .onDrag
        starStoriesCollectionView.delegate = self
        starStoriesCollectionView.dataSource = self
        starStoriesCollectionView.register(UINib(nibName: "StarSituationCellXib", bundle: nil), forCellWithReuseIdentifier: "starSituationCell")
    }
    //MARK:- Config NavBar & Nav Bar Button functions
    private func configureNavBar() {
        navigationItem.title = "Answer Question"
        let saveQuestionButton = UIBarButtonItem(image: AppButtonIcons.bookmarkIcon, style: .plain, target: self, action: #selector(addQuestionToSavedQuestionsButtonPressed(_:)))
        let suggestionButton = UIBarButtonItem(image: AppButtonIcons.infoIcon, style: .plain, target: self, action: #selector(suggestionButtonPressed(_:)))
        navigationItem.rightBarButtonItems = [saveQuestionButton, suggestionButton]
    }
    @objc private func suggestionButtonPressed(_ sender: UIBarButtonItem) {
        let infoViewController = MoreInfoViewController(nibName: "MoreInfoControllerXib", bundle: nil)
        infoViewController.modalTransitionStyle = .crossDissolve
        infoViewController.modalPresentationStyle = .overFullScreen
        infoViewController.enterFrom = .interviewAnswer
        infoViewController.interviewQuestion = question
        present(infoViewController, animated: true)
    }
    @objc private func addQuestionToSavedQuestionsButtonPressed(_ sender: UIBarButtonItem) {
        self.showIndicator()
        guard let question = question else {return}
        if isBookmarked {
            DatabaseService.shared.removeQuestionFromBookmarks(question: question) { [weak self] (result) in
                switch result {
                case .failure(let error):
                    DispatchQueue.main.async {
                        self?.removeIndicator()
                        self?.showAlert(title: "Error", message: "Unable to remove \(question.question) from your bookmarks error: \(error.localizedDescription)")
                    }
                case .success:
                    DispatchQueue.main.async {
                        self?.removeIndicator()
                        self?.showAlert(title: "Removed", message: "\(question.question) has been removed")
                    }
                    self?.isBookmarked = false
                }
            }
        } else {
            DatabaseService.shared.addQuestionToBookmarks(question: question) { [weak self] (result) in
                switch result {
                case .failure(let error):
                    DispatchQueue.main.async {
                        self?.removeIndicator()
                        self?.showAlert(title: "Error", message: "Unable to add \(question.question) to your bookmarks at this time error: \(error.localizedDescription)")
                    }
                case.success:
                    DispatchQueue.main.async {
                        self?.removeIndicator()
                        self?.showAlert(title: "Added To Your Bookmarks", message: "\(question.question) has been added")
                    }
                    self?.isBookmarked = true
                }
            }
        }
    }
    //MARK:- Hide/Show methods
    private func hideAddAnswerElements() {
        cancelAnswerButton.isHidden = true
        confirmAddAnswerButton.isHidden = true
        enterAnswerTextfield.isHidden = true
        enterAnswerTextfield.text = ""
        answersCollectionView.isHidden = false
        addAnswerButton.isHidden = false
    }
    private func showAddAnswerElements() {
        cancelAnswerButton.isHidden = false
        confirmAddAnswerButton.isHidden = false
        enterAnswerTextfield.isHidden = false
        answersCollectionView.isHidden = true
        addAnswerButton.isHidden = true
    }
    //MARK:- Get Data Methods
    private func getUserAnswers() {
        self.showIndicator()
        guard let question = question else {return}
        DatabaseService.shared.fetchAnsweredQuestions(questionString: question.question) { [weak self] (result) in
            switch result {
            case .failure(let error):
                print("unable to fetch user answers error: \(error.localizedDescription)")
            case .success(let answers):
                DispatchQueue.main.async {
                    self?.removeIndicator()
                    self?.answers = answers
                }
            }
        }
    }
    private func getUserSTARS() {
        self.showIndicator()
        DatabaseService.shared.fetchStarSituations { [weak self] (result) in
            switch result {
            case .failure(let error):
                print("unable to fetch user STAR stories error: \(error.localizedDescription)")
            case .success(let stars):
                DispatchQueue.main.async {
                    self?.removeIndicator()
                    self?.starStories = stars
                    var results = [StarSituation]()
                    for star in stars {
                        if self?.answers.first?.starSituationIDs.contains(star.id) ?? false {
                            results.append(star)
                        }
                    }
                    self?.starStories = results
                }
            }
        }
    }
    private func isQuestionBookmarked(question: InterviewQuestion?) {
        guard let question = question else {return}
        DatabaseService.shared.isQuestionInBookmarks(question: question) { [weak self] (result) in
            switch result {
            case.failure(let error):
                print("could not check bookmarks collection error: \(error.localizedDescription)")
            case.success(let successful):
                if successful == true {
                    self?.isBookmarked = true
                } else {
                    self?.isEditing = false
                }
            }
        }
    }
    //MARK:- Button IBActions
    @IBAction func addAnswerButtonPressed(_ sender: UIButton){
        showAddAnswerElements()
    }
    @IBAction func cancelAddAnswerButtonPressed(_ sender: UIButton) {
        hideAddAnswerElements()
    }
    @IBAction func confirmAddAnswerButtonPressed(_ sender: UIButton) {
        self.showIndicator()
        if isEditingAnswer == false {
            guard let answer = enterAnswerTextfield.text, !answer.isEmpty else {
                confirmAddAnswerButton.isEnabled = false
                return
            }
            newAnswers.append(answer)
            if answers.count == 0 {
                let newAnswer = AnsweredQuestion(id: UUID().uuidString, question: question?.question ?? "could not pass question", answers: newAnswers, starSituationIDs: newStarStoryIDs)
                DatabaseService.shared.addToAnsweredQuestions(answeredQuestion: newAnswer) { [weak self] (result) in
                    switch result {
                    case .failure(let error):
                        DispatchQueue.main.async {
                            self?.removeIndicator()
                            self?.showAlert(title: "Error", message: "Unable to add answer at this time error: \(error.localizedDescription)")
                        }
                    case .success:
                        DispatchQueue.main.async {
                            self?.removeIndicator()
                            self?.showAlert(title: "Answer Submitted!", message: "")
                        }
                    }
                }
            } else {
                let answerId = answers.first?.id ?? ""
                DatabaseService.shared.addAnswerToAnswersArray(answerID: answerId, answerString: answer) { [weak self] (result) in
                    switch result {
                    case .failure(let error) :
                        DispatchQueue.main.async {
                            self?.removeIndicator()
                            self?.showAlert(title: "Error", message: "Unable to add answer error: \(error.localizedDescription)")
                        }
                    case .success:
                        DispatchQueue.main.async {
                            self?.removeIndicator()
                            self?.showAlert(title: "Answer Submitted!", message: "")
                        }
                        
                    }
                }
            }
        } else {
            //TODO: 1. remove 2. add
            DatabaseService.shared.removeAnswerFromAnswersArray(answerID: answerBeingEdited?.id ?? "", answerString: answerBeingEdited?.answers.first ?? "") { (result) in
                switch result {
                case .failure(let error):
                    print("could not remove error: \(error.localizedDescription)")
                case .success:
                    print("removed \(self.answerBeingEdited?.answers.first ?? "")")
                }
            }
            DatabaseService.shared.addAnswerToAnswersArray(answerID: answerBeingEdited?.id ?? "", answerString: enterAnswerTextfield.text ?? "") { [weak self] (result) in
                switch result {
                case .failure(let error):
                    DispatchQueue.main.async {
                        self?.removeIndicator()
                        self?.showAlert(title: "Error", message: "Unable to update your answer \(error.localizedDescription)")
                    }
                case .success:
                    DispatchQueue.main.async {
                        self?.removeIndicator()
                        self?.showAlert(title: "Updated", message: "Your answer has been updated with your edits")
                    }
                }
            }
            
        }
        hideAddAnswerElements()
        isEditingAnswer = false
    }
    
    @IBAction func addSTARStoryButtonPressed(_ sender: UIButton) {
        let starStoryVC = StarStoryMainController(nibName: "StarStoryMainXib", bundle: nil)
        starStoryVC.isAddingToAnswer = true
        starStoryVC.answerId = answers.first?.id
        starStoryVC.question = question?.question
        present(UINavigationController(rootViewController: starStoryVC), animated: true)
    }
}
//MARK:- Extensions
//MARK: TextFieldDelegate
extension InterviewAnswerDetailController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        confirmAddAnswerButton.isEnabled = true
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
//MARK: CollectionView Delegate & DataSource
extension InterviewAnswerDetailController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let maxsize: CGSize = UIScreen.main.bounds.size
        let itemWidth: CGFloat = maxsize.width * 0.8
        return CGSize(width: itemWidth, height: itemWidth * 0.5)
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    }
}
//MARK: CollectionViewDataSource
extension InterviewAnswerDetailController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == answersCollectionView {
            return answerStrings.count
        } else {
            return starStories.count
        }
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == answersCollectionView {
            guard let cell = answersCollectionView.dequeueReusableCell(withReuseIdentifier: "interviewAnswerCell", for: indexPath) as? QuestionAnswerDetailCell else {
                fatalError("could not cast to QuestionAnswerDetailCell")
            }
            let answer = answerStrings[indexPath.row]
            cell.configureCell(answer: answer)
            return cell
        } else {
            guard let cell = starStoriesCollectionView.dequeueReusableCell(withReuseIdentifier: "starSituationCell", for: indexPath) as? StarSituationCell else {
                fatalError("could not cast to StarSituationCell")
            }
            let story = starStories[indexPath.row]
            cell.configureCell(starSituation: story)
            return cell
        }
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == answersCollectionView {
            guard let answer = answers.first else {return}
            answerBeingEdited = answer
            enterAnswerTextfield.text = answerBeingEdited?.answers[indexPath.row]
            showAnswersActionSheet(answer: answer)
        } else {
            let starStory = starStories[indexPath.row]
            guard let answer = answers.first else {return}
            showSTARActionSheet(answer: answer, starStory: starStory)
        }
    }
}
//MARK:- Action sheets for editing/deleting from collections
extension InterviewAnswerDetailController {
    private func showAnswersActionSheet(answer: AnsweredQuestion) {
        self.showIndicator()
        let actionSheet = UIAlertController(title: "Options Menu", message: nil, preferredStyle: .actionSheet)
        let editAction = UIAlertAction(title: "Edit", style: .default) { (action) in
            self.showAddAnswerElements()
            self.isEditingAnswer = true
        }
        let deleteAction = UIAlertAction(title: "Remove", style: .destructive) { [weak self] (action) in
            DatabaseService.shared.removeAnswerFromAnswersArray(answerID: answer.id, answerString: answer.answers.first ?? "") { (result) in
                switch result {
                case .failure(let error):
                    DispatchQueue.main.async {
                        self?.removeIndicator()
                        self?.showAlert(title: "Error", message: "Answer could not be removed at this time error: \(error.localizedDescription)")
                    }
                case .success:
                    DispatchQueue.main.async {
                        self?.removeIndicator()
                        self?.showAlert(title: "Removed", message: "Your answer has been removed")
                    }
                }
            }
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel)
        actionSheet.addAction(editAction)
        actionSheet.addAction(deleteAction)
        actionSheet.addAction(cancel)
        present(actionSheet, animated: true, completion: nil)
    }
    private func showSTARActionSheet(answer: AnsweredQuestion, starStory: StarSituation) {
        self.showIndicator()
        self.showAddAnswerElements()
        let actionSheet = UIAlertController(title: "Options Menu", message: nil, preferredStyle: .actionSheet)
        let editAction = UIAlertAction(title: "Edit", style: .default) { (action) in
            //present Star Story edit vc
            let starStoryEditVC = StarStoryEntryController(nibName: "StarStoryEntryXib", bundle: nil)
            starStoryEditVC.isEditingStarSituation = true
            starStoryEditVC.starSituation = starStory
            self.navigationController?.pushViewController(starStoryEditVC, animated: true)
        }
        let deleteAction = UIAlertAction(title: "Remove", style: .destructive) { (action) in
            DatabaseService.shared.removeStarSituationFromAnswer(answerID: answer.id, starSolutionID: starStory.id) { [weak self] (result) in
                switch result {
                case .failure(let error):
                    DispatchQueue.main.async {
                        self?.removeIndicator()
                        self?.showAlert(title: "Error", message: "Unable to remove STAR Story from this answer at this time error: \(error.localizedDescription)")
                    }
                case .success:
                    DispatchQueue.main.async {
                        self?.removeIndicator()
                        self?.showAlert(title: "Removed", message: "STAR Story was removed from answer")
                    }
                }
            }
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel)
        actionSheet.addAction(editAction)
        actionSheet.addAction(deleteAction)
        actionSheet.addAction(cancel)
        present(actionSheet, animated: true, completion: nil)
    }
}
