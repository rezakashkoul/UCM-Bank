import Amplify
import UIKit
import RxSwift
import RxKeyboard
import MarqueeLabel
import NotificationBannerSwift

class LoginViewController: UIViewController {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var signInStackViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var usernameTipLabel: MarqueeLabel!
    @IBOutlet weak var passwordTipLabel: MarqueeLabel!
    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var forgetButton: UIButton!
    @IBOutlet weak var signupButton: UIButton!

    var disposeBag = DisposeBag()
    var numberOfSignInAttempts = 0

    @IBAction func signupButtonAction(_ sender: Any) {
        showSignupViewController()
    }

    @IBAction func signInButtonAction(_ sender: Any) {
        signInAction()
    }

    @IBAction func forgetButtonAction(_ sender: Any) {
        showResetPasswordViewController(shouldDismiss: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        scrollView.slideUpViews(delay: 0.1)
        Task {
            await NetworkManager.shared.signOutIfNeeded()
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        passwordTextField.text = ""
    }
}

// MARK: - Setup
private extension LoginViewController {
    func setupViews() {
        setupNavigation()
        setupTextFields()
        setupLabels()
        signInButton.dropShadowAndCornerRadius(.regular)
    }

    func setupNavigation() {
        navigationController?.navigationBar.prefersLargeTitles = true
        title = "Login"
        let label = UILabel()
        label.text = "UCM BANK"
        label.font = .boldSystemFont(ofSize: 20)
        label.textAlignment = .center
        let stack = UIStackView(arrangedSubviews: [label])
        stack.axis = .horizontal
        stack.alignment = .center
        navigationItem.titleView = stack
    }

    func setupTextFields() {
        handleKeyboardVisibility()
        [usernameTextField, passwordTextField].forEach {
            $0?.delegate = self
            $0?.addDoneToolbar()
        }
        hideKeyboardOnTap(#selector(dismissKeyboard))
    }

    func setupLabels() {
        usernameTipLabel.speed = .duration(20)
        passwordTipLabel.speed = .duration(20)
        usernameTipLabel.text = "Username must be 8–32 chars, case-insensitive, with _ or . allowed."
        passwordTipLabel.text = "Password must include symbols and numbers."
    }

    func signInAction() {
        numberOfSignInAttempts += 1

        guard let username = usernameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
              let password = passwordTextField.text, !username.isEmpty, !password.isEmpty else {
            BannerManager.showMessage(messageText: "Error!", messageSubtitle: "Please fill all fields", style: .danger)
            return
        }

        guard isLoginEntryValid(username: username, password: password) else {
            if numberOfSignInAttempts > 3 {
                numberOfSignInAttempts = 0
                BannerManager.showMessage(messageText: "Too many attempts", messageSubtitle: "Reset your password.", style: .warning)
                showResetPasswordViewController(shouldDismiss: false)
            } else {
                BannerManager.showMessage(messageText: "Invalid Entry", messageSubtitle: "Check username and password.", style: .danger)
            }
            return
        }

        signIn(username: username, password: password)
    }

    func signIn(username: String, password: String) {
        NetworkManager.shared.checkUsernameExists(username.lowercased()) { [weak self] exists in
            guard let self = self else { return }

            if !exists {
                BannerManager.showMessage(messageText: "User Not Found", messageSubtitle: "Please register first.", style: .warning)
                self.showSignupViewController()
                return
            }

            Task {
                do {
                    let result = try await Amplify.Auth.signIn(username: username, password: password)
                    if result.isSignedIn {
                        BannerManager.showMessage(messageText: "Success", messageSubtitle: "Logged in successfully", style: .success)
                        self.showTabbarController()
                    } else {
                        BannerManager.showMessage(messageText: "Next Step", messageSubtitle: "Additional auth needed.", style: .warning)
                    }
                } catch {
                    BannerManager.showMessage(messageText: "Login Failed", messageSubtitle: error.localizedDescription, style: .danger)
                }
            }
        }
    }

    func isLoginEntryValid(username: String, password: String) -> Bool {
        ValidationRule.username.isValidUsername(text: username) &&
        ValidationRule.password.isValidPassword(text: password)
    }

    @objc func dismissKeyboard() {
        view.endEditing(true)
    }

    func handleKeyboardVisibility() {
        RxKeyboard.instance.visibleHeight
            .drive(onNext: { [weak self] height in
                guard let self = self else { return }
                self.signInStackViewBottomConstraint.constant = height == 0 ? 20 : height
                UIView.animate(withDuration: 0.3) { self.view.layoutIfNeeded() }
            }).disposed(by: disposeBag)
    }
}

// MARK: - Delegate & Navigation
extension LoginViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
}

extension LoginViewController: SecurityQuestionViewControllerDelegate {
    
    func setUsername(_ username: String) {
        usernameTextField.text = username.lowercased()
    }
}

extension LoginViewController {
    
    func showTabbarController() {
        DispatchQueue.main.async {
            guard let vc = self.storyboard?.instantiateViewController(withIdentifier: "MainTabBarController") else { return }
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }

    func showSignupViewController() {
        DispatchQueue.main.async {
            guard let vc = self.storyboard?.instantiateViewController(withIdentifier: "SignupViewController") as? SignupViewController else { return }
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }

    func showResetPasswordViewController(shouldDismiss: Bool) {
        DispatchQueue.main.async {
            guard let vc = self.storyboard?.instantiateViewController(withIdentifier: "SecurityQuestionViewController") as? SecurityQuestionViewController else { return }
            vc.isModalInPresentation = !shouldDismiss
            vc.isUserSigningUp = false
            self.navigationController?.present(vc, animated: true)
        }
    }
}
