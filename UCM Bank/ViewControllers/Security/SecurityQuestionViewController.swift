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

    var disposeBag = DisposeBag()
    var textFields: [UITextField]!
    var isUserSigningUp: Bool = false
    var username: String = "" // ✅ به صورت مستقیم از ContinueSignupViewController ست می‌شود
    weak var delegate: SecurityQuestionViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        scrollView.slideUpViews(delay: 0.1)
    }

    @IBAction func submitButtonAction(_ sender: Any) {
        submitAction()
    }
}

// MARK: - Setup
private extension SecurityQuestionViewController {
    func setupViews() {
        handleKeyboardVisibility()
        setupTextFields()
        submitButton.dropShadowAndCornerRadius(.regular)
        usernameStackView.isHidden = isUserSigningUp
        if isUserSigningUp {
            usernameTextField.text = username
            usernameTextField.isEnabled = false
        }
    }

    func setupTextFields() {
        textFields = [usernameTextField, question1TextField, question2TextField, question3TextField]
        textFields.forEach {
            $0.delegate = self
            $0.addDoneToolbar()
        }
        usernameTextField.becomeFirstResponder()
    }

    func handleKeyboardVisibility() {
        RxKeyboard.instance.visibleHeight
            .drive(onNext: { [weak self] height in
                guard let self = self else { return }
                self.submitButtonBottomConstraint.constant = height == 0 ? 20 : height
                UIView.animate(withDuration: 0.3) {
                    self.view.layoutIfNeeded()
                } completion: { _ in
                    self.scrollView.scrollToBottom()
                }
            }).disposed(by: disposeBag)
    }

    func submitAction() {
        let enteredUsername = usernameTextField.text?.sanitized ?? ""
        let actualUsername = isUserSigningUp ? username : enteredUsername

        let answer1 = question1TextField.text ?? ""
        let answer2 = question2TextField.text ?? ""
        let answer3 = question3TextField.text ?? ""

        guard !actualUsername.isEmpty, !answer1.isEmpty, !answer2.isEmpty, !answer3.isEmpty else {
            BannerManager.showMessage(messageText: "Error!", messageSubtitle: "Please fill all fields.", style: .danger)
            return
        }

        if isUserSigningUp {
            submitSecurityQuestions(username: actualUsername, answer1: answer1, answer2: answer2, answer3: answer3)
        } else {
            NetworkManager.shared.checkUsernameExists(actualUsername) { [weak self] exists in
                guard let self = self else { return }
                if !exists {
                    BannerManager.showMessage(messageText: "Error", messageSubtitle: "Username does not exist!", style: .danger)
                    return
                }

                NetworkManager.shared.validateSecurityAnswers(username: actualUsername, answer1: answer1, answer2: answer2, answer3: answer3) { result in
                    DispatchQueue.main.async {
                        switch result {
                        case .success(let match):
                            if match {
                                self.showChangePasswordViewController()
                            } else {
                                BannerManager.showMessage(messageText: "Incorrect", messageSubtitle: "Security answers do not match.", style: .danger)
                            }
                        case .failure(let error):
                            BannerManager.showMessage(messageText: "Error", messageSubtitle: error.localizedDescription, style: .danger)
                        }
                    }
                }
            }
        }
    }

    func submitSecurityQuestions(username: String, answer1: String, answer2: String, answer3: String) {
        NetworkManager.shared.setSecurityQuestions(username: username, answer1: answer1, answer2: answer2, answer3: answer3) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let success):
                    if success {
                        BannerManager.showMessage(messageText: "Success", messageSubtitle: "Security questions saved.", style: .success)
                        self.showLoginViewController()
                    } else {
                        BannerManager.showMessage(messageText: "Error", messageSubtitle: "Unexpected failure saving questions.", style: .danger)
                    }
                case .failure(let error):
                    BannerManager.showMessage(messageText: "Error", messageSubtitle: error.localizedDescription, style: .danger)
                }
            }
        }
    }

    func showChangePasswordViewController() {
        guard let vc = storyboard?.instantiateViewController(withIdentifier: "ChangePasswordViewController") as? ChangePasswordViewController else { return }
        vc.isModalInPresentation = true
        vc.username = usernameTextField.text!
        present(vc, animated: true)
    }

    func showLoginViewController() {
        delegate?.setUsername(username)
        navigationController?.popToRootViewController(animated: true)
    }
}

// MARK: - UITextFieldDelegate
extension SecurityQuestionViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case usernameTextField: question1TextField.becomeFirstResponder()
        case question1TextField: question2TextField.becomeFirstResponder()
        case question2TextField: question3TextField.becomeFirstResponder()
        case question3TextField:
            textField.resignFirstResponder()
            submitAction()
        default: break
        }
        return true
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
}
