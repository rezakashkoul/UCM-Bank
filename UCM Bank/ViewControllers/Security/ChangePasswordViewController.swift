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
        password1TextField.delegate = self
        password2TextField.delegate = self
        password1TextField.addDoneToolbar()
        password2TextField.addDoneToolbar()
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

        // ✅ Use rememberedUsername from UserDefaults (if available)
        let username = UserDefaults.standard.string(forKey: "rememberedUsername")?.lowercased()

        guard let safeUsername = username, !safeUsername.isEmpty else {
            BannerManager.showMessage(messageText: "Error", messageSubtitle: "Username not found. Please login again.", style: .danger)
            goToLoginPage()
            return
        }

        submitButton.isEnabled = false

        NetworkManager.shared.changePassword(username: safeUsername, newPassword: password1) { [weak self] result in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.submitButton.isEnabled = true

                switch result {
                case .success(let success):
                    if success {
                        BannerManager.showMessage(messageText: "Success", messageSubtitle: "Password changed. Please login again.", style: .success)
                        self.goToLoginPage()
                    } else {
                        BannerManager.showMessage(messageText: "Error", messageSubtitle: "Password change unsuccessful.", style: .danger)
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
        switch textField {
        case password1TextField:
            password2TextField.becomeFirstResponder()
        case password2TextField:
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
