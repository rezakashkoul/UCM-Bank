import UIKit
import RxSwift
import RxKeyboard
import MarqueeLabel
import Amplify
import NotificationBannerSwift

class SignupViewController: UIViewController {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var usernameTipLabel: MarqueeLabel!
    @IBOutlet weak var passwordTipLabel: MarqueeLabel!
    @IBOutlet weak var submitButtonBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var submitButton: UIButton!

    var disposeBag = DisposeBag()
    var textFields: [UITextField]!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        scrollView.slideLeftViews(delay: 0.1)
    }

    @IBAction func submitButtonAction(_ sender: Any) {
        Task { @MainActor in
            await submitAction()
        }
    }
}

// MARK: - Setup
private extension SignupViewController {
    func setupViews() {
        setupNavigation()
        setupTextFields()
        setupTips()
        setupSubmitButton()
    }

    func setupNavigation() {
        navigationItem.largeTitleDisplayMode = .always
        navigationItem.title = "Sign Up"
    }

    func setupTextFields() {
        handleKeyboardVisibility()
        hideKeyboardOnTap(#selector(dismissKeyboard))
        textFields = [usernameTextField, passwordTextField, emailTextField]
        textFields.forEach { field in
            field.delegate = self
            field.addDoneToolbar()
            field.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        }
    }

    func setupTips() {
        usernameTipLabel.speed = .duration(20)
        passwordTipLabel.speed = .duration(20)
        usernameTipLabel.text = "Username must be 8–32 characters, can include _ or ."
        passwordTipLabel.text = "Password must include letters, numbers, and special characters."
    }

    func setupSubmitButton() {
        submitButton.dropShadowAndCornerRadius(.regular)
        updateSubmitButtonState()
    }

    func updateSubmitButtonState() {
        let enabled = isSignupValid()
        submitButton.isEnabled = enabled
        submitButton.backgroundColor = enabled ? .systemPink : .systemGray
    }
}

// MARK: - Text Field
extension SignupViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case usernameTextField: passwordTextField.becomeFirstResponder()
        case passwordTextField: emailTextField.becomeFirstResponder()
        default: textField.resignFirstResponder()
        }
        return true
    }

    @objc func textFieldDidChange() {
        updateSubmitButtonState()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
}

// MARK: - Keyboard
private extension SignupViewController {
    @objc func dismissKeyboard() {
        view.endEditing(true)
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
}

// MARK: - Actions
private extension SignupViewController {
    func isSignupValid() -> Bool {
        ValidationRule.username.isValidUsername(text: usernameTextField.text!, shouldShowError: false) &&
        ValidationRule.password.isValidPassword(text: passwordTextField.text!, shouldShowError: false) &&
        ValidationRule.email.isValidEmail(text: emailTextField.text!, shouldShowError: false)
    }

    func submitAction() async {
        guard textFields.allSatisfy({ !($0.text ?? "").isEmpty }) else {
            BannerManager.showMessage(messageText: "Error", messageSubtitle: "Please fill all fields", style: .danger)
            return
        }

        guard isSignupValid() else {
            BannerManager.showMessage(messageText: "Error", messageSubtitle: "Invalid inputs", style: .danger)
            return
        }

        let username = usernameTextField.text!
        let password = passwordTextField.text!
        let email = emailTextField.text!

        let exists = await NetworkManager.shared.checkUsernameExists(username: username)

        if exists {
            BannerManager.showMessage(messageText: "User Exists", messageSubtitle: "Try signing in or reset.", style: .warning)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self.showResetPasswordViewController(shouldDismiss: true)
            }
        } else {
            await signupUser(username: username, password: password, email: email)
        }
    }

    func signupUser(username: String, password: String, email: String) async {
        let attributes = [AuthUserAttribute(.email, value: email)]
        let options = AuthSignUpRequest.Options(userAttributes: attributes)

        do {
            let result = try await Amplify.Auth.signUp(username: username, password: password, options: options)
            switch result.nextStep {
            case .done:
                BannerManager.showMessage(messageText: "Signed Up", messageSubtitle: "No confirmation needed.", style: .success)
            case .confirmUser:
                BannerManager.showMessage(messageText: "Verify Email", messageSubtitle: "Check your inbox.", style: .info)
                showSignupEmailConfirmationViewController(username: username)
            @unknown default:
                BannerManager.showMessage(messageText: "Error", messageSubtitle: "Unknown sign-up step", style: .danger)
            }
        } catch let error as AuthError {
            switch error {
            case .service(_, let message, _):
                if message.contains("UsernameExistsException") {
                    BannerManager.showMessage(messageText: "User Exists", messageSubtitle: "Try signing in or reset.", style: .warning)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        self.showResetPasswordViewController(shouldDismiss: true)
                    }
                } else {
                    BannerManager.showMessage(messageText: "Error", messageSubtitle: message, style: .danger)
                }
            default:
                BannerManager.showMessage(messageText: "Error", messageSubtitle: error.localizedDescription, style: .danger)
            }
        } catch {
            BannerManager.showMessage(messageText: "Error", messageSubtitle: error.localizedDescription, style: .danger)
        }
    }
}

// MARK: - Navigation
extension SignupViewController {
    func showSignupEmailConfirmationViewController(username: String) {
        let vc = storyboard?.instantiateViewController(withIdentifier: "SignupEmailConfirmationViewController") as! SignupEmailConfirmationViewController
        vc.username = username
        navigationController?.pushViewController(vc, animated: true)
    }

    func showResetPasswordViewController(shouldDismiss: Bool) {
        let vc = storyboard?.instantiateViewController(withIdentifier: "SecurityQuestionViewController") as! SecurityQuestionViewController
        vc.isModalInPresentation = !shouldDismiss
        vc.isUserSigningUp = false
        navigationController?.present(vc, animated: true)
    }
}
