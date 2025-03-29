import UIKit
import RxSwift
import RxKeyboard
import MarqueeLabel
import NotificationBannerSwift

class LoginViewController: UIViewController {
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var usernameTipLabel: MarqueeLabel!
    @IBOutlet weak var passwordTipLabel: MarqueeLabel!
    @IBOutlet weak var rememberSwitch: UISwitch!
    
    @IBOutlet weak var signInButton: UIButton!
    @IBAction func signInButtonAction(_ sender: Any) {
        signInAction()
    }
    
    @IBOutlet weak var registerStackViewBottomConstraint: NSLayoutConstraint!
    @IBAction func registerButtonAction(_ sender: Any) {
        showRegisterViewController()
    }
    
    @IBOutlet weak var forgetButton: UIButton!
    @IBAction func forgetButtonAction(_ sender: Any) {
        forgotAction()
    }
    
    var numberOfSignInAttempts = 0
    var loginData: [String: String] = [:]
    var disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        getUsers()
        setupViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        scrollView.slideUpViews(delay: 0.1)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        passwordTextField.text = ""
    }
    
    private func getUsers() {
        allUsers = UserDefaults.standard.retrieveUsers()
        setInitialCurrentUser()
    }
    
    private func getCurrentUser() {
        if let user = allUsers.filter({$0.personalInfo.username.lowercased() == usernameTextField.text!.lowercased() && $0.personalInfo.password == passwordTextField.text!}).first {
            currentUser = user
        } else {
            BannerManager.showMessage(messageText: "Failure", messageSubtitle: "The user is not available.", style: .danger)
        }
    }
    
    private func setInitialCurrentUser() {
        if !allUsers.filter({$0.rememberUserLogin == true}).isEmpty {
            currentUser = allUsers.filter({$0.rememberUserLogin == true}).first
        } else {
            currentUser = initialUser()
        }
    }
    
    private func isUsernameAvailableInUserDefaults()-> Bool {
        return !allUsers.filter({$0.personalInfo.username.lowercased() == usernameTextField.text?.lowercased()}).isEmpty
    }
    
    private func isAuthAccepted()-> Bool {
        return !allUsers.filter({$0.personalInfo.username.lowercased() == usernameTextField.text?.lowercased() && $0.personalInfo.password == passwordTextField.text}).isEmpty
    }
}

//MARK: - Setup Functions
private extension LoginViewController {
    
    func setupViews() {
        view.window?.tintColor = .systemPink
        setupNavigationController()
        setupTextFields()
        setupLabels()
        signInButton.dropShadowAndCornerRadius(.regular)
    }
    
    func setupNavigationController() {
        navigationController?.navigationBar.prefersLargeTitles = true
        title = "Login"
        setupNavigationTitleView()
    }
    
    func setupNavigationTitleView() {
        let textLabel = UILabel()
        textLabel.text = "UCM BANK"
        textLabel.font = UIFont.boldSystemFont(ofSize: 20.0)
        textLabel.textAlignment = .center
        let stackView = UIStackView()
        stackView.axis = NSLayoutConstraint.Axis.horizontal
        stackView.distribution = UIStackView.Distribution.equalSpacing
        stackView.alignment = UIStackView.Alignment.center
        stackView.spacing = 4.0
        stackView.addArrangedSubview(textLabel)
        navigationItem.titleView = stackView
    }
    func setupTextFields() {
        handleKeyboardVisibility()
        usernameTextField.delegate = self
        passwordTextField.delegate = self
        usernameTextField.addDoneToolbar()
        passwordTextField.addDoneToolbar()
        hideKeyboardOnTap(#selector(self.dismissKeyboard))
        usernameTextField.text = currentUser?.rememberUserLogin ?? false ? currentUser?.personalInfo.username : ""
    }
    
    func setupLabels() {
        usernameTipLabel.speed = MarqueeLabel.SpeedLimit.duration(20)
        passwordTipLabel.speed = MarqueeLabel.SpeedLimit.duration(20)
        usernameTipLabel.text = "The minimum length is between 8 and 32 characters. It may including underline or dots; but it's not case sensitive."
        passwordTipLabel.text = "The minimum length is between 8 and 32 characters including both special characters and numbers."
    }
}

//MARK: - TextField Functions
extension LoginViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
}

//MARK: - Keyboard Functions
private extension LoginViewController {
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func handleKeyboardVisibility() {
        RxKeyboard.instance.visibleHeight
            .drive(onNext: { [weak self] keyboardVisibleHeight in
                guard let self = self else { return }
                self.registerStackViewBottomConstraint.constant = (keyboardVisibleHeight == 0) ? 20 : keyboardVisibleHeight
                UIView.animate(withDuration: 0.3) {
                    self.view.layoutIfNeeded()
                } completion: { _ in
                    self.scrollView.scrollToBottom()
                }
            }).disposed(by: disposeBag)
    }
}

//MARK: - Action Functions
private extension LoginViewController {
    
    func forgotAction() {
        showResetPasswordViewController(shouldDismiss: true)
    }
    
    func signInAction() {
        
        numberOfSignInAttempts += 1
        let username = usernameTextField.text!
        let password = passwordTextField.text!
        if username.isEmpty && password.isEmpty {
            BannerManager.showMessage(messageText: "Error!", messageSubtitle: "Please fill all fields", style: .danger)
            return
        }
        let isValid = isLoginEntryValid()
        
        if numberOfSignInAttempts > 3 && !isValid {
            numberOfSignInAttempts = 0
            BannerManager.showMessage(messageText: "Forgot password", messageSubtitle: "Please reset your account password.", style: .warning)
            showResetPasswordViewController(shouldDismiss: false)
            return
        }
        currentUser?.personalInfo.username = username
        currentUser?.personalInfo.password = password
        
        if isValid && isUsernameAvailableInUserDefaults() && isAuthAccepted() {
            numberOfSignInAttempts = 0
            getCurrentUser()
            rememberUserLogin()
            showTabbarController()
            BannerManager.showMessage(messageText: "Success", messageSubtitle: "Logging you in...", style: .success)
            
        } else if isValid && !isUsernameAvailableInUserDefaults() {
            BannerManager.showMessage(messageText: "New User?", messageSubtitle: "If you are, please register.", style: .warning)
        } else if isValid && isUsernameAvailableInUserDefaults() && !isAuthAccepted(){
            
            BannerManager.showMessage(messageText: "Failure", messageSubtitle: "Password is wrong.", style: .danger)
            return
        } else if !isValid && !username.isEmpty && !password.isEmpty {
            BannerManager.showMessage(messageText: "Failure", messageSubtitle: "Either Username, Password or both are wrong.", style: .danger)
        } else {
            BannerManager.showMessage(messageText: "New User?", messageSubtitle: "If you are, please register.", style: .warning)
        }
    }
    
    func rememberUserLogin() {
        //        set all rememberUserLogin to false
        for i in 0..<allUsers.count {
            allUsers[i].rememberUserLogin = false
        }
        //        make change and save
        for i in 0..<allUsers.count {
            if allUsers[i].personalInfo.username == currentUser?.personalInfo.username && allUsers[i].personalInfo.password == currentUser?.personalInfo.password {
                allUsers[i].rememberUserLogin = rememberSwitch.isOn
                currentUser = allUsers[i]
                break
            }
        }
        UserDefaults.standard.saveUsers()
    }
    
    private func isLoginEntryValid()-> Bool {
        let username = usernameTextField.text ?? ""
        let password = passwordTextField.text ?? ""
        
        let isValidUsername = ValidationRule.username.isValidUsername(text: username)
        let isValidPassword = ValidationRule.password.isValidPassword(text: password)
        return isValidUsername && isValidPassword ? true : false
    }
}
//MARK: - Navigation Functions
extension LoginViewController: SecurityQuestionViewControllerDelegate {
    
    func setUsername(_ username: String) {
        usernameTextField.text = username
    }
}

//MARK: - Navigation Functions
extension LoginViewController {
    
    func showTabbarController() {
        let vc = storyboard?.instantiateViewController(withIdentifier: "MainTabBarController")
        navigationController?.pushViewController(vc!, animated: true)
    }
    
    func showRegisterViewController() {
        let viewController = storyboard?.instantiateViewController(withIdentifier: "RegisterViewController") as! RegisterViewController
        currentUser = nil
        viewController.securityDelegate = self
        navigationController?.pushViewController(viewController, animated: true)
    }
    
    func showResetPasswordViewController(shouldDismiss: Bool) {
        let viewController = storyboard?.instantiateViewController(withIdentifier: "SecurityQuestionViewController") as! SecurityQuestionViewController
        viewController.isModalInPresentation = !shouldDismiss
        viewController.isUserRegistering = false
        navigationController?.present(viewController, animated: true)
    }
}
