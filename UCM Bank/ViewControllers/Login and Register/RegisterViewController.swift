import UIKit
import RxSwift
import RxKeyboard
import MarqueeLabel

class RegisterViewController: UIViewController {
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var ssnTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var telTextField: UITextField!
    @IBOutlet weak var unitNumberTextField: UITextField!
    @IBOutlet weak var streetNumberTextField: UITextField!
    @IBOutlet weak var streetNameTextField: UITextField!
    @IBOutlet weak var postalCodeTextField: UITextField!
    @IBOutlet weak var provinceTextField: UITextField!
    @IBOutlet weak var usernameTipLabel: MarqueeLabel!
    @IBOutlet weak var passwordTipLabel: MarqueeLabel!
    
    @IBOutlet weak var submitButtonBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var submitButton: UIButton!
    @IBAction func submitButtonAction(_ sender: Any) {
        submitAction()
    }
    
    var disposeBag = DisposeBag()
    var textFields: [UITextField]!
    let pickerView = UIPickerView()
    var securityDelegate: SecurityQuestionViewControllerDelegate!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViews()
        currentUser = initialUser()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        scrollView.slideLeftViews(delay: 0.1)
    }
}

//MARK: - Setup Views
private extension RegisterViewController {
    
    func setupViews() {
        setupNavigationTitle()
        setupTextFields()
        setupPickerView()
        setupLabels()
        submitButton.dropShadowAndCornerRadius(.regular)
    }
    
    func setupNavigationTitle() {
        navigationItem.largeTitleDisplayMode = .always
        navigationItem.title = "Register"
    }
    
    func setupTextFields() {
        handleKeyboardVisibility()
        hideKeyboardOnTap(#selector(self.dismissKeyboard))
        textFields = view.getTextfields(view)
        textFields.forEach({$0.delegate = self})
        textFields.forEach({$0.addDoneToolbar()})
        provinceTextField.inputView = pickerView
        provinceTextField.text = "State"
    }
    
    func setupPickerView() {
        pickerView.delegate = self
        pickerView.dataSource = self
    }
    
    func setupLabels() {
        usernameTipLabel.speed = MarqueeLabel.SpeedLimit.duration(20)
        passwordTipLabel.speed = MarqueeLabel.SpeedLimit.duration(20)
        usernameTipLabel.text = "The minimum length is between 8 and 32 characters. It may including underline or dots; but it's not case sensitive."
        passwordTipLabel.text = "The minimum length is between 8 and 32 characters including both special characters and numbers."
    }
}

//MARK: - TextField Functions
extension RegisterViewController: UITextFieldDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField == provinceTextField && textField.text == "State" {
            textField.text = provinces[0]
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentString: NSString = (textField.text ?? "") as NSString
        let newString: NSString =  currentString.replacingCharacters(in: range, with: string) as NSString
        var maxLength = 10
        
        switch textField {
        case ssnTextField: maxLength = 9
            return newString.length <= maxLength
        case telTextField: maxLength = 10
            return newString.length <= maxLength
        case unitNumberTextField: maxLength = 4
            return newString.length <= maxLength
        case streetNumberTextField, postalCodeTextField: maxLength = 6
            return newString.length <= maxLength
        case provinceTextField: return false
        default: return true
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case usernameTextField: passwordTextField.becomeFirstResponder()
        case passwordTextField: firstNameTextField.becomeFirstResponder()
        case firstNameTextField: lastNameTextField.becomeFirstResponder()
        case lastNameTextField: ssnTextField.becomeFirstResponder()
        case ssnTextField: emailTextField.becomeFirstResponder()
        case emailTextField: telTextField.becomeFirstResponder()
        case telTextField: unitNumberTextField.becomeFirstResponder()
        case unitNumberTextField: streetNumberTextField.becomeFirstResponder()
        case streetNumberTextField: streetNameTextField.becomeFirstResponder()
        case streetNameTextField: provinceTextField.becomeFirstResponder()
        case provinceTextField: postalCodeTextField.becomeFirstResponder()
        case postalCodeTextField: postalCodeTextField.resignFirstResponder()
        default: break
        }
        return true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
}

//MARK: - PickerView Functions
extension RegisterViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return provinces.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return provinces[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        provinceTextField.text = provinces[row]
    }
}

//MARK: - Keyboard Functions
private extension RegisterViewController {
    
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

//MARK: - Actions
private extension RegisterViewController {
    
    private func isRegisterEntriesValid()-> Bool {
        let isValidUsername = ValidationRule.username.isValidUsername(text: usernameTextField.text!)
        let isValidPassword = ValidationRule.password.isValidPassword(text: passwordTextField.text!)
        let isValidFirstName = isValidFirstName()
        let isValidLastName = isValidLastName()
        let isValidStreetName = ValidationRule.none.isValid(text: streetNameTextField.text!)
        let isValidSSN = ValidationRule.ssn.isValidSSN(text: ssnTextField.text!)
        let isValidEmail = ValidationRule.email.isValidEmail(text: emailTextField.text!)
        let isValidTel = ValidationRule.tel.isValidTel(text: telTextField.text!)
        let isValidUnitNumber = ValidationRule.unitNumber.isValidUnitNumber(text: unitNumberTextField.text!)
        let isValidStreetNumber = ValidationRule.streetNumber.isValidStreetNumber(text: streetNumberTextField.text!)
        let isValidPostalCode = ValidationRule.postalCode.isValidPostalCode(text: postalCodeTextField.text!)
        let isValidProvince = ValidationRule.province.isValidProvince(text: provinceTextField.text!)
        
        if isValidUsername && isValidPassword && isValidFirstName && isValidLastName && isValidStreetName && isValidSSN && isValidEmail && isValidTel && isValidUnitNumber && isValidStreetNumber && isValidPostalCode && isValidProvince {
            return true
        } else {
            return false
        }
    }
    
    private func isValidFirstName()-> Bool {
        let title = firstNameTextField.text ?? ""
        let isValidTitle = ValidationRule.textName.isValidTextName(text: title, shouldShowError: false)
        if !isValidTitle {
            BannerManager.showMessage(messageText: "Error", messageSubtitle: "Please check first name!", style: .danger)
            return false
        } else {
            return true
        }
    }
    
    private func isValidLastName()-> Bool {
        let title = lastNameTextField.text ?? ""
        let isValidTitle = ValidationRule.textName.isValidTextName(text: title, shouldShowError: false)
        if !isValidTitle {
            BannerManager.showMessage(messageText: "Error", messageSubtitle: "Please check last name!", style: .danger)
            return false
        } else {
            return true
        }
    }
    
    private func setUser() {
        
        currentUser?.personalInfo.username = usernameTextField.text!.lowercased()
        currentUser?.personalInfo.password = passwordTextField.text!
        currentUser?.personalInfo.firstName = firstNameTextField.text!
        currentUser?.personalInfo.lastName = lastNameTextField.text!
        currentUser?.personalInfo.ssn = ssnTextField.text!
        currentUser?.personalInfo.email = emailTextField.text!
        currentUser?.personalInfo.tel = telTextField.text!
        currentUser?.personalInfo.address.unitNumber = unitNumberTextField.text!
        currentUser?.personalInfo.address.streetNumber = streetNumberTextField.text!
        currentUser?.personalInfo.address.streetName = streetNameTextField.text!
        currentUser?.personalInfo.address.province = provinceTextField.text!
        currentUser?.personalInfo.address.postalCode = postalCodeTextField.text!
    }
    
    func isUserAvailable()-> Bool {
        return !allUsers.filter({$0.personalInfo.username.lowercased() == currentUser?.personalInfo.username.lowercased()}).isEmpty
    }
    
    func submitAction() {
        
        if textFields?.filter({$0 != provinceTextField}).filter({$0.text!.isEmpty}).count != 0 {
            BannerManager.showMessage(messageText: "Error!", messageSubtitle: "Please fill all fields", style: .danger)
            return
        }
        if isRegisterEntriesValid() {
            setUser()
            if !isUserAvailable() {
                BannerManager.showMessage(messageText: "Success!", messageSubtitle: "Please choose the security questions to recover your account in case of forgetting login info.", style: .success)
                showSecurityQuestion()
            } else {
                BannerManager.showMessage(messageText: "User exist already", messageSubtitle: "Please user forget button to recover user!", style: .warning)
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.showResetPasswordViewController(shouldDismiss: true)
                }
            }
        }
    }
}

//MARK: - Navigation Functions
extension RegisterViewController {
    
    func showSecurityQuestion() {
        let viewController = storyboard?.instantiateViewController(withIdentifier: "SecurityQuestionViewController") as! SecurityQuestionViewController
        viewController.isUserRegistering = true
        viewController.delegate = securityDelegate
        navigationController?.pushViewController(viewController, animated: true)
    }
    
    func showResetPasswordViewController(shouldDismiss: Bool) {
        let viewController = storyboard?.instantiateViewController(withIdentifier: "SecurityQuestionViewController") as! SecurityQuestionViewController
        viewController.isModalInPresentation = !shouldDismiss
        viewController.isUserRegistering = false
        navigationController?.present(viewController, animated: true)
    }
}
