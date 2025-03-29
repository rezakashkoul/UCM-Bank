import UIKit
import RxSwift
import RxKeyboard

protocol SecurityQuestionViewControllerDelegate: AnyObject {
    func setUsername(_ username: String)
}

class SecurityQuestionViewController: UIViewController {
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var usernameStackView: UIStackView!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var question1TextField: UITextField!
    @IBOutlet weak var question2TextField: UITextField!
    @IBOutlet weak var question3TextField: UITextField!
    
    @IBOutlet weak var submitButtonBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var submitButton: UIButton!
    @IBAction func submitButtonAction(_ sender: Any) {
        submitAction()
    }
    
    weak var delegate: SecurityQuestionViewControllerDelegate?
    var disposeBag = DisposeBag()
    var textFields: [UITextField]!
    var isUserRegistering: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        scrollView.slideUpViews(delay: 0.1)
    }
    
}

//MARK: - Setup Views
extension SecurityQuestionViewController {
    
    func setupViews() {
        handleKeyboardVisibility()
        setupTextFields()
        submitButton.dropShadowAndCornerRadius(.regular)
        usernameStackView.isHidden = isUserRegistering ? true : false
    }
    
    func setupTextFields() {
        textFields = view.getTextfields(view)
        textFields.forEach({$0.delegate = self})
        textFields.forEach({$0.addDoneToolbar()})
        usernameTextField.becomeFirstResponder()
    }
}

//MARK: - TextField Functions
extension SecurityQuestionViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case usernameTextField:
            question1TextField.becomeFirstResponder()
        case question1TextField:
            question2TextField.becomeFirstResponder()
        case question2TextField:
            question3TextField.becomeFirstResponder()
        case question3TextField:
            question3TextField.resignFirstResponder()
            submitAction()
        default: break
        }
        return true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
}

//MARK: - Keyboard Functions
private extension SecurityQuestionViewController {
    
    func handleKeyboardVisibility() {
        RxKeyboard.instance.visibleHeight
            .drive(onNext: { [weak self] keyboardVisibleHeight in
                guard let self = self else { return }
                self.submitButtonBottomConstraint.constant = (keyboardVisibleHeight == 0) ? 20 : keyboardVisibleHeight
                UIView.animate(withDuration: 0.3) {
                    self.view.layoutIfNeeded()
                } completion: { _ in
                    self.scrollView.scrollToBottom()
                }
            }).disposed(by: disposeBag)
    }
}

//MARK: - Actions
private extension SecurityQuestionViewController {
    
    func submitAction() {
        let text1 = question1TextField.text ?? ""
        let text2 = question2TextField.text ?? ""
        let text3 = question3TextField.text ?? ""
        if !text1.isEmpty && !text2.isEmpty && !text3.isEmpty {
            let securityAnswers = [SecurityAnswer(answer: text1), SecurityAnswer(answer: text2), SecurityAnswer(answer: text3)]
            if isUserRegistering {
                currentUser?.personalInfo.securityAnswers = securityAnswers
                allUsers.append(currentUser!)
                UserDefaults.standard.saveUsers()
                print("user is \(String(describing: currentUser))")
                print("Account successfully created.")
                showLoginViewController()
                currentUser = nil
                BannerManager.showMessage(messageText: "Success", messageSubtitle: "You're account created successfully.", style: .success)
            } else {
                let username = usernameTextField.text?.lowercased() ?? ""
                for i in 0..<allUsers.count {
                    if allUsers[i].personalInfo.username.lowercased() == username && allUsers[i].personalInfo.securityAnswers == securityAnswers {
                        currentUser = allUsers[i]
                        showChangePasswordViewController()
                        return
                    }
                }
                BannerManager.showMessage(messageText: "Incorrect", messageSubtitle: "Pleas think twice", style: .danger)
            }
        } else {
            BannerManager.showMessage(messageText: "Error!", messageSubtitle: "Please fill all fields", style: .danger)
        }
    }
}

//MARK: - Navigation Functions
extension SecurityQuestionViewController {
    
    func showChangePasswordViewController() {
        let viewController = storyboard?.instantiateViewController(withIdentifier: "ChangePasswordViewController") as! ChangePasswordViewController
        viewController.isModalInPresentation = true
        present(viewController, animated: true)
    }
    
    func showLoginViewController() {
        if let user = currentUser {
            delegate?.setUsername(user.personalInfo.username)
        }
        navigationController?.popToRootViewController(animated: true)
    }
}
