import UIKit
import RxSwift
import RxKeyboard

class ChangePasswordViewController: UIViewController {
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var password1TextField: UITextField!
    @IBOutlet weak var password2TextField: UITextField!
    
    @IBOutlet weak var submitButtonBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var submitButton: UIButton!
    @IBAction func submitButtonAction(_ sender: Any) {
        submitAction()
    }
    
    var disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        scrollView.slideLeftViews(delay: 0.1)
    }
}

//MARK: - Setup Views
private extension ChangePasswordViewController {
    
    func setupViews() {
        setupTextFields()
        submitButton.dropShadowAndCornerRadius(.regular)
    }
    
    func setupTextFields() {
        handleKeyboardVisibility()
        password1TextField.delegate = self
        password2TextField.delegate = self
        password1TextField.addDoneToolbar()
        password2TextField.addDoneToolbar()
        password1TextField.becomeFirstResponder()
    }
}

//MARK: - TextField Functions
extension ChangePasswordViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        switch textField {
        case password1TextField:
            password2TextField.becomeFirstResponder()
        case password2TextField:
            password2TextField.resignFirstResponder()
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
private extension ChangePasswordViewController {
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
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

//MARK: - Action Functions
private extension ChangePasswordViewController {
    
    func submitAction() {
        if password1TextField.text == password2TextField.text && !password1TextField.text!.isEmpty {
            let password = password1TextField.text!
            if ValidationRule.password.isValidPassword(text: password) {
                changePassword(by: password)
                BannerManager.showMessage(messageText: "Success!", messageSubtitle: "Password changed successfully. Login With new password.", style: .success)
                self.view.window!.rootViewController?.dismiss(animated: true)
            }
        } else if password1TextField.text != password2TextField.text {
            BannerManager.showMessage(messageText: "Warning!", messageSubtitle: "Passwords are not the same! Please correct them.", style: .danger)
        } else {
            BannerManager.showMessage(messageText: "Error!", messageSubtitle: "Please fill all fields", style: .danger)
        }
    }
    
    func changePassword(by password: String) {
        currentUser?.personalInfo.password = password
        for i in 0..<allUsers.count {
            if allUsers[i].personalInfo.username.lowercased() == currentUser?.personalInfo.username.lowercased() && allUsers[i].personalInfo.lastName == currentUser?.personalInfo.lastName {
                allUsers[i] = currentUser!
                UserDefaults.standard.saveUsers()
                break
            }
        }
    }
}
