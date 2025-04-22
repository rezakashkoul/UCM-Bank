import UIKit
import RxSwift
import RxKeyboard

class ChangePasswordViewController: UIViewController {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var password1TextField: UITextField!
    @IBOutlet weak var password2TextField: UITextField!
    @IBOutlet weak var submitButtonBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var submitButton: UIButton!

    var disposeBag = DisposeBag()
    var username = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        scrollView.slideLeftViews(delay: 0.1)
    }

    @IBAction func submitButtonAction(_ sender: Any) {
        submitAction()
    }
}

// MARK: - Setup
private extension ChangePasswordViewController {

    func setupViews() {
        handleKeyboardVisibility()
        submitButton.dropShadowAndCornerRadius(.regular)
        [password1TextField, password2TextField].forEach {
            $0?.delegate = self
            $0?.addDoneToolbar()
        }
        password1TextField.becomeFirstResponder()
    }

    func handleKeyboardVisibility() {
        RxKeyboard.instance.visibleHeight
            .drive(onNext: { [weak self] keyboardVisibleHeight in
                guard let self = self else { return }
                self.submitButtonBottomConstraint.constant = keyboardVisibleHeight == 0 ? 20 : keyboardVisibleHeight
                UIView.animate(withDuration: 0.3) {
                    self.view.layoutIfNeeded()
                } completion: { _ in
                    self.scrollView.scrollToBottom()
                }
            }).disposed(by: disposeBag)
    }

    func submitAction() {
        guard let password1 = password1TextField.text,
              let password2 = password2TextField.text,
              !password1.isEmpty, !password2.isEmpty else {
            BannerManager.showMessage(messageText: "Error", messageSubtitle: "Please fill all fields.", style: .danger)
            return
        }

        guard password1 == password2 else {
            BannerManager.showMessage(messageText: "Warning!", messageSubtitle: "Passwords do not match!", style: .danger)
            return
        }

        guard ValidationRule.password.isValidPassword(text: password1) else {
            BannerManager.showMessage(messageText: "Error!", messageSubtitle: "Password is not valid.", style: .danger)
            return
        }

        guard !username.isEmpty else {
            BannerManager.showMessage(messageText: "Error", messageSubtitle: "Username not available. Please restart the flow.", style: .danger)
            goToLoginPage()
            return
        }

        submitButton.isEnabled = false

        NetworkManager.shared.resetCognitoPassword(username: username, newPassword: password1) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.submitButton.isEnabled = true

                switch result {
                case .success(let response):
                    if let message = response["message"] as? String,
                       message.lowercased().contains("password updated successfully") {
                        BannerManager.showMessage(messageText: "Success", messageSubtitle: message, style: .success)
                        self.goToLoginPage()
                    } else {
                        let subtitle = response["message"] as? String ?? "Password update failed."
                        BannerManager.showMessage(messageText: "Error", messageSubtitle: subtitle, style: .danger)
                    }

                case .failure(let error):
                    BannerManager.showMessage(messageText: "Error", messageSubtitle: error.localizedDescription, style: .danger)
                }
            }
        }
    }

    func goToLoginPage() {
        if let window = UIApplication.shared.windows.first {
            window.rootViewController?.dismiss(animated: true)
        }
    }
}

// MARK: - UITextFieldDelegate
extension ChangePasswordViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == password1TextField {
            password2TextField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
            submitAction()
        }
        return true
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
}
