import UIKit
import RxSwift
import RxKeyboard
import Amplify
import MarqueeLabel

class SignupEmailConfirmationViewController: UIViewController {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var buttonsStackBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var emailTipLabel: MarqueeLabel!
    @IBOutlet weak var timerLabel: UILabel!

    @IBOutlet weak var submitButton: UIButton!
    @IBAction func submitButtonAction(_ sender: Any) {
        submitEmail()
    }

    @IBOutlet weak var resendButton: UIButton!
    @IBAction func resendButtonAction(_ sender: Any) {
        resendEmail()
    }

    var disposeBag = DisposeBag()
    var timer: Timer?
    var secondsRemaining = 300
    var username: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        startTimerCountdown()
    }
}

// MARK: - Setup Views
private extension SignupEmailConfirmationViewController {

    func setupViews() {
        setupNavigationTitle()
        setupTextField()
        setupLabels()
        setupButtons()
    }

    func setupNavigationTitle() {
        navigationItem.largeTitleDisplayMode = .always
        navigationItem.title = "Email Verification"
    }

    func setupTextField() {
        handleKeyboardVisibility()
        hideKeyboardOnTap(#selector(self.dismissKeyboard))
        emailTextField.delegate = self
        emailTextField.addDoneToolbar()
        emailTextField.keyboardType = .numberPad
    }

    func setupLabels() {
        emailTipLabel.speed = MarqueeLabel.SpeedLimit.duration(20)
        emailTipLabel.text = "An email has been sent to your email address. Please check your inbox and enter the code."
    }

    func setupButtons() {
        submitButton.dropShadowAndCornerRadius(.regular)
        resendButton.dropShadowAndCornerRadius(.regular)
        updateButtonStates()
    }

    func updateButtonStates() {
        submitButton.isHidden = secondsRemaining <= 0
        resendButton.isHidden = secondsRemaining > 0

        let activeColor = UIColor.systemPink
        let inactiveColor = UIColor.systemGray

        submitButton.isEnabled = secondsRemaining > 0
        resendButton.isEnabled = secondsRemaining <= 0

        submitButton.backgroundColor = submitButton.isEnabled ? activeColor : inactiveColor
        resendButton.backgroundColor = resendButton.isEnabled ? activeColor : inactiveColor
    }

    func formatTime(seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", minutes, secs)
    }

    func animateShake(_ view: UIView) {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        animation.duration = 0.4
        animation.values = [-10, 10, -8, 8, -5, 5, 0]
        view.layer.add(animation, forKey: "shake")
    }
}

// MARK: - TextField Functions
extension SignupEmailConfirmationViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        emailTextField.resignFirstResponder()
        return true
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
}

// MARK: - Keyboard Functions
private extension SignupEmailConfirmationViewController {
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }

    func handleKeyboardVisibility() {
        RxKeyboard.instance.visibleHeight
            .drive(onNext: { [weak self] keyboardVisibleHeight in
                guard let self = self else { return }
                self.buttonsStackBottomConstraint.constant = (keyboardVisibleHeight == 0) ? 20 : keyboardVisibleHeight
                UIView.animate(withDuration: 0.3) {
                    self.view.layoutIfNeeded()
                } completion: { _ in
                    self.scrollView.scrollToBottom()
                }
            }).disposed(by: disposeBag)
    }
}

// MARK: - Actions
private extension SignupEmailConfirmationViewController {

    func startTimerCountdown() {
        updateButtonStates()
        timerLabel.text = formatTime(seconds: secondsRemaining)

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.secondsRemaining -= 1
            self.timerLabel.text = self.formatTime(seconds: self.secondsRemaining)

            if self.secondsRemaining <= 0 {
                self.timer?.invalidate()
                self.timerLabel.text = "Code expired. Press Resend!"
            }
            self.updateButtonStates()
        }
    }

    func submitEmail() {
        guard let code = emailTextField.text, !code.isEmpty else {
            BannerManager.showMessage(messageText: "Missing Code", messageSubtitle: "Please enter the verification code.", style: .warning)
            animateShake(emailTextField)
            return
        }

        Task {
            do {
                let result = try await Amplify.Auth.confirmSignUp(for: username, confirmationCode: code)
                DispatchQueue.main.async {
                    if result.isSignUpComplete {
                        BannerManager.showMessage(messageText: "Success", messageSubtitle: "Your account has been verified.", style: .success)
                        self.showContinueSignupViewController()
                    } else {
                        BannerManager.showMessage(messageText: "Pending", messageSubtitle: "Verification not complete.", style: .warning)
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    BannerManager.showMessage(messageText: "Error", messageSubtitle: error.localizedDescription, style: .danger)
                    self.animateShake(self.emailTextField)
                }
            }
        }
    }

    func resendEmail() {
        resendButton.isEnabled = false

        Task {
            do {
                let result = try await Amplify.Auth.resendSignUpCode(for: username)
                DispatchQueue.main.async {
                    print("📨 Code resent to: \(result.destination)")
                    BannerManager.showMessage(
                        messageText: "Code Resent",
                        messageSubtitle: "A new code was sent to your email.",
                        style: .info
                    )
                    self.secondsRemaining = 300
                    self.startTimerCountdown()
                }
            } catch {
                DispatchQueue.main.async {
                    BannerManager.showMessage(
                        messageText: "Error",
                        messageSubtitle: error.localizedDescription,
                        style: .danger
                    )
                    self.updateButtonStates()
                }
            }
        }
    }

    func showContinueSignupViewController() {
        let viewController = storyboard?.instantiateViewController(withIdentifier: "ContinueSignupViewController") as! ContinueSignupViewController
        viewController.username = username
        navigationController?.pushViewController(viewController, animated: true)
    }
}
